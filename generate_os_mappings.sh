#!/bin/bash

CENTOS_RELEASE='aws-native-chef-server-5.0.*'
IMAGE_OWNERID="406084061336"

printf "Mappings:\n  AMI:\n"

regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)
for region in $regions; do
  centos_ami=$(aws --region $region ec2 describe-images \
  --owners $IMAGE_OWNERID \
  --filters "Name=name,Values=${CENTOS_RELEASE}" \
  --query "Images[0].ImageId" \
  --output "text")

  printf "    $region:\n      centos: $centos_ami\n"
done
