#!/bin/bash -x

# Provided variables that are required: STACKNAME, BUCKET, AWS_REGION
test -n "${STACKNAME}" || exit 1
test -n "${BUCKET}" || exit 1
test -n "${AWS_REGION}" || exit 1
test -n "${WAITHANDLE}" || exit 1

# Determine if we are the bootstrap node
# BOOTSTRAP_TAGS will be empty if not
INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
BOOTSTRAP_TAGS=`aws ec2 describe-tags --region $AWS_REGION --filter "Name=resource-id,Values=$INSTANCE_ID" --output=text | grep BootstrapAutoScaleGroup`

# Check if the configs already exist in S3 - a sign that bootstrap already successfully happened once
CONFIGS_EXIST=`aws s3 ls s3://${BUCKET}/${STACKNAME}/ | grep migration-level`

# from this point on, exit on any errors and notify the waithandle that something bad happened
set -e
function error_exit {
  echo "Error on line $1"
  /opt/aws/bin/cfn-signal -e 1 -r "Error on line $1" "${WAITHANDLE}"
  exit 1
}
trap 'error_exit $LINENO' ERR

function download_config () {
  aws s3 sync s3://${BUCKET}/${STACKNAME}/etc_opscode /etc/opscode --exclude "chef-server.rb"
  mkdir -p /var/opt/opscode/upgrades
  touch /var/opt/opscode/bootstrapped
  aws s3 cp s3://${BUCKET}/${STACKNAME}/migration-level /var/opt/opscode/upgrades/
}

function upload_config () {
  aws s3 sync /etc/opscode s3://${BUCKET}/${STACKNAME}/etc_opscode
  aws s3 cp /var/opt/opscode/upgrades/migration-level s3://${BUCKET}/${STACKNAME}/
}

function server_reconfigure () {
  chef-server-ctl reconfigure --chef-license=accept
  chef-manage-ctl reconfigure --accept-license
}

function server_upgrade () {
  chef-server-ctl reconfigure --chef-license=accept
  chef-server-ctl upgrade
  chef-server-ctl start
  chef-manage-ctl reconfigure --accept-license
}

function prevent_dns_overload {
  # erchef will constantly try to DNS lookup the bookshelf hostname, which is simply itself.
  # as a workaround, we're just going to put the hostname
  echo "`hostname -i` `hostname -f`" >> /etc/hosts
}

function push_jobs_configure () {
	chef-server-ctl reconfigure --accept-license
	opscode-push-jobs-server-ctl reconfigure
	chef-server-ctl restart
}

# Here we go
prevent_dns_overload

# If we're not bootstrap OR a config already exists, sync down the rest of the secrets first before reconfiguring
if [ -z "${BOOTSTRAP_TAGS}" ] || [ -n "${CONFIGS_EXIST}" ] ; then
  echo "[INFO] configuring this node as a regular Chef frontend or restoring a Bootstrap"
  download_config
else
  echo "[INFO] configuring this node as a Bootstrap Chef frontend"
fi

# Upgrade/Configure handler
# If we're a bootstrap and configs already existed, upgrade
if [ -n "${BOOTSTRAP_TAGS}" ] && [ -n "${CONFIGS_EXIST}" ] ; then
  echo "[INFO] Looks like we're on a boostrap node that may need to be upgraded"
  server_upgrade
else
  echo "[INFO] Running chef-server-ctl reconfigure"
  server_reconfigure
fi

# the bootstrap instance should sync files after reconfigure, regardless if configs exist or not (upgrades)
if [ -n "${BOOTSTRAP_TAGS}" ]; then
  echo "[INFO] Configuring push jobs"
  push_jobs_configure
  echo "[INFO] syncing bootstrap secrets up to S3"
  upload_config
fi
