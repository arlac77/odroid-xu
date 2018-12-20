# see http://archlinuxarm.org/platforms/armv7/samsung/odroid-xu3

HOSTNAME=$1

read HOSTNAME IP GATEWAY MACADDR PLATFORM PART_SCHEME <<< $(grep $HOSTNAME<<EOF
odroid0  10.0.6.0  10.0.0.2 0:1e:6:10:06:0    odroid-xu3  ext2_only
odroid1  10.0.6.1  10.0.0.2 00:1e:06:31:08:57 odroid-xu3  ext2_only
odroid2  10.0.6.2  10.0.0.2 0:1e:6:10:06:2    odroid-xu3  ext2_only
odroid3  10.0.6.3  10.0.0.2 0:1e:6:10:06:3    odroid-xu3  ext2_only
odroid4  10.0.6.4  10.0.0.2 0:1e:6:10:06:4    odroid-xu3  ext2_only
odroid5  10.0.6.5  10.0.0.2 0:1e:6:10:06:5    odroid-xu3  ext2_only
odroid11 10.0.6.11 10.0.0.2 0:1e:6:10:06:11   odroid-c2   ext2_only
pine1    10.0.6.21 10.0.0.2 0:1e:6:10:06:21   pine64      ext2_only
pine2    10.0.6.22 10.0.0.2 0:1e:6:10:06:22   pine64      ext2_only
pine3    10.0.6.23 10.0.0.2 0:1e:6:10:06:23   pine64      ext2_only
rock1    10.0.6.24 10.0.0.2 3e:2a:57:bf:39:46 aarch64     ext2_only
rpi1     10.0.6.31 10.0.0.2 b8:27:eb:5c:84:bd rpi-3       vfat_ext2
EOF
)

echo $HOSTNAME $IP $GATEWAY $MACADDR $PLATFORM $PART_SCHEME

SDX=/dev/mmcblk1
SDX1=/dev/mmcblk1p1
SDX2=/dev/mmcblk1p2

#SDX=/dev/mmcblk0
#SDX1=/dev/mmcblk0p1

umount $SDX1

dd if=/dev/zero of=$SDX bs=1M count=16

fdisk $SDX << __EOF__ >> /dev/null
o
p
n
p
1


w
__EOF__


cd /tmp
mkdir -p root

mkfs.ext4 $SDX1
mount $SDX1 root

ARCHLINUX_MIRROR="nl2.mirror.archlinuxarm.org"
ARCHLINUX_MIRROR="os.archlinuxarm.org"
ARCHLINUX_MIRROR="dk.mirror.archlinuxarm.org"

curl -O http://${ARCHLINUX_MIRROR}/os/ArchLinuxARM-${PLATFORM}-latest.tar.gz

bsdtar -xzvf ArchLinuxARM-${PLATFORM}-latest.tar.gz -C root

(cd root
 tar cvfp - /etc/systemd/network/eth0.network /root/.ssh /etc/ssh/sshd_config /etc/ssh/ssh_host_* | tar xvfp -
 echo $HOSTNAME >etc/hostname
 #perl setenv macaddr "$MACADDR" boot/boot.txt
 cat >etc/systemd/network/eth0.network <<EOF
[Match]
Name=eth0

[Network]
Address=$IP/16
Gateway=$GATEWAY
EOF
 mkdir -p root/.ssh
 cat >root/.ssh/authorized_keys<<EOF
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPzHP3wE8qlmB9QLwKMK5dIb/Azej+aIg6UmL6YRoHE51ISI4SQc6gBYCfucB9isVns/ucejDRdVQBtthZd/RTM= markus@pro
EOF
)

cd root/boot
./sd_fusing.sh $SDX
cd ../..


umount root
