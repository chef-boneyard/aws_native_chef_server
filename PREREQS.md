## Prerequisites

### AMI Acceptance

Before you start, make sure the AMI that is listed in the `backendless_chef.yaml` for your region has been accepted/approved for use in the AWS Marketplace. We are using native Amazon Linux AMIs, the most up to date list is [always here](https://aws.amazon.com/amazon-linux-ami/).

### For SSL
1. You must have a DNS Record Name and Zone Name planned for this cluster to match the SSL certificate.
1. You must have already created and uploaded an SSL cert to AWS. Once you've uploaded the cert, you will need to follow these steps to update the `backendless_chef.yaml` template with the correct values:
   * Update the `SSLCertificateARN` parameter with the `ARN` for the SSL Cert. _For info on how to get the ARN, please follow the [AWS Certificate Manger](https://aws.amazon.com/certificate-manager/) docs._
   * **If you're using AWS Route 53**, fill in the `Route53RecordName` and `Route53HostedZone` parameters for the template
   * **If you're not using AWS Route 53**, create the DNS record in your own nameservers to be a CNAME record that points at the stack's Application Load Balancer (e.g. my-chef-stack-1942464223.us-west-2.elb.amazonaws.com)

### Using with Automate

At this time, this template does not setup Automate as part of it's deployment. However, you can configure it to point to an Automate server that you will setup afterwards, or that is already setup.
1. You should have a token already generated, follow the [instructions here](https://automate.chef.io/docs/data-collection/) on how to generate an Automate token.
1. The Chef Automate URL, for more information on how this URL is formatted, [read this](https://automate.chef.io/docs/data-collection/).

### Package Versions

It's recommended to have the packages downloaded and hosted locally before proceeding, an S3 bucket, Artifactory/Nexus or YUM/APT repository cache works well for this purpose. Once you've downloaded the correct EL7 packages and have them hosted, adjust the following variables accordingly to point to the proper URLs.

* `ChefServerPackage`, `ChefManagePackage`, `PushJobsPackage`

_Here's an example of setting up an S3 cache:_

1. Install `mixlib-install` Ruby Gem from the [mixlib-install repo](https://github.com/chef/mixlib-install) on an EC2 instance that has access to the S3 bucket being used.
1. Install the `aws` cli tool on the same instance from [aws cli](https://aws.amazon.com/cli/).
1. Run the following commands:
    ```
    mixlib-install download chef-server --platform el --platform-version 7.5 --architecture x86_64
    # Starting download https://packages.chef.io/files/stable/chef-server/12.17.33/el/7/chef-server-core-12.17.33-1.el7.x86_64.rpm
    # Download saved to /Users/myname/chef-server-core-12.17.33-1.el7.x86_64.rpm

    aws s3 cp /Users/myname/chef-server-core-12.17.33-1.el7.x86_64.rpm s3://mybucket/package-cache/ --acl public-read
    # upload: ./chef-server-core-12.17.33-1.el7.x86_64.rpm to s3://mybucket/package-cache/chef-server-core-12.17.33-1.el7.x86_64.rpm

    aws s3 presign s3://mybucket/package-cache/chef-server-core-12.17.33-1.el7.x86_64.rpm | cut -d '?' -f 1
    # https://mybucket.s3.amazonaws.com/package-cache/chef-server-core-12.17.33-1.el7.x86_64.rpm
    ```
1. Set the last output (e.g. `https://mybucket.s3.amazonaws.com/package-cache/chef-server-core-12.17.33-1.el7.x86_64.rpm` as shown above) as your `ChefServerPackage` value in `backendless_chef.yaml`.
    

## Network

You must already have a VPC setup properly before continuing setting up the stack, it should;

* Have enough IP's available to assign to nodes
* Be split up into 3 subnets, each in different Availability Zones (AZ's)

## Security

* You should already have created/uploaded an SSH key to AWS and have the ARN available.
* You should already have an Admin SG created for inbound SSH connections. The Security Group ID should be provided for the `InboundAdminSecurityGroupId` parameter in `backendless_chef.yaml`, otherwise you won't have any ssh connectivity to your cluster.

## Amazon ElasticSearch and Service Linked Role (SLR)

Amazon ElasticSearch requires a specific SLR to be created prior to running this CloudFormation template, specifically one called `AWSServiceRoleForAmazonElasticsearchService`. This role cannot be created programmatically as it is created automatically when setting up a VPC access domain in the AWS console. For more information on this [please see this doc from AWS](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/slr-es.html), at this time, even though the doc points to a way to create this manually via the CLI, it still only works via console setup, however AWS adds new features all the time, and by the time you do this, it may work programmatically, please follow their documentation. Once you've created the VPC access domain for AWS ElasticSearch, you can then delete this domain, the role will still be there and you should be able to continue.

_Note: You will need to do this for each region you plan on setting up Chef in_
