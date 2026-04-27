# Ansible Home Network Configuration

This repository contains Ansible code for configuring a home network. Systems currently managed:

- **gateway**: Local Internet router, DNS server, DHCP server, NTP server, VPN endpoint
- **server**: Runs local services (mail, file sharing, web servers, Docker containers)
- **claw**: Runs containers (Docker) with NTP client

## Repository Structure

### Playbooks

Each system has two playbooks:

| System  | Init Playbook       | Main Playbook       |
|---------|---------------------|---------------------|
| gateway | `init-gateway.yml`  | `main-gateway.yml`  |
| server  | `init-server.yml`   | `main-server.yml`   |
| claw    | `init-claw.yml`     | `main-claw.yml`     |

- **init playbooks**: Minimal initial configuration (networking, hostname, kernel modules, sudo). Run once on fresh systems locally, using `inventory-localhost`.
- **main playbooks**: Full configuration with all services and roles. Used for ongoing management remotely, using `inventory.yml`.

### Inventory Files

- **`inventory-localhost`**: Used by init playbooks. Targets `127.0.0.1` with a local connection, for bootstrapping before DNS is available.
- **`inventory.yml`**: Used by main playbooks. Contains `gateway`, `server`, and `claw` hosts with short hostnames resolved via DNS.

### Roles

Roles are in the `roles/` directory. Many roles support a mode variable to handle different configurations for gateway vs server:

| Role      | Used By         | Mode Variable    | Modes                           | Description                           |
|-----------|-----------------|------------------|---------------------------------|---------------------------------------|
| chrony    | gateway, server, claw | `chrony_mode`    | `ntp_server`, `ntp_client`      | NTP time synchronization              |
| dhcp      | gateway         | -                | -                               | DHCP server (isc-dhcp-server)         |
| unbound   | gateway         | -                | -                               | DNS resolver + disables resolved listener |
| wireguard | gateway         | -                | -                               | WireGuard VPN endpoint + client configs |
| samba     | gateway, server | `samba_mode`     | `gateway`, `server`             | File sharing (WINS, SMB)              |
| dovecot   | server          | -                | -                               | IMAP mail server                      |
| postfix   | server          | -                | -                               | SMTP mail server                      |
| docker    | server, claw    | -                | -                               | Docker container runtime              |

### Templates

Configuration file templates are in `templates/` (for playbook tasks) and `roles/*/templates/` (for role tasks).

- Text configuration files use the `template` module and may have `.j2` extension
- Binary files (e.g., favicon.ico) must use the `copy` module, not `template`
- In templates, reference facts as `ansible_facts['fact_name']` (e.g. `ansible_facts['default_ipv4']['address']`), not the deprecated top-level `ansible_*` variables

## Secrets and Site-Specific Configuration

Sensitive and site-specific data is stored in `extra-vars.yml`, which is git-ignored. This file contains:

- **Network configuration**: `local_net_prefix`, `local_net_prefix_reverse`, `local_domain`
- **User configuration**: `main_user`
- **Port forwarding rules**: `server_ports_forwarded_tcp`, `sshd_port_extra`
- **WireGuard VPN**: Server keys, client configurations (names, keys, allowed IPs)

All playbook runs require passing the extra-vars file:
```bash
--extra-vars "@extra-vars.yml"
```

## Gateway Services

The gateway (`main-gateway.yml`) provides:

- **Firewall**: nftables
- **DNS**: Unbound (resolver and local authoritative server)
- **DHCP**: isc-dhcp-server
- **NTP**: Chrony (server mode)
- **VPN**: WireGuard
- **File sharing**: Samba (WINS server, domain master)
- **Startup scripts**: rc.local

## Server Services

The server (`main-server.yml`) provides:

- **NTP**: Chrony (client mode, syncs from gateway)
- **Mail**: Dovecot (IMAP) + Postfix (SMTP)
- **Containers**: Docker
- **File sharing**: Samba (WINS client, media shares)
- **Web**: Apache + Nginx

## Claw Services

The claw host (`main-claw.yml`) provides:

- **NTP**: Chrony (client mode, syncs from gateway)
- **Containers**: Docker

## Testing

Always test changes with `--check --diff` before applying:

```bash
# Test gateway
ansible-playbook -i inventory.yml --extra-vars "@extra-vars.yml" main-gateway.yml --check --diff

# Test server
ansible-playbook -i inventory.yml --extra-vars "@extra-vars.yml" main-server.yml --check --diff

# Test claw
ansible-playbook -i inventory.yml --extra-vars "@extra-vars.yml" main-claw.yml --check --diff
```

### Focused Testing with Tags

Use `--tags` to test specific parts of the configuration:

```bash
# Test only the samba role on gateway
ansible-playbook -i inventory.yml --extra-vars "@extra-vars.yml" main-gateway.yml --check --diff --tags samba

# Test only chrony on server
ansible-playbook -i inventory.yml --extra-vars "@extra-vars.yml" main-server.yml --check --diff --tags chrony
```

Available tags vary by playbook. Common tags include:
- `chrony`, `dhcp`, `samba`, `rc.local`, `unbound`, `ip_forwarding` (gateway)
- `chrony`, `dovecot`, `postfix`, `docker`, `samba`, `apache`, `nginx` (server)
- `chrony`, `docker` (claw)

### Verbose Output

For debugging, use `-v`, `-vv`, or `-vvv` for increasing verbosity:

```bash
ansible-playbook -i inventory.yml --extra-vars "@extra-vars.yml" main-gateway.yml --check --diff --tags samba -vvv
```

## Role Development Guidelines

When creating new roles, follow the existing pattern:

1. Create standard directory structure: `defaults/`, `handlers/`, `tasks/`, `templates/`
2. Use a mode variable in `defaults/main.yml` if the role will be used differently on gateway vs server
3. Use conditional `when:` clauses in tasks to apply mode-specific configuration
4. Place templates in `templates/` with `.j2` extension
5. Define handlers in `handlers/main.yml` for service restarts

### Handling `--check` mode on fresh systems

When a role installs a package and then uses it (service tasks, file operations that require files created by earlier tasks), `--check` mode on a fresh system will fail because earlier tasks simulate changes without actually applying them.

The pattern to handle this:

- Register the task whose output a later task depends on
- Guard the dependent task with `when: not (ansible_check_mode and <registered_var> is changed)`

This applies to **tasks and handlers alike**. Examples:

```yaml
# tasks/main.yml
- name: install Foo
  apt:
    name: foo
    state: present
  register: foo_install

- name: deploy Foo config
  template:
    src: foo.conf.j2
    dest: /etc/foo/foo.conf
  register: foo_conf
  notify: reload foo

# Skip if check mode and foo isn't installed yet (file won't exist on disk)
- name: enable Foo site
  file:
    src: /etc/foo/sites-available/foo.conf
    dest: /etc/foo/sites-enabled/foo.conf
    state: link
  when: not (ansible_check_mode and foo_conf is changed)

# Skip if check mode and foo isn't installed yet (service won't exist)
- name: make sure Foo is enabled and running
  service:
    name: foo
    enabled: yes
    state: started
  when: not (ansible_check_mode and foo_install is changed)
```

```yaml
# handlers/main.yml
- name: reload foo
  service:
    name: foo
    state: reloaded
  when: not (ansible_check_mode and foo_install is changed)
```
