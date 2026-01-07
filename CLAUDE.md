This is a repository containing Ansible code for configuring a home network. Currently two systems are managed: gateway and server. Gateway is the local Internet router. Server runs typical local services.

For each system, there are two playbooks: init and main. init performs minimal initial configuration. main is the main playbook. There is a common inventory file which is meant to be used when ansible is running locally on the host being configured, but this should only happen once, when the hosts are newly configured, which is not the case anymore; current runs are all remote. There are also dedicated inventory files, meant for remote operation.

Playbooks and inventory for gateway:

- init-gateway.yml
- main-gateway.yml
- inventory-gateway

Playbooks and inventory for server:

- init-server.yml
- main-server.yml
- inventory-server

Secrets are kept in extra-vars.yml which is ignored by git.

If tests need to be performed for the code written here, then they must run with the `--check --diff` options. The `--tags` option may, in some cases, be used to focus the test on parts of the code. If normal test runs do not provide enough information, Ansible has the `-v` option for increased verbosity; using this option repeatedly increases the verbosity level; a reasonable level to start is `-vvv`.

Running an Ansible test for the gateway with the main playbook:

```
ansible-playbook -i inventory-gateway --extra-vars "@extra-vars.yml" main-gateway.yml --check --diff
```

Running an Ansible test for the server with the main playbook:

```
ansible-playbook -i inventory-server --extra-vars "@extra-vars.yml" main-server.yml --check --diff
```

The init playbooks would run in similar ways.
