#!/bin/bash

if [ -z "${SEARCH_PATTERN}" ]
then
      echo "please set SEARCH_PATTERN environment variable with pattern to delete"
      exit
fi

function listRoles() {
  echo "############################"
  echo "Read roles from AWS IAM"
  echo "############################"
  items=$(aws iam list-roles \
  --max-items 5000 \
  --query "Roles[*].[RoleName]" 2>/dev/null | jq ".[][]|select(.|contains(\"${SEARCH_PATTERN}\"))" | xargs)

  IFS=" " read -r -a items <<< "$items"

  count=0
  for i in "${items[@]}"
  do
    count=$count+1
    echo "${i}"
  done
  echo "Found: ${#items[@]}"
}

listRoles