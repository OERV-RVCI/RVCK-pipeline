#!/bin/bash
set -e
set -x


repo_name="$(echo "${REPO##h*/}" | awk -F'.' '{print $1}')"
kernel_result_dir="${repo_name}_pr_${ISSUE_ID}"
download_server=10.213.6.54
rootfs_download_url='https://mirror.iscas.ac.cn/openeuler-sig-riscv/openEuler-RISC-V/RVCK/openEuler24.03-LTS-SP1/openeuler-rootfs.img'
kernel_download_url="http://${download_server}/kernel-build-results/${kernel_result_dir}/Image"


## build kernel

make distclean
make openeuler_defconfig
make Image -j$(nproc)
make modules -j$(nproc)
make dtbs -j$(nproc)

make INSTALL_MOD_PATH="$kernel_result_dir" modules_install -j$(nproc)
mkdir -p "$kernel_result_dir/dtb/thead"
cp vmlinux "$kernel_result_dir"
cp arch/riscv/boot/Image "$kernel_result_dir"
install -m 644 $(find arch/riscv/boot/dts/ -name "*.dtb") "$kernel_result_dir"/dtb
mv $(find arch/riscv/boot/dts/ -name "th1520*.dtb") "$kernel_result_dir"/dtb/thead


## publish kernel
if [ -f "${kernel_result_dir}/Image" ];then
	cp -vr "${kernel_result_dir}" /mnt/kernel-build-results/
else
	echo "Kernel not found!"
	exit 1
fi

# pass download url
echo "${kernel_download_url}" > kernel_download_url
echo "${rootfs_download_url}" > rootfs_download_url