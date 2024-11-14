#!/bin/bash
if [ -z "$1" ]; then
  echo "provide SEARCH_PATTERN of environment to search for"
  exit
fi

echo "############################"
echo "Search for roles from AWS IAM $1"
echo "############################"
items=$(aws iam list-roles \
  --max-items 5000 \
  --query "Roles[*].[RoleName]" 2>/dev/null | jq ".[][]|select(.|contains(\"$1\"))" | xargs)

IFS=" " read -r -a items <<<"$items"

count=0
for i in "${items[@]}"; do
  count=$count+1
  echo "${i}"
done
echo "Found: ${#items[@]}"
