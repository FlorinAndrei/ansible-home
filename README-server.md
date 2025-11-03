# RAID

https://www.digitalocean.com/community/tutorials/how-to-create-raid-arrays-with-mdadm-on-ubuntu

List block devices:

```
# lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT
NAME          SIZE FSTYPE TYPE MOUNTPOIN
nvme0n1       1.7T        disk 
nvme1n1       1.7T        disk 
nvme2n1     931.5G        disk 
├─nvme2n1p1     1G vfat   part /boot/efi
├─nvme2n1p2    50G swap   part [SWAP]
└─nvme2n1p3 880.5G ext4   part /
```

Create RAID array:

```
# mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/nvme0n1 /dev/nvme1n1
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

Check RAID array status:

```
# cat /proc/mdstat
Personalities : [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md0 : active raid1 nvme1n1[1] nvme0n1[0]
      1875242304 blocks super 1.2 [2/2] [UU]
      [>....................]  resync =  0.5% (10803840/1875242304) finish=150.7min speed=206118K/sec
      bitmap: 14/14 pages [56KB], 65536KB chunk

unused devices: <none>
```

RAID array creation may take a long time. You do not have to wait for it to complete. If you wish, you can simply keep going.

Create filesystem:

```
root@server:~# mkfs.ext4 /dev/md0
mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done
Creating filesystem with 468810576 4k blocks and 117202944 inodes
Filesystem UUID: 3035c84f-7836-44bb-a4e9-0d4b7e7a0c51
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968,
        102400000, 214990848

Allocating group tables: done
Writing inode tables: done
Creating journal (262144 blocks): done
Writing superblocks and filesystem accounting information: done
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
root@server:~# echo '/dev/md0 /storage ext4 defaults,nofail 0 0' >> /etc/fstab
```
