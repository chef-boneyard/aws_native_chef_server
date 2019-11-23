#!/bin/bash

CENTOS_RELEASE='aws-native-chef-server-5.1.*'
IMAGE_OWNERID="446539779517"

printf "Mappings:\n  AMI:\n"

regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)
for region in $regions; do
  centos_ami=$(aws --region $region ec2 describe-images \
  --owners $IMAGE_OWNERID \
  --filters "Name=name,Values=${CENTOS_RELEASE}" \
  --query "sort_by(Images, &CreationDate)[*].ImageId | [-1]" \
  --output "text")

  printf "    $region:\n      centos: $centos_ami\n"
done
