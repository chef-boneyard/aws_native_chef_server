#!/bin/bash

# Below are needed for RHEL, which lacks niceties like the AWS tools and lvm
if [[ ! -f /bin/aws ]]; then
  echo ">>> Installing awscli package"
  yum install -y unzip
  yum erase -y awscli python2-botocore python-s3transfer
  curl -sOL https://s3.amazonaws.com/aws-cli/awscli-bundle.zip
  unzip awscli-bundle.zip
  ./awscli-bundle/install -i /usr/local/aws -b /bin/aws
  rm -rf awscli-bundle awscli-bundle.zip
fi

if [[ ! -f /opt/aws/bin/cfn-init ]]; then
  echo ">>> Installing AWS cfn-init tools"
  /usr/bin/easy_install --script-dir /opt/aws/bin https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
  for i in `/bin/ls -1 /opt/aws/bin/`; do ln -s /opt/aws/bin/$i /usr/bin/ ; done
fi

# place your customizations here, for things that run before main.sh

exit 0
