#!/bin/bash

roles=("farmer-exp-sae1-e2e-7086-sort-s-get-p-earnings-y-role")

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
