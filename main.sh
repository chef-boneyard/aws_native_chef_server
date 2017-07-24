#!/bin/bash -ex

# Provided variables that are required: STACKNAME, BUCKET, AWS_REGION

# Determine if we are the bootstrap node
INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
BOOTSTRAP_TAGS=`aws ec2 describe-tags --region $AWS_REGION --filter "Name=resource-id,Values=$INSTANCE_ID" --output=text | grep BootstrapAutoScaleGroup`

# If we're not bootstrap, sync down the rest of the secrets first before reconfiguring
if [ -z "${!BOOTSTRAP_TAGS}" ]; then
  echo "[INFO] configuring this node as a regular Chef frontend"
  aws s3 sync s3://${!BUCKET}/${!STACKNAME}/etc_opscode /etc/opscode
  mkdir -p /var/opt/opscode/upgrades
  touch /var/opt/opscode/bootstrapped
  aws s3 cp s3://${!BUCKET}/${!STACKNAME}/migration-level /var/opt/opscode/upgrades/
else
  echo "[INFO] configuring this node as a Bootstrap Chef frontend"
fi
# Configure the chef server
chef-server-ctl reconfigure --accept-license
chef-manage-ctl reconfigure --accept-license
# the bootstrap instance should sync files after reconfigure
if [ -n "${!BOOTSTRAP_TAGS}" ]; then
  echo "[INFO] syncing secrets up to S3"
  aws s3 sync /etc/opscode s3://${!BUCKET}/${!STACKNAME}/etc_opscode
  aws s3 cp /var/opt/opscode/upgrades/migration-level s3://${!BUCKET}/${!STACKNAME}/
fi
