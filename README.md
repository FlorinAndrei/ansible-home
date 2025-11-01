```
sudo apt-get update
sudo apt-get full-upgrade
sudo apt-get install python3-pip python3-venv git
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade -r requirements.txt
sudo reboot
```

On the server, check `README-server.md`.

The remaining Ansible invocations assume Ansible is running locally.

Server:

```
ansible-playbook -i inventory -K --extra-vars "@extra-vars.yml" init-server.yml --check --diff
ansible-playbook -i inventory -K --extra-vars "@extra-vars.yml" init-server.yml
```

Gateway:

```
ansible-playbook -i inventory -K --extra-vars "@extra-vars.yml" init-gateway.yml --check --diff
ansible-playbook -i inventory -K --extra-vars "@extra-vars.yml" init-gateway.yml
```

Server and gateway:

```
reboot
```

Server:

```
ansible-playbook -i inventory --extra-vars "@extra-vars.yml" main-server.yml --check --diff
ansible-playbook -i inventory --extra-vars "@extra-vars.yml" main-server.yml
```

Gateway:

```
ansible-playbook -i inventory --extra-vars "@extra-vars.yml" main-gateway.yml --check --diff
ansible-playbook -i inventory --extra-vars "@extra-vars.yml" main-gateway.yml
```

Gateway:

Check battery:

```
cat /sys/devices/platform/soc/soc\:rpi_rtc/rtc/rtc0/*_voltage*
```

Check CPU fan:

```
cat /sys/devices/platform/cooling_fan/hwmon/*/fan1_input
```
