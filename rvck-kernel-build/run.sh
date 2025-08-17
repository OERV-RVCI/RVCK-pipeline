#!/bin/bash
set -e
set -x


repo_name="$(echo "${REPO##h*/}" | awk -F'.' '{print $1}')"
kernel_result_dir="${repo_name}_pr_${ISSUE_ID}"
download_server=10.213.6.54

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
dracut "$kernel_result_dir"/initramfs.img -k "$kernel_result_dir"/lib/modules/"$module_dir_name" "$module_dir_name"
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


