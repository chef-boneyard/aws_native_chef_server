## Prerequisites

### AMI Acceptance

Before you start, make sure the AMI that is listed in the `backendless_chef.yaml` for your region has been accepted/approved for use in the AWS Marketplace. We are using native Amazon Linux AMIs, the most up to date list is [always here](https://aws.amazon.com/amazon-linux-ami/).

### For SSL
1. You must have a DNS Record Name and Zone Name defined prior to setup if you want SSL.
1. You must have already created and uploaded an SSL cert to AWS. Once you've uploaded the cert, you will need the `ARN` of the cert resource. For info on how to do this, please follow the [AWS Certificate Manger](https://aws.amazon.com/certificate-manager/) docs.

### Using with Automate

At this time, this template does not setup Automate as part of it's deployment. However, you can configure it to point to an Automate server that you will setup afterwards, or that is already setup.
1. You should have a token already generated, follow the [instructions here](https://docs.chef.io/data_collection.html#step-1-configure-a-data-collector-token-in-chef-automate) on how to generate an Automate token.
1. The Chef Automate URL, for more information on how this URL is formatted, [read this](https://docs.chef.io/data_collection.html#step-2-configure-your-chef-server-to-point-to-chef-automate).

### Package Versions

It's recommended to have the packages downloaded and hosted locally before proceeding, an S3 bucket works well for this purpose. Once you've downloaded the correct EL7 packages and have them hosted, adjust the following variables accordingly to point to the proper URLs.

* `ChefServerPackage`, `ChefManagePackage`, `PushJobsPackage`

## Network

You must already have a VPC setup properly before continuing setting up the stack, it should;

* Have enough IP's available to assign to nodes
* Be split up into 3 subnets, each in different Availability Zones (AZ's)

## Security

* You should already have created/uploaded an SSH key to AWS and have the ARN available.
* You can let this template setup an Admin SG, but it's recommended to use one already in place for SSH, HTTP and HTTPS access.

## Amazon ElasticSearch and Service Linked Role (SLR)

Amazon ElasticSearch requires a specific SLR to be created prior to running this CloudFormation template, specifically one called `AWSServiceRoleForAmazonElasticsearchService`. This role cannot be created programmatically as it is created automatically when setting up a VPC access domain in the AWS console. For more information on this [please see this doc from AWS](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/slr-es.html), at this time, even though the doc points to a way to create this manually via the CLI, it still only works via console setup, however AWS adds new features all the time, and by the time you do this, it may work programmatically, please follow their documentation. Once you've created the VPC access domain for AWS ElasticSearch, you can then delete this domain, the role will still be there and you should be able to continue.

_Note: You will need to do this for each region you plan on setting up Chef in_
