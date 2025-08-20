#!/bin/bash
set -e


if [ "$REPO" = "" ] || [ "$ISSUE_ID" = "" ]; then
    echo "'REPO' and 'ISSUE_ID' is required"
    exit 1
fi

max_retry_times=5
set -x
if [ "$COMMENT_CONTENT" != "" ]; then
    for((i=0;i<max_retry_times;i++)); do
        if gh issue comment "$ISSUE_ID" -b "$COMMENT_CONTENT" -R "$REPO"; then 
            break
        fi
        sleep 5
    done
fi

if [ "$REMOVE_LABEL" != "" ]; then
    for((i=0;i<max_retry_times;i++)); do
        if gh issue edit "$ISSUE_ID" --remove-label "$REMOVE_LABEL" -R "$REPO"; then
            break
        fi
        sleep 5
    done
fi

if [ "$ADD_LABEL" != "" ]; then
    for((i=0; i<max_retry_times;i++)); do
        if gh issue edit "$ISSUE_ID" --add-label "$ADD_LABEL" -R "$REPO"; then
            break
        fi
        sleep 5
    done
fi
