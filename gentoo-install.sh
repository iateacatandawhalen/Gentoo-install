#!/bin/bash

# Variables (modify these to fit your setup)
DISK="/dev/sda"    # Target disk
ROOT_PARTITION="/dev/sda1"
SWAP_PARTITION="/dev/sda2"

# Step 1: Partition the disk (Modify as necessary)
echo "Creating partitions on $DISK..."
parted $DISK mklabel gpt
parted $DISK mkpart primary ext4 1MiB 100GiB
parted $DISK mkpart primary linux-swap 100GiB 102GiB
parted $DISK mkpart primary ext4 102GiB 100%

# Step 2: Format the partitions
echo "Formatting partitions..."
mkfs.ext4 $ROOT_PARTITION
mkswap $SWAP_PARTITION
swapon $SWAP_PARTITION

# Step 3: Mount the root partition
echo "Mounting the root partition..."
mount $ROOT_PARTITION /mnt/gentoo

# Step 4: Install the Gentoo base system
echo "Installing Gentoo base system..."
# Select an appropriate mirror
mirror_url="http://distfiles.gentoo.org"
emerge --sync

# Install the basic Gentoo system using stage3 tarball
# This step may take a while
wget $mirror_url/releases/amd64/autobuilds/20250304T214502Z/stage3-amd64-20250304T214502Z.tar.xz -P /mnt/gentoo
tar xpvf /mnt/gentoo/stage3-amd64-*.tar.xz --xattrs --numeric-owner -C /mnt/gentoo

# Step 5: Chroot into the new system
echo "Chrooting into the new system..."
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
cp /etc/resolv.conf /mnt/gentoo/etc/resolv.conf

chroot /mnt/gentoo /bin/bash

# Step 6: Set up the Portage tree
echo "Setting up Portage..."
emerge-webrsync

# Step 7: Install essential packages
echo "Installing essential packages..."
emerge --ask sys-kernel/gentoo-sources
emerge --ask sys-apps/util-linux
emerge --ask sys-boot/limine
emerge --ask x11-base/xorg-server
emerge --ask x11-wm/windowmaker

# Step 8: Install Limine bootloader
echo "Installing Limine bootloader..."
# Install Limine
emerge --ask sys-boot/limine

# Configure Limine
limine-install /mnt/gentoo

# Step 9: Configure the system
echo "Configuring system..."

# Set the timezone to Europe/Copenhagen
echo "Europe/Copenhagen" > /mnt/gentoo/etc/timezone
emerge --config sys-libs/timezone-data

# Set up networking
echo "Configuring networking..."
echo "hostname=\"gentoo\"" > /mnt/gentoo/etc/conf.d/hostname
echo "config_eth0=\"dhcp\"" > /mnt/gentoo/etc/conf.d/net
rc-update add net.eth0 default

# Step 10: Create fstab
echo "Creating fstab..."
genfstab -U /mnt/gentoo >> /mnt/gentoo/etc/fstab

# Step 11: Set the root password
echo "Setting root password..."
passwd

# Step 12: Exit chroot and unmount
echo "Exiting chroot..."
exit

# Step 13: Unmount the filesystems
echo "Unmounting..."
umount -R /mnt/gentoo

# Step 14: Reboot
echo "Installation complete! Rebooting..."
reboot
