
#Requirements:
* A VPC with 3 public and 3 private subnets
  * the private subnets must be behind a NAT gateway (or multiple)
* AMI: It's recommended that you use the AMIs supplied in the template, which are CentOS 7 based and come from here: [github.com/irvingpop/packer-chef-highperf-centos7-ami](https://github.com/irvingpop/packer-chef-highperf-centos7-ami)
  * If you use your own, the following things need to be installed:
    - awscli (`aws` command)
    - Cloudformation Helper Scripts (`cfn-init` and `cfn-signal` commands)
    - NTP (installed and enabled)


#Creating a VPC to spec
```bash
# create the VPCs
aws cloudformation create-stack --stack-name myname-vpc --template-body file://vpc/vpc-3azs.yaml --capabilities CAPABILITY_IAM --parameters ParameterKey=ClassB,ParameterValue=42

# create the NAT gateway
aws cloudformation create-stack --stack-name myname-vpc-natgw --template-body file://vpc/vpc-nat-gateway.yaml --capabilities CAPABILITY_IAM --parameters ParameterKey=ParentVPCStack,ParameterValue=myname-vpc

# create the bastion host
aws cloudformation create-stack --stack-name myname-vpc-bastion --template-body file://vpc/vpc-ssh-bastion.yaml --capabilities CAPABILITY_IAM --parameters ParameterKey=ParentVPCStack,ParameterValue=myname-vpc ParameterKey=KeyName,ParameterValue=my_ssh_key
```

# Fire up the backendless chef server stack
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

# SSH to your hosts

If you're using a bastion host:
```bash
ssh -o ProxyCommand="ssh -W %h:%p -q ec2-user@bastion" -l centos <chef server private ip>
```

otherwise just login as `centos` to the private IPs of the chef servers


# Credits

This project was inspired by the work of [Levi Smith](https://github.com/TheFynx) of the Hearst Automation Team and published at [HearstAT/cfn_backendless_chef](https://github.com/HearstAT/cfn_backendless_chef).  Thanks Levi!

Contributors:
- Irving Popovetsky
- Joshua Hudson
- Levi Smith
