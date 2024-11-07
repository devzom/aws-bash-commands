#!/bin/bash

if [ -z "${DELETE_PATTERN}" ]
then
      echo "please set DELETE_PATTERN environment variable with pattern to delete"
      exit
fi

#if [ -z "${AWS_PROFILE}" ]
#then
#      echo "please set AWS_PROFILE environment variable"
#      exit
#fi

if [ -z "${AWS_REGION}" ]
then
      echo "please set AWS_REGION environment variable"
      exit
fi

function deleteStacks() {

  stacks=$(aws cloudformation --region ${AWS_REGION} list-stacks --stack-status-filter \
  ${DELETE_PATTERN} --query "StackSummaries[*].StackName" 2>/dev/null | jq '.[]' | xargs)
  IFS=" " read -r -a stacks <<< "$stacks"
  echo "Stacks count: ${#stacks[@]}"

  if [ ${#stacks[@]} -lt 1 ]
    then
        echo "Remaining stacks count: ${#stacks[@]}, Exiting..."
        exit 128
  fi

  for stack in "${stacks[@]}"
  do
    echo "Deleting... ${stack}"
    aws cloudformation delete-stack --stack-name ${stack} --deletion-mode FORCE_DELETE_STACK --region ${AWS_REGION}
  done

  echo "Initiated deletion for all the stacks."
  echo "Sleeping...."
  sleep 120

  deleteStacks
}


function listStacks() {
  echo "####################################################################"
  echo "##  REGION: ${AWS_REGION} DELETE_PATTERN: \"${DELETE_PATTERN}\" ##"
  echo "####################################################################"
  stacks=$(aws cloudformation --region ${AWS_REGION} list-stacks --stack-status-filter \
  ${DELETE_PATTERN} --query "StackSummaries[*].StackName" 2>/dev/null | jq '.[]' | xargs)
  IFS=" " read -r -a stacks <<< "$stacks"

  echo "STACKS: $stacks size: ${#stacks[@]}"
  count=0
  for i in "${stacks[@]}"
  do
    count=$(($count+1))
    echo "${count}. ${i}"
  done
}

listStacks

while true; do
    read -p "Do you want to proceed?(y/n): " yn
    case $yn in
        [Yy]* ) deleteStacks; break;;
        [Nn]* ) exit;;
        * ) echo "Answer y / n.";;
    esac
done