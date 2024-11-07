#!/bin/bash

if [ -z "${SEARCH_PATTERN}" ]; then
  echo "please set SEARCH_PATTERN environment variable with pattern to delete"
  exit
fi

function deleteItems() {
  items=("$@")

  echo "Initiated deletion for all items."

  for role in "${items[@]}"; do
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

function action() {
  items=$(aws iam list-roles \
    --max-items 5000 \
    --query "Roles[*].[RoleName]" 2>/dev/null | jq ".[][]|select(.|contains(\"${SEARCH_PATTERN}\"))" | xargs)

  IFS=" " read -r -a items <<<"$items"

  if [ ${#items[@]} -eq 0 ]; then
    echo "No items found. Exiting."
    exit 0
  fi

  echo "Found: ${#items[@]}"

  while true; do
    read -p "Do you want to proceed deletion?(y/n): " yn
    case $yn in
    [Yy]*)
      deleteItems "${items[@]}"
      break
      ;;
    [Nn]*) exit ;;
    *) echo "Answer y / n." ;;
    esac
  done
}

action