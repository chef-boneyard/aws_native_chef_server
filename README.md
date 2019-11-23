[![Build Status](https://travis-ci.org/chef-customers/aws_native_chef_server.svg?branch=master)](https://travis-ci.org/chef-customers/aws_native_chef_server)

# AWS Native Chef Stack
A complete Chef Stack including:
- Chef Automate 2 server, using EC2 Auto-Recovery
- Chef Server cluster utilizing Amazon services for high availability, auto-scaling and DBaaS
- Chef Supermarket server, using EC2 Auto-Recovery

![Chef Server Architecture Diagram](/images/arch-diagram.png?raw=true "Architecture Diagram")

# What does the chef_server_ha template provision?
- A "bootstrap" frontend in an Auto Scaling Group of 1.
- A second frontend in an Auto Scaling Group that will automatically scale up to a configured maximum (default 3)
- A Multi-AZ Elastic Load Balancer
- A Multi-AZ RDS Postgres database
- A Multi-AZ ElasticSearch cluster
- Various security groups, iam profiles, and various pieces to connect the things.
- Cloudwatch alarms and an Operations dashboard in Cloudwatch:

![Dashboard Example](/images/opsdashboard.png?raw=true "Architecture Diagram")

# Using it

## Requirements
* A working knowledge and comfort level with CloudFormation so that you can read and understand this template for your self
* Permissions to create all of the types of resources specified in this template (IAM roles, Database subnets, etc)

## Prerequisites

Before you fire it up, there are a few things you should make sure you have prepped and ready.

* Please review the [Prerequisites doc before proceeding](./PREREQS.md)

## Browser launch instructions (quickstart)

You can launch this stack with the push of a button:

| Edition | Version | Est Monthly cost | Launch button |
| ------- | ------- | ---------------- | ------------- |
| High Performance | 5.1.0 | [$1500*](https://calculator.s3.amazonaws.com/index.html#r=IAD&s=EC2&key=calc-E9251374-D80C-45B7-BED7-C9C9778B1D6C) | <p><a href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?templateURL=https:%2F%2Fs3.amazonaws.com%2Faws-native-chef-server%2F5.1.0%2Fmain.yaml&amp;stackName=my-chef-stack" target="_blank"><img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png" alt="Launch Stack" /></a></p> |
| Lowest Cost | 5.1.0 | [$320*](https://calculator.s3.amazonaws.com/index.html#r=IAD&s=EC2&key=files/calc-165638db8e331664846c0d6654d743377bd3eac6&v=ver20190604sQ) | <p><a href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?templateURL=https:%2F%2Fs3.amazonaws.com%2Faws-native-chef-server%2F5.1.0%2Fmarketplace.yaml&amp;stackName=my-chef-stack" target="_blank"><img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png" alt="Launch Stack" /></a></p> |

_*NOTE: Estimated costs are just that, your mileage will vary. Use reserved instances to greatly reduce costs for long-running clusters._

## CLI Launch instructions
However, the most repeatable and least error-prone way to launch this stack is to use the `aws` command-line. First copy file `stack_parameters_main.json.example` to `stack_parameters_main.json`, make the necessary changes, then run this command:

```bash
MYBUCKET=aws-native-chef-server
MYID=mycompany
VERSION=5.1.0
EDITION=main  # main or marketplace
# Configure the automate_stack_parameters.json and then launch the cloudformation stack:
# If you're using your own bucket, uncomment the next line:
# aws s3 sync . s3://$MYBUCKET/$VERSION/ --exclude "*" --include "*.yaml" --include "files/*" && \
aws cloudformation validate-template --template-url https://s3.amazonaws.com/$MYBUCKET/$VERSION/$EDITION.yaml && \
aws cloudformation create-stack \
  --stack-name ${MYID}-chef-stack \
  --template-url https://s3.amazonaws.com/$MYBUCKET/$VERSION/$EDITION.yaml \
  --capabilities CAPABILITY_IAM \
  --on-failure DO_NOTHING \
  --parameters file://stack_parameters_$EDITION.json
```

## Updating the stack

If you've made changes to the template content or parameters and you wish to update a running stack:

```bash
MYBUCKET=aws-native-chef-server
MYID=mycompany
VERSION=5.1.0
EDITION=main  # main or marketplace
# If you're using your own bucket, uncomment the next line:
# aws s3 sync . s3://$MYBUCKET/$VERSION/ --exclude "*" --include "*.yaml" --include "files/*" && \
aws cloudformation validate-template --template-url https://s3.amazonaws.com/$MYBUCKET/$VERSION/$EDITION.yaml && \
aws cloudformation update-stack \
  --stack-name ${MYID}-chef-stack \
  --template-url https://s3.amazonaws.com/$MYBUCKET/$VERSION/$EDITION.yaml \
  --capabilities CAPABILITY_IAM \
  --parameters file://stack_parameters_$EDITION.json
```

Note: For production instances it is recommended to use the CloudFormation console so that you can get a report of all changes before executing them.  Particularly pay attention to any resources that are being replaced.

## SSH to your hosts

If you're using a bastion host and need to SSH from the outside:

```bash
ssh -o ProxyCommand="ssh -W %h:%p -q centos@bastion" -l centos <chef server private ip>
```
otherwise just SSH directly to the public IPs of the chef servers

## Upgrading the Chef Server

If a new Chef Server or Manage package comes out, the process for upgrading is simple and requires no downtime:

1. Using Cloudformation's `update-stack` functionality, update the `ChefServerPackage` and `ChefManagePackage` parameters to the new URLs.
  - Confirm in the ChangeSet that this will only `ServerLaunchConfig` resource and no others!
2. Wait for the update-stack to run, it may take a few minutes for the new metadata to be available
3. Terminate the bootstrap frontend instance (aka `mystack-chef-bootstrap-frontend`). AutoScale will launch a new one within a few seconds that will pick up the new package versions and upgrade.
4. SSH to the new bootstrap frontend and tail the `/var/log/cfn-init.log` - waiting until you see an `[INFO] syncing bootstrap secrets up to S3` message which lets you know that the upgrade was successful.  There may be a minute or two with no output, because the output isn't live streamed.
  - Caution: if significant database schema changes were made then your remaining frontends may begin throwing 500 errors for certain types of operations.  This doesn't happen often, but you should always perform these test upgrades in a non-production cluster first to understand the ramifications of your change.
5. Terminate all of the non-bootstrap frontend instances.  the same process will happen.
  - alternatively, temporarily increase the desired capacity to launch new instances and then decrease it back to the original level to terminate the old instances
6. You're up to date!

# FAQ

### Is this better than using chef-backend on AWS?

Yes, it is significantly more robust and easier to operate.
- It is based on the architecture of Hosted Chef (albeit simplified)
- AWS RDS and ElasticSearch significantly reduce the maintenance burden compared to chef-backend
- AWS RDS and ElasticSearch provide a much better model for multi-AZ operations than chef-backend, and AWS RDS provides cross-region replication capabilities

### Is this supported by Chef Software, Inc?

- The Chef software installed (Chef Server and add-ons) are fully supported by Chef.  The operating mode (using AWS RDS and ES) is also fully supported by Chef.
- For everything else, there are no support SLAs.  including:
  - The template itself and any errors you may have provisioning services (talk to your Customer Success team if you need help)
  - Any AWS services provisioned (RDS, ElasticSearch) - please direct questions to AWS Customer Support

### What improvements can be made to this template?

- Support for restoring from an RDS Snapshot and existing secrets bucket
- Investigate better secrets handling (AWS secrets service?)
- Investigate alternatives to AWS Postgres RDS, namely AWS Aurora's Postgres mode and/or RedShift

Contributions are welcomed!

# Credits

This project was inspired by the work of [Levi Smith](https://github.com/TheFynx) of the Hearst Automation Team and published at [HearstAT/cfn_backendless_chef](https://github.com/HearstAT/cfn_backendless_chef).  Thanks Levi!

Contributors:
- Irving Popovetsky
- Joshua Hudson
- Levi Smith
- Daniel Bright
