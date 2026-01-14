# Ansible Home Network Configuration

This repository contains Ansible code for configuring a home network. Two systems are managed:

- **gateway**: Local Internet router, DNS server, DHCP server, NTP server, VPN endpoint
- **server**: Runs local services (mail, file sharing, web servers, Docker containers)

## Repository Structure

### Playbooks

Each system has two playbooks:

| System  | Init Playbook       | Main Playbook       | Inventory           |
|---------|---------------------|---------------------|---------------------|
| gateway | `init-gateway.yml`  | `main-gateway.yml`  | `inventory-gateway` |
| server  | `init-server.yml`   | `main-server.yml`   | `inventory-server`  |

- **init playbooks**: Minimal initial configuration (networking, hostname, kernel modules, sudo). Run once on fresh systems.
- **main playbooks**: Full configuration with all services and roles. Used for ongoing management.

### Roles

Roles are in the `roles/` directory. Many roles support a mode variable to handle different configurations for gateway vs server:

| Role      | Used By         | Mode Variable    | Modes                           | Description                           |
|-----------|-----------------|------------------|---------------------------------|---------------------------------------|
| chrony    | gateway, server | `chrony_mode`    | `ntp_server`, `ntp_client`      | NTP time synchronization              |
| dhcp      | gateway         | -                | -                               | DHCP server (isc-dhcp-server)         |
| samba     | gateway, server | `samba_mode`     | `gateway`, `server`             | File sharing (WINS, SMB)              |
| rc_local  | gateway         | `rc_local_mode`  | `gateway` (server planned)      | Startup scripts via /etc/rc.local     |
| dovecot   | server          | -                | -                               | IMAP mail server                      |
| postfix   | server          | -                | -                               | SMTP mail server                      |
| docker    | server          | -                | -                               | Docker container runtime              |

### Templates

Configuration file templates are in `templates/` (for playbook tasks) and `roles/*/templates/` (for role tasks).

- Text configuration files use the `template` module and may have `.j2` extension
- Binary files (e.g., favicon.ico) must use the `copy` module, not `template`

## Secrets and Site-Specific Configuration

Sensitive and site-specific data is stored in `extra-vars.yml`, which is git-ignored. This file contains:

- **Network configuration**: `local_net_prefix`, `local_net_prefix_reverse`, `local_domain`
- **User configuration**: `main_user`
- **Port forwarding rules**: `server_ports_forwarded_tcp`, `sshd_port_extra`
- **WireGuard VPN**: Server keys, client configurations (names, keys, allowed IPs)

The inventory files (`inventory-gateway`, `inventory-server`) contain host IP addresses and are also git-ignored.

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

## Testing

Always test changes with `--check --diff` before applying:

```bash
# Test gateway
ansible-playbook -i inventory-gateway --extra-vars "@extra-vars.yml" main-gateway.yml --check --diff

# Test server
ansible-playbook -i inventory-server --extra-vars "@extra-vars.yml" main-server.yml --check --diff
```

### Focused Testing with Tags

Use `--tags` to test specific parts of the configuration:

```bash
# Test only the samba role on gateway
ansible-playbook -i inventory-gateway --extra-vars "@extra-vars.yml" main-gateway.yml --check --diff --tags samba

# Test only chrony on server
ansible-playbook -i inventory-server --extra-vars "@extra-vars.yml" main-server.yml --check --diff --tags chrony
```

Available tags vary by playbook. Common tags include:
- `chrony`, `dhcp`, `samba`, `rc.local`, `unbound`, `ip_forwarding` (gateway)
- `chrony`, `dovecot`, `postfix`, `docker`, `samba`, `apache`, `nginx` (server)

### Verbose Output

For debugging, use `-v`, `-vv`, or `-vvv` for increasing verbosity:

```bash
ansible-playbook -i inventory-gateway --extra-vars "@extra-vars.yml" main-gateway.yml --check --diff --tags samba -vvv
```

## Role Development Guidelines

When creating new roles, follow the existing pattern:

1. Create standard directory structure: `defaults/`, `handlers/`, `tasks/`, `templates/`
2. Use a mode variable in `defaults/main.yml` if the role will be used differently on gateway vs server
3. Use conditional `when:` clauses in tasks to apply mode-specific configuration
4. Place templates in `templates/` with `.j2` extension
5. Define handlers in `handlers/main.yml` for service restarts
