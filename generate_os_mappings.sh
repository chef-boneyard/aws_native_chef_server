#!/bin/bash

# get the latest Name value from: 
# RHEL: aws ec2 describe-images --owners 309956199498 --filters "Name=name,Values=RHEL-7.6*" --query "Images[*].Name" --output text
# CentOS highperf: `aws ec2 describe-images --owners 446539779517 --filters "Name=name,Values=chef-highperf-centos7*" --query "Images[*].Name" | sort`

RHEL_RELEASE='RHEL-7.6_HVM_GA-20190128-x86_64-0-Hourly2-GP2'
CENTOS_RELEASE='chef-highperf-centos7-201902131539'

printf "Mappings:\n  AMI:\n"

regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)
for region in $regions; do
  rhel_ami=$(aws --region $region ec2 describe-images \
  --filters "Name=name,Values=${RHEL_RELEASE}" \
  --query "Images[0].ImageId" --output "text")

  centos_ami=$(aws --region $region ec2 describe-images \
  --filters "Name=name,Values=${CENTOS_RELEASE}" \
  --query "Images[0].ImageId" --output "text")

  printf "    $region:\n      rhel: $rhel_ami\n      centos: $centos_ami\n"
done
