#!/bin/bash
set -e
set -x


repo_name="$(echo "${REPO##h*/}" | awk -F'.' '{print $1}')"
kernel_result_dir="${repo_name}_pr_${ISSUE_ID}"
download_server=10.211.102.58

kernel_download_url="http://${download_server}/kernel-build-results/${kernel_result_dir}/Image"


## build kernel

make distclean
if [ "$repo_name" = "rvck" ]; then
    make defconfig
else
    make openeuler_defconfig
fi
make Image -j$(nproc)
make modules -j$(nproc)
make dtbs -j$(nproc)

make INSTALL_MOD_PATH="$kernel_result_dir" modules_install -j$(nproc)
mkdir -p "$kernel_result_dir/dtb/thead"
cp vmlinux "$kernel_result_dir"
cp arch/riscv/boot/Image "$kernel_result_dir"
install -m 644 $(find arch/riscv/boot/dts/ -name "*.dtb") "$kernel_result_dir"/dtb
mv $(find arch/riscv/boot/dts/ -name "th1520*.dtb") "$kernel_result_dir"/dtb/thead

## create module tar
module_path_name=$(ls "$kernel_result_dir"/lib/modules/)
module_dir_name=$(basename "$module_path_name")
tar -cvzf "$kernel_result_dir"/"$module_dir_name".tgz -C "$kernel_result_dir"/lib/modules/ "$module_dir_name"

## create initramfs
initramfs_chroot=$(mktemp -d)
mkdir -p ${initramfs_chroot}/dev ${initramfs_chroot}/proc ${initramfs_chroot}/sys ${initramfs_chroot}/run
sudo mount --bind /dev ${initramfs_chroot}/dev
sudo mount --bind /dev/pts ${initramfs_chroot}/dev/pts
sudo mount --bind /dev/shm ${initramfs_chroot}/dev/shm
sudo mount --bind /run ${initramfs_chroot}/run
sudo mount -t proc proc ${initramfs_chroot}/proc
sudo mount -t sysfs sys ${initramfs_chroot}/sys
sudo dnf group install -y "Minimal Install" --forcearch riscv64 --installroot ${initramfs_chroot}
sudo dnf install -y dracut --forcearch riscv64 --installroot ${initramfs_chroot} 
sudo cp -r "$kernel_result_dir"/lib/modules/"$module_dir_name" ${initramfs_chroot}/lib/modules/
sudo chroot ${initramfs_chroot} /bin/bash -c "dracut /root/initramfs.img --no-hostonly --kver ${module_dir_name}"
cp ${initramfs_chroot}/root/initramfs.img "$kernel_result_dir"/
sudo chmod 0644 "$kernel_result_dir"/initramfs.img
# Unmount filesystems if they exist
if [ -d "${initramfs_chroot}/dev/pts" ]; then
    umount ${initramfs_chroot}/dev/pts 2>/dev/null || true
fi
if [ -d "${initramfs_chroot}/dev/shm" ]; then
    umount ${initramfs_chroot}/dev/shm 2>/dev/null || true
fi
if [ -d "${initramfs_chroot}/dev" ]; then
    umount ${initramfs_chroot}/dev 2>/dev/null || true
fi
if [ -d "${initramfs_chroot}/proc" ]; then
    umount ${initramfs_chroot}/proc 2>/dev/null || true
fi
if [ -d "${initramfs_chroot}/sys" ]; then
    umount ${initramfs_chroot}/sys 2>/dev/null || true
fi
if [ -d "${initramfs_chroot}/run" ]; then
    umount ${initramfs_chroot}/run 2>/dev/null || true
fi

if [ "$repo_name" = "rvck" ]; then
    initrdramfs_url="http://${download_server}/kernel-build-results/${kernel_result_dir}/initramfs.img"
fi 

## publish kernel
if [ -f "${kernel_result_dir}/Image" ];then
    rm -fr /mnt/kernel-build-results/"${kernel_result_dir}"
	cp -vr "${kernel_result_dir}" /mnt/kernel-build-results/
else
	echo "Kernel not found!"
	exit 1
fi

# pass download url
echo "${kernel_download_url}" > kernel_download_url
echo "${initrdramfs_url}" > initrdramfs_url


