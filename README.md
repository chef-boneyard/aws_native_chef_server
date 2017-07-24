# Backendless Chef in AWS
A Chef Server cluster utilizing Amazon services for high availability along with autoscaled frontends.

![Chef Server Backendless Diagram](https://cloud.githubusercontent.com/assets/382062/21002669/26f69096-bce4-11e6-903c-153bb040ae16.png)

# What does this template provision?
- A "bootstrap" frontend in an Auto Scaling Group of 1.
- A second frontend in an Auto Scaling Group that will scale up to 3 total.
- A Multi AZ Elastic Load Balancer instance.
- A Multi AZ RDS Postgres database.
- An ElasticSearch cluster that defaults to 3 shards.
- Basic CloudWatch alarms. (WIP)
- Various security groups, iam profiles, and various pieces to connect the things.

# Using it

## Requirements:
* A VPC with 3 public and 3 private subnets
  * the private subnets must be behind a NAT gateway (or multiple)
* Permissions to create all of the types of resources specified in this template (IAM roles, Database subnets, etc)


## Creating a VPC to spec

If you don't have a VPC configuration that can NAT your chef server's traffic out of a predictable set of public IPs, the following template will help you:

```bash
# create the VPCs
aws cloudformation create-stack --stack-name myname-vpc --template-body file://vpc/vpc-3azs.yaml --capabilities CAPABILITY_IAM --parameters ParameterKey=ClassB,ParameterValue=42

# create the NAT gateway
aws cloudformation create-stack --stack-name myname-vpc-natgw --template-body file://vpc/vpc-nat-gateway.yaml --capabilities CAPABILITY_IAM --parameters ParameterKey=ParentVPCStack,ParameterValue=myname-vpc

# create the bastion host
aws cloudformation create-stack --stack-name myname-vpc-bastion --template-body file://vpc/vpc-ssh-bastion.yaml --capabilities CAPABILITY_IAM --parameters ParameterKey=ParentVPCStack,ParameterValue=myname-vpc ParameterKey=KeyName,ParameterValue=my_ssh_key
```

## Fire up the backendless chef server stack

It is possible to launch using the AWS Cloudformation Console, although you may find it more repeatable and less error-prone to use the command aws command-line way:

```bash
aws cloudformation create-stack \
  --stack-name irving-backendless-chef \
  --template-body file://backendless_chef.yaml \
  --capabilities CAPABILITY_IAM \
  --on-failure DO_NOTHING \
  --parameters \
  ParameterKey=SSLCertificateARN,ParameterValue=arn:aws:acm:us-west-2:446539779517:certificate/60f573b3-f8ed-48d9-a6d1-e89f79da2e8f \
  ParameterKey=LicenseCount,ParameterValue=999999 \
  ParameterKey=DBUser,ParameterValue=chefadmin \
  ParameterKey=DBPassword,ParameterValue=SuperSecurePassword \
  ParameterKey=KeyName,ParameterValue=irving \
  ParameterKey=VPC,ParameterValue=vpc-fa58989d \
  ParameterKey=SSHSecurityGroup,ParameterValue=sg-bddcfbc4 \
  'ParameterKey=LoadBalancerSubnets,ParameterValue="subnet-63c62b04,subnet-dc1611aa,subnet-0247365a"' \
  'ParameterKey=ChefServerSubnets,ParameterValue="subnet-66c62b01,subnet-df1611a9,subnet-01473659"' \
  'ParameterKey=NatGatewayIPs,ParameterValue="35.162.132.208"' \
  ParameterKey=InstanceType,ParameterValue=c4.large \
  ParameterKey=DBInstanceClass,ParameterValue=db.m4.large \
  ParameterKey=ContactEmail,ParameterValue=irving@chef.io \
  ParameterKey=ContactDept,ParameterValue=success
```

## SSH to your hosts

If you're using a bastion host and need to SSH from the outside:

```bash
ssh -o ProxyCommand="ssh -W %h:%p -q ec2-user@bastion" -l ec2-user <chef server private ip>
```

otherwise just login as `ec2-user` to the private IPs of the chef servers

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

### Why are the Chef Frontends required to be behind a NAT gateway?

Because AWS ElasticSearch's authentication model provides some challenges:
- It is IAM integrated, required an AWS-proprietary signing module that Chef server doesn't support
- It allows authentication to be bypassed on an IP basis, but isn't VPC integrated (private IPs don't work, only public IPs)
- Therefore we need a simple model to predict the public IP addresses of the Chef Servers, or else they won't be able to access ElasticSearch (port 9200 will be open, but all requests will be rejected)


### What improvements can be made to this template?

- Upgrade handling - right now there's no support for handling upgrades
- Support for terminating the bootstrap instance (secrets handling code is too naive)
- Integrate an AWS ElasticSearch signing module into the chef server
- Support for restoring from an RDS Snapshot
- Investigate better secrets handling (AWS secrets service?)
- Upgrade the load balancer to the new-style ALB
- Fix an error where the partybus configuration file assumes that Postgres is in localhost
- Investigate alternatives to AWS Postgres RDS, namely AWS Aurora's Postgres mode and/or

Contributions are welcomed!

# Credits

This project was inspired by the work of [Levi Smith](https://github.com/TheFynx) of the Hearst Automation Team and published at [HearstAT/cfn_backendless_chef](https://github.com/HearstAT/cfn_backendless_chef).  Thanks Levi!

Contributors:
- Irving Popovetsky
- Joshua Hudson
- Levi Smith
