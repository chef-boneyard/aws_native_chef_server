
#Requirements:
* A VPC with 3 public and 3 private subnets
  * the private subnets must be behind a NAT gateway (or multiple)


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
  ParameterKey=SSLCertificateARN,ParameterValue=arn:aws:iam::862552916454:server-certificate/ip-ub-backend1-trusty-aws-1164570181.us-west-2.elb.amazonaws.com \
  ParameterKey=LicenseCount,ParameterValue=999999 \
  ParameterKey=DBUser,ParameterValue=chefadmin \
  ParameterKey=DBPassword,ParameterValue=VerySecure \
  ParameterKey=KeyName,ParameterValue=irving@getchef.com \
  ParameterKey=VPC,ParameterValue=vpc-0012f067 \
  ParameterKey=SSHSecurityGroup,ParameterValue=sg-bf53c1c6 \
  ParameterKey=PublicSubnetA,ParameterValue=subnet-ff2f279b \
  ParameterKey=PublicSubnetB,ParameterValue=subnet-6c30121a \
  ParameterKey=PublicSubnetC,ParameterValue=subnet-0b61fa53 \
  ParameterKey=PrivateSubnetA,ParameterValue=subnet-fe2f279a \
  ParameterKey=PrivateSubnetB,ParameterValue=subnet-6d30121b \
  ParameterKey=PrivateSubnetC,ParameterValue=subnet-0c61fa54 \
  ParameterKey=NatGatewayIP,ParameterValue=35.160.121.138

```

# SSH to your hosts
```bash
ssh -o ProxyCommand="ssh -W %h:%p -q ec2-user@35.160.211.71" centos@10.42.24.101
```
