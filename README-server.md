# RAID

https://www.digitalocean.com/community/tutorials/how-to-create-raid-arrays-with-mdadm-on-ubuntu

List block devices:

```
root@server:~# lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT
NAME          SIZE FSTYPE   TYPE MOUNTPOINT
loop0        33.7M squashfs loop /snap/snapd/21761
nvme0n1     953.9G          disk
├─nvme0n1p1   512M vfat     part /boot/firmware
└─nvme0n1p2 953.4G ext4     part /
nvme1n1       1.7T          disk
nvme2n1       1.7T          disk
```

Create RAID array:

```
root@server:~# mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/nvme1n1 /dev/nvme2n1
mdadm: Note: this array has metadata at the start and
    may not be suitable as a boot device.  If you plan to
    store '/boot' on this device please ensure that
    your boot-loader understands md/v1.x metadata, or use
    --metadata=0.90
mdadm: size set to 1875242304K
mdadm: automatically enabling write-intent bitmap on large array
Continue creating array? y
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```

Check RAID array status (may take a long time to complete, do not wait for this step, keep going):

```
root@server:~# cat /proc/mdstat
Personalities : [raid0] [raid1] [raid6] [raid5] [raid4] [raid10]
md0 : active raid1 nvme2n1[1] nvme1n1[0]
      1875242304 blocks super 1.2 [2/2] [UU]
      [>....................]  resync =  0.0% (991040/1875242304) finish=12790.8min speed=2441K/sec
      bitmap: 14/14 pages [56KB], 65536KB chunk

unused devices: <none>
```

Mount RAID array:

```
root@server:~# mkdir /storage
root@server:~# mount /dev/md0 /storage
root@server:~# df -h /storage
Filesystem      Size  Used Avail Use% Mounted on
/dev/md0        1.8T   28K  1.7T   1% /storage
```

Put the array in mdadm.conf:

```
root@server:~# mdadm --detail --scan | tee -a /etc/mdadm/mdadm.conf
ARRAY /dev/md0 metadata=1.2 UUID=b5550701:d20c0911:9319e2ab:541c4595
root@server:~# update-initramfs -u
update-initramfs: Generating /boot/initrd.img-6.8.0-1015-raspi
Using DTB: bcm2712-rpi-5-b.dtb
Installing /lib/firmware/6.8.0-1015-raspi/device-tree/broadcom/bcm2712-rpi-5-b.dtb into /boot/dtbs/6.8.0-1015-raspi/./bcm2712-rpi-5-b.dtb
Taking backup of bcm2712-rpi-5-b.dtb.
Installing new bcm2712-rpi-5-b.dtb.
flash-kernel: installing version 6.8.0-1015-raspi
Taking backup of vmlinuz.
Installing new vmlinuz.
```

Mount the array permanently:

```
root@server:~# echo '/dev/md0 /storage ext4 defaults,nofail,discard 0 0' >> /etc/fstab
```
