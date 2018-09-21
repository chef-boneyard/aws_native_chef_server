#!/bin/bash

if [[ ! -f /opt/aws/bin/cfn-init ]]; then
  echo ">>> Installing AWS cfn-init tools"
  /usr/bin/easy_install --script-dir /opt/aws/bin https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
  for i in `/bin/ls -1 /opt/aws/bin/`; do ln -s /opt/aws/bin/$i /usr/bin/ ; done
fi

# place your customizations here, for things that run before main.sh

exit 0
