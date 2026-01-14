# ansible-home

The document assumes:

- the `gateway` system is a [Raspberry Pi 5](https://www.raspberrypi.com/products/raspberry-pi-5/) with a [Pineboards HatDrive! NET 1G](https://thepihut.com/blogs/raspberry-pi-tutorials/pineboards-hatdrive-net-1g-documentation) adapter (NVMe + 1 GB Ethernet), the OS is installed on NVMe, and both Ethernet adapters (original and add-on) are used in a router configuration
- the `server` system is a [Beelink ME mini](https://www.bee-link.com/products/beelink-me-mini-n150) with an Intel N150 CPU, the original 1 TB SSD drive used for the OS, and two additional SSD drives installed for storage

All systems run Ubuntu 24.04 LTS.

## Initial Setup

Update the systems and install the repository dependencies:

```
sudo apt-get update
sudo apt-get full-upgrade
sudo apt-get install python3-pip python3-venv git
bash install.sh
sudo reboot
```

STOP! On the server, follow [README-server.md](README-server.md) before continuing.

## Local Ansible Runs, Prep The Systems Initially

These Ansible invocations assume Ansible is running locally.

These playbooks should only be applied once, after the initial setup.

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

## Main Ansible Playbooks, Routine Maintenance

The next invocations assume Ansible is running remotely. The new inventory files must be created manually, they are not in the repo.

These playbooks are meant for regular system maintenance and configuration.

Server:

```
ansible-playbook -i inventory-server --extra-vars "@extra-vars.yml" main-server.yml --check --diff
ansible-playbook -i inventory-server --extra-vars "@extra-vars.yml" main-server.yml
```

Gateway:

```
ansible-playbook -i inventory-gateway --extra-vars "@extra-vars.yml" main-gateway.yml --check --diff
ansible-playbook -i inventory-gateway --extra-vars "@extra-vars.yml" main-gateway.yml
```

## Extra

Gateway:

Check battery:

```
cat /sys/devices/platform/soc/soc\:rpi_rtc/rtc/rtc0/*_voltage*
```

Check CPU fan:

```
cat /sys/devices/platform/cooling_fan/hwmon/*/fan1_input
```

To allow Windows 11 systems to connect to Samba, run PowerShell as Administrator, and run:

```
Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -Force
```
