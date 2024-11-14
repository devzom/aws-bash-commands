#!/bin/bash

if [ -z "$1" ]; then
  echo "provide search pattern of environment to search for"
  exit
fi

SEARCH_PATTERN=$1

function batchDelete() {
  roles=("$@")

  echo "Initiated deletion."

  for role in "${roles[@]}"; do
    echo "Deleteing role $role"
    role_attached_policies=$(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[*].PolicyArn' --output text)
    for policy_arn in $role_attached_policies; do
      aws iam detach-role-policy --role-name "$role" --policy-arn "$policy_arn"
    done
    role_inline_policies=$(aws iam list-role-policies --role-name "$role" --query 'PolicyNames' --output text)
    for policy_name in $role_inline_policies; do
      aws iam delete-role-policy --role-name "$role" --policy-name "$policy_name"
    done

    aws iam delete-role --role-name "$role"
  done

  echo "Deletion completed."
}

function init() {
  roles=$(aws iam list-roles \
    --max-items 5000 \
    --query "Roles[*].[RoleName]" 2>/dev/null | jq ".[][]|select(.|contains(\"${SEARCH_PATTERN}\"))" | xargs)

  IFS=" " read -r -a roles <<<"$roles"

  if [ ${#roles[@]} -eq 0 ]; then
    echo "No roles found. Exiting."
    exit 0
  fi

  echo "Found: ${#roles[@]}"

  while true; do
    read -r -p "Do you want to proceed deletion?(y/n): " yn
    case $yn in
    [Yy]*)
      batchDelete "${roles[@]}"
      break
      ;;
    [Nn]*) exit ;;
    *) echo "Answer y / n." ;;
    esac
  done
}

init