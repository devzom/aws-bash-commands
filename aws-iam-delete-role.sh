#!/bin/bash

function init {
  role="$1"

  echo "Deleting role $role"
  role_attached_policies=$(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[*].PolicyArn' --output text)
  for policy_arn in ${role_attached_policies}; do
    aws iam detach-role-policy --role-name "$role" --policy-arn "$policy_arn"
  done
  role_inline_policies=$(aws iam list-role-policies --role-name "$role" --query 'PolicyNames' --output text)
  for policy_name in ${role_inline_policies}; do
    aws iam delete-role-policy --role-name "$role" --policy-name "$policy_name"
  done

  aws iam delete-role --role-name "$role"
}

if [ -z "$1" ]; then
  echo "Provide search pattern of environment to search for."
  exit 1
fi

SEARCH_PATTERN=$1

init "$SEARCH_PATTERN"
