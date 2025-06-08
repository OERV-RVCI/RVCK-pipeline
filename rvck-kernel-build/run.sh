#!/bin/bash
set -e
set -x


repo_name="$(echo "${REPO%.git}" | awk -F'/' '{print $(NF-1)"_"$NF}')"
kernel_result_dir="${repo_name}_pr_${ISSUE_ID}"
download_server=10.213.6.54

kernel_download_url="http://${download_server}/kernel-build-results/${kernel_result_dir}/Image"

kernel_result_dir="$kernel_result_dir" bash "$(dirname "$0")/kernel-build.sh"

## publish kernel
if [ -f "${kernel_result_dir}/Image" ];then
	cp -vr "${kernel_result_dir}" /mnt/kernel-build-results/
else
	echo "Kernel not found!"
	exit 1
fi

# pass download url
echo "${kernel_download_url}" > kernel_download_url

