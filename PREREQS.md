## Prerequisites

### Create an external Route53 zone that is resolvable

In order to use one of the "full stack" templates such as `main.yaml` or `marketplace.yaml`, you must have a domain that is hosted on Route53.  If you're not ready to take the plunge for your entire domain, you can create a subdomain and route all traffic to that (for example chef.mycompany.com).  AWS provides [instructions](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingNewSubdomain.html) and [a video](https://aws.amazon.com/premiumsupport/knowledge-center/create-subdomain-route-53/) on how to do that.

In the parameters, fill in the `Route53HostedZone` parameter to match your Route53 zone, as well as the `AutomateDnsRecordName`, `ChefServerDnsRecordName` and `SupermarketDnsRecordName` values.


### For SSL

You must create or upload at least one SSL certficate to AWS Certificate Manager (ACM).  If you wish, ACM can provide free SSL certificates for you and automatically manages renewals of those certificates.  You may create 3 separate certificates, or a single wildcard certificate (ex: `*.chef.mycompany.com`) that is used in all 3 places.  Since your Route53 zone is now working, use the `DNS Validation` option as it is far faster and more convenient.

In the parameters, fill in the `ChefSSLCertificateARN`, `AutomateSSLCertificateARN` and `SupermarketSSLCertificateARN` values with the ARNs for the certificates. The ARNs are always viewable in the ACM console, an example ACM ARN looks like: `arn:aws:acm:us-west-2:446539779517:certificate/82d30a13-b420-4f43-80de-9e7872f70b96`


## Network

You must already have a VPC setup properly before continuing setting up the stack, it should;

* Have enough IP's available to assign to nodes
* Be split up into 3 subnets, each in different Availability Zones (AZ's)
* Provide the VPC ID and associated subnets to the `VPC` and `ServerSubnets` parameters

## Security

* You should already have created/uploaded an SSH key to AWS. Provide the keypair name to the `KeyName` parameter
* If you're using the `main.yaml` stack, you must also create a security group in the referenced VPC to define your administrative access.  Provide sg ID to the `InboundAdminSecurityGroupId` parameter

## Amazon Elasticsearch and Service Linked Role (SLR)

Amazon Elasticsearch requires a specific SLR to be created prior to running this CloudFormation template, specifically one called `AWSServiceRoleForAmazonElasticsearchService`. This role cannot be created programmatically as it is created automatically when setting up a VPC access domain in the AWS console. For more information on this [please see this doc from AWS](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/slr-es.html), at this time, even though the doc points to a way to create this manually via the CLI, it still only works via console setup, however AWS adds new features all the time, and by the time you do this, it may work programmatically, please follow their documentation. Once you've created the VPC access domain for AWS ElasticSearch, you can then delete this domain, the role will still be there and you should be able to continue.

_Note: You will need to do this for each region you plan on setting up Chef in_
