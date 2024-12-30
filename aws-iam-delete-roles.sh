#!/bin/bash

function init() {
  roles=$(aws iam list-roles \
    --max-items 5000 \
    --query "Roles[*].[RoleName]" 2>/dev/null | jq -r ".[][] | select(. | contains(\"${SEARCH_PATTERN}\"))" | xargs)

  # Convert roles string to an array
  IFS=" " read -r -a roles <<<"$roles"

  # Check if any roles were found
  if [ ${#roles[@]} -eq 0 ]; then
    echo "No roles found. Exiting."
    exit 0
  fi

  echo "Found: ${#roles[@]} roles."

  # Prompt user for confirmation
  while true; do
    read -r -p "Do you want to proceed with deletion? (y/n): " yn
    case $yn in
      [Yy]*)
        batchDelete "${roles[@]}"
        break
        ;;
      [Nn]*)
        echo "Deletion aborted."
        exit 0
        ;;
      *)
        echo "Please answer y or n."
        ;;
    esac
  done
}

function batchDelete() {
  roles=("$@")

  echo "Initiated deletion."

  for role in "${roles[@]}"; do
    (
      echo "Deleting: $role"

      # Detach attached policies
      role_attached_policies=$(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[*].PolicyArn' --output text)
      for policy_arn in $role_attached_policies; do
        aws iam detach-role-policy --role-name "$role" --policy-arn "$policy_arn" || {
          echo "Failed to detach policy $policy_arn from role $role"
          continue
        }
      done

      # Delete inline policies
      role_inline_policies=$(aws iam list-role-policies --role-name "$role" --query 'PolicyNames' --output text)
      for policy_name in $role_inline_policies; do
        aws iam delete-role-policy --role-name "$role" --policy-name "$policy_name" || {
          echo "Failed to delete inline policy $policy_name from role $role"
          continue
        }
      done

      # Delete the role
      aws iam delete-role --role-name "$role" || {
        echo "Failed to delete role $role"
        continue
      }
    ) &
    sleep 3  # Add delay between concurrent requests
  done

  wait

  echo "Deletion completed."
}

if [ -z "$1" ]; then
  echo "Provide search pattern of environment to search for."
  exit 1
fi

SEARCH_PATTERN=$1

init