#!/bin/bash
set -e


if [ "$REPO" = "" ] || [ "$ISSUE_ID" = "" ]; then
    echo "'REPO' and 'ISSUE_ID' is required"
    exit 1
fi

set -x
if [ "$COMMENT_CONTENT" != "" ]; then
    gh issue comment "$ISSUE_ID" -b "$COMMENT_CONTENT" -R "$REPO"
fi

if [ "$REMOVE_LABEL" != "" ]; then
    gh issue edit "$ISSUE_ID" --remove-label "$REMOVE_LABEL" -R "$REPO" || true
fi

if [ "$ADD_LABEL" != "" ]; then
    gh issue edit "$ISSUE_ID" --add-label "$ADD_LABEL" -R "$REPO"
fi
