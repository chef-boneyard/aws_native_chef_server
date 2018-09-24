#!/bin/bash

# Below are needed for RHEL, which lacks niceties like the AWS tools and lvm
if [[ ! -f /bin/aws ]]; then
  echo ">>> Installing awscli package"
  yum install -y python-cryptography python-docutils
  # Thanks Redhat for hiding these in add-on repos, gotta get these from centos
  rpm -ivh \
    http://mirror.centos.org/centos/7/os/x86_64/Packages/python-s3transfer-0.1.10-8.el7.noarch.rpm \
    http://mirror.centos.org/centos/7/updates/x86_64/Packages/awscli-1.14.28-5.el7_5.1.noarch.rpm
fi

if [[ ! -f /opt/aws/bin/cfn-init ]]; then
  echo ">>> Installing AWS cfn-init tools"
  /usr/bin/easy_install --script-dir /opt/aws/bin https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
  for i in `/bin/ls -1 /opt/aws/bin/`; do ln -s /opt/aws/bin/$i /usr/bin/ ; done
fi

# place your customizations here, for things that run before main.sh

exit 0
