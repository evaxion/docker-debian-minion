#!/bin/bash
HEAD_COMMIT_MSG="$(git log --pretty='format:%s' -1)"
EVENT=$(cat <<EOF
{ 
	"head_commit": { 
		"message": "$HEAD_COMMIT_MSG"
	}
}
EOF
)

act -W ./.github/workflows/docker-publish.yml -e <(echo "$EVENT") "$@"
