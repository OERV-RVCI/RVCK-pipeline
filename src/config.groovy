
all_params_desc = [
    'REPO': '指定所属仓库, 用于gh ... -R "$REPO"',
    "FETCH_REF": '需要拉取的代码分支或commit_sha',
    'SRC_REF': "pr 请求时, 源分支",
    'ISSUE_ID': '需要评论的issue|pr id',
    
    'kernel_download_url': '内核下载链接',
    'rootfs_download_url': 'rootfs下载链接',
    'lava_template': 'lava测试模板',
    'testcase_url': '需要执行的用例yaml 文件路径',
    'testcase_params': '测试用例参数,[key=value ...]',
    'testcase_repo': 'lava 仓库地址',

    'COMMENT_CONTENT': '评论内容, 用于 gh issue $ISSUE_ID -b "$COMMENT_CONTENT"',
    'ADD_LABEL': "添加标签，多个以英文逗号 ',' 分割",
    'REMOVE_LABEL': "删除标签，多个以英文逗号 ',' 分割",
]

params_defaultvalue = [
    "testcase_repo": 'https://github.com/RVCK-Project/lavaci.git',
    "lava_template": "lava-job-template/qemu/qemu-ltp.yaml",
    "testcase_url": "lava-testcases/common-test/ltp/ltp.yaml",
]

all_params = all_params_desc.collectEntries { name, desc ->
    [(name): string(name: name, description: desc, trim: true, defaultValue: params_defaultvalue.get(name, ''))]
}

check_patch_params_keys = [
    "REPO",
    "ISSUE_ID",
    "FETCH_REF",
    "SRC_REF",
]

kernel_build_params_keys = [
    "REPO",
    "ISSUE_ID",
    "FETCH_REF",
    'lava_template',
    'testcase_url',
    'testcase_params',
]

gh_actions_params_keys = [
    "REPO",
    "ISSUE_ID",
    "COMMENT_CONTENT",
    "ADD_LABEL",
    "REMOVE_LABEL",
]

lava_trigger_params_keys = [
    "REPO",
    "ISSUE_ID",
    "kernel_download_url",
    "rootfs_download_url",
    'testcase_repo',
    "lava_template",
    "testcase_url",
    "testcase_params",
]

kunit_test_params_keys = [
    "REPO",
    "ISSUE_ID",
    "FETCH_REF",
]

label_group = [
    "kernel":[
        "kernel_waiting",
        "kernel_building",
        "kernel_build_failed",
        "kernel_build_succeed",
    ],
    "lava": [
        "lava_waiting",
        "lava_checking",
        "lava_check_done",
        "lava_check_fail",
    ],
    "kunit": [
        "kunit-test_waiting",
        "kunit-test_checking",
        "kunit-test_done",
    ],
    "check-patch": [
        "check-patch_waiting",
        "check-patch_checking",
        "check-patch_done",
    ],
]

return this