#!/usr/bin/env bash
set -e
set -x

repo_name=$(echo ${REPO##h*/} | awk -F'.' '{print $1}')
job_name=${repo_name}_pr_${ISSUE_ID}
device_type=$(yq .device_type "${lava_template}")
testcase_name=$(echo "${testcase_path}" | awk -F'/' '{print $2}')
testitem_name=${repo_name}_${testcase_name}_${device_type}
ssh_port=$(od -An -N2 -i /dev/urandom | awk -v min=10000 -v max=20000 '{print min + ($1 % (max - min + 1))}')
lava_server=lava.oerv.ac.cn
lavacli_max_retry=5
lavacli_retry_delay=30 

lavacli_admim(){
    command=$1
    option=$2
    if [ "${option}" = "show" ];then
    	option=${option}" --yaml"
    elif [ ${option} = "wait" ];then
    	option=${option}" --polling 30"
    fi
    jobid=$3
    lavacli --uri https://${lava_admin_token}@${lava_server}/RPC2/ ${command} ${option} ${jobid}
}

yq e ".job_name |= sub(\"\\\${job_name}\",\"${job_name}\")" -i "${lava_template}"
yq e ".context.extra_options[] |=  sub(\"hostfwd=tcp::10001-:22\", \"hostfwd=tcp::${ssh_port}-:22\")" -i "${lava_template}"
yq e ".actions[0].deploy.images.kernel.url |= sub(\"\\\${kernel_image_url}\", \"${kernel_download_url}\")" -i "${lava_template}"
yq e ".actions[0].deploy.images.rootfs.url |= sub(\"\\\${rootfs_image_url}\", \"${rootfs_download_url}\")" -i "${lava_template}"
yq e ".actions[2].test.definitions[0].name |= sub(\"\\\${testitem_name}\",\"${testitem_name}\")" -i "${lava_template}"
yq e ".actions[2].test.definitions[0].path |= sub(\"\\\${testcase_path}\",\"${testcase_path}\")" -i "${lava_template}"
yq e ".actions[2].test.definitions[0].repository |= sub(\"\\\${testcase_repo}\",\"${testcase_repo}\")" -i "${lava_template}"
if [ "$repo_name" = "rvck" ]; then
    yq e ".actions[0].deploy.images.initrd = {\"image_arg\": \"-initrd {initrd}\", \"url\": \"${initrdramfs_url}\"}" -i "${lava_template}"
fi 

if [ "$testcase_params" = "" ]; then
    yq e 'del(.actions[2].test.definitions[0].parameters)' -i "${lava_template}"

else
    while read -r l; do
        if [ "$l" = "" ]; then
            continue
        fi

        k="${l%%=*}"
        v="${l#"${k}="}"
        echo "key: $k, value: $v"
        if ! grep -q "\${$k}" "${lava_template}"; then
            echo "Lava check fail! key=$k is not found in ${lava_template}" > COMMENT_CONTENT
            cat COMMENT_CONTENT
            exit 1
        fi

        sed -i "s@\${$k}@$v@g" "${lava_template}"

    done <<< "$testcase_params"
fi

lava_jobid=$(lavacli_admim jobs submit ${lava_template})

for _i in $(seq 1 ${lavacli_max_retry}); do
    echo " lavacli jobs wait try ${_i} ..."
    lavacli_admim jobs wait ${lava_jobid} && break
    if [ ${_i} -lt ${lavacli_max_retry} ]; then
        echo "wait ${lavacli_retry_delay} second then retry.."
        sleep ${lavacli_retry_delay}
    else
        echo "reach retry maximum number. lavacli jobs wait error!"
        exit 1
    fi
done

sleep 5
lava_result_url=https://${lava_server}/results/${lava_jobid}/0_${testitem_name}
lava_result=$(lavacli_admim jobs show ${lava_jobid} | yq .health)

if [ ${lava_result} = "Complete" ];then
	echo "Lava check done! result url: ${lava_result_url}" > COMMENT_CONTENT
else
	echo "Lava check fail! log: ${BUILD_URL}consoleFull, result url: ${lava_result_url}" > COMMENT_CONTENT
	exit 1
fi
