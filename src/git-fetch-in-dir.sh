#!/bin/bash
set -e
set -x

# 当前文件夹下, 初始化仓库, 拉取指定分支

# 环境变量：
## REPO, 拉取仓库
## GIT_FETCH_DEPTH, 可选 --depth=$GIT_FETCH_DEPTH
## MAX_RETRY_TIMES, 重试次数，默认=10
# 参数:
## 需要拉取的commit或分支, 支持多参

GIT_FETCH_DEPTH="${GIT_FETCH_DEPTH:+"--depth=$GIT_FETCH_DEPTH"}"
MAX_RETRY_TIMES="${MAX_RETRY_TIMES:-10}"

git init .
git config user.email rvci@isrc.iscas.ac.cn
git config user.name rvci
git remote add origin "${REPO}"

for fetch_ref in "$@"; do
    res=false
    for((retry_times=0; retry_times < MAX_RETRY_TIMES; retry_times++)); do
        if git fetch origin "$fetch_ref":"$fetch_ref" "$GIT_FETCH_DEPTH" --progress; then
            res=true
            break
        fi
    done
    if [ "$res" != "true" ]; then
        exit 1
    fi
done

git checkout "$1"