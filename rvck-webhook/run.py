#!/bin/python3

import json
import os


def write_properties_file(info: dict):
    for k, v in info.items():
        if v is None:
            continue
        open(k, 'w').write(str(v))

def parse_comment(comment: str):
    """解析comment内容, /check"""

    if not comment.strip().startswith("/check"):
        print(comment.strip(), "| not found /check, ignore")
        return None
    
    res = {}
    if len("/check") == len(comment.strip()):
        return res

    import shlex
    data = {
        item[0]: item[1].strip("'\"") if len(item) == 2 else ""
        for item in [
            str(i).split('=',maxsplit=1)
        for i in shlex.split(comment.strip()[6:])]
    }
    for k in ['lava_template','testcase_url', 'fetch']:
        if k in data:
            res[k] = data.pop(k)
    res["testcase_params"] = "\n".join([f"{k}={v}" for k, v in data.items()])

    # 检查文件是否存在
    for k in ['lava_template','testcase_url',]:
        if k in res and os.system(f'gh api repos/RVCK-Project/lavaci/contents/{res[k]}'):
            raise Exception(f"{k}={res[k]} not found in RVCK-Project/lavaci")

    for k, v in res.items():
        print(f"{k} = '{v}'")
    
    return res

def get_pr_fetch_ref(pr_id, repo):
    """pr 源分支及目标分支, 检查是否可合入mergeable """

    mergeable = json.loads(os.popen(f"gh pr view {pr_id} --json mergeable -R {repo}").read())["mergeable"]
    if mergeable != "MERGEABLE":
        raise Exception(f"{repo}, pr={pr_id}, mergeable: {mergeable}, is not 'MERGEABLE'")
    return f"pull/{pr_id}/head"

def issue_comment(payload: dict):
    """pr|issue comment 触发"""

    # comment 创建
    if payload["action"] != "created":
        return

    res = parse_comment(str(payload["comment"]["body"]))

    if res is None:
        return

    res["REPO"] = payload["repository"]["clone_url"]
    res["ISSUE_ID"] = payload["issue"]["number"]

    # FETCH_REF
    if "pull_request" in payload["issue"]:  # pr
        res["FETCH_REF"] = get_pr_fetch_ref(res["ISSUE_ID"], res["REPO"])
        # res["PATCH_URL"] = payload["issue"]["pull_request"]["patch_url"]
    else:
        if "fetch" not in res:
            raise Exception("params:fetch is required")
        res["FETCH_REF"] = res.pop("fetch")
    
    write_properties_file(res)


def pull_request(payload: dict):
    # pr 创建
    if payload["action"] != "opened":
        return
    
    print("from pr opened")

    res = parse_comment(str(payload["pull_request"]["body"]))
    if res is None:
        res = {}

    res["REPO"] = payload["repository"]["clone_url"]
    res["ISSUE_ID"] = payload["number"]
    res["FETCH_REF"] = get_pr_fetch_ref(res["ISSUE_ID"], res["REPO"])

    write_properties_file(res)


def issues(payload: dict):
    # issue 创建
    if payload["action"] != "opened":
        return
    
    # 解析内容
    res = parse_comment(str(payload["issue"]["body"]))
    if res is None:
        return

    if not len(res.get("fetch", "")):
        raise Exception("params:fetch is required")
    res["FETCH_REF"] = res.pop("fetch")
    res["REPO"] = payload["repository"]["clone_url"]
    res["ISSUE_ID"] = payload["issue"]["number"]

    write_properties_file(res)



support_actions = {
    i.__name__: i
    for i in [issue_comment, pull_request, issues]
}


def main():
    gh_event = os.getenv("x_github_event", "")

    if gh_event not in support_actions:
        raise Exception("unknown event:", gh_event)

    support_actions[gh_event](payload=json.loads(os.getenv("payload", '{}')))


if __name__ == "__main__":
    p= os.getenv("payload", "")
    if len(p):
        main()

