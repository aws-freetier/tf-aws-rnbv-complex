# tf-aws-rnbv-complex
complex example of infrastructure in aws based on terraform approach

##Notes
Terraform save and use remote state with versioning provided by S3 bucket and state locking providing by DynamoDB

##Used resources 
###AWS
* [Identity and Access Management (IAM)](https://aws.amazon.com/iam/)
* [Secrets Manager](https://aws.amazon.com/secrets-manager/)
* [DynamoDb](https://aws.amazon.com/dynamodb/)
* [S3 bucket](https://aws.amazon.com/s3/)
* [EC2](https://aws.amazon.com/ec2/)
* [VPC](https://aws.amazon.com/vpc/)

###Other
* [GitHub](https://github.com/)
* [Terraform](https://www.terraform.io/)
* [Atlantis](https://www.runatlantis.io/)

##Preparation
1. Create [GitHub's organization account](https://help.github.com/en/enterprise/2.20/admin/user-management/creating-organizations)
2. Create a [Personal Access Token by following](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/#creating-a-token).
Will be enough next scope for token:
    - repo
        - repo:status
        - repo_deployment
        - repo_public
    - admin:repo_hook 
        - read:repo_hook 
        - write:repo_hook 

##Software to install on EC2 instance
* Terraform
* Atlantis
* [Git](https://git-scm.com/)

##Up&Running
1. Create a _secret_ on AWS Secrets Manager
2. Save github personal Access Token to _secret_ on Secrets Manager
3. Create a dedicated IAM role. Set trust relationships created role for identity provider(s) ec2.amazonaws.com
4. Add required policies, at least: 
    - IAMReadOnlyAccess
    - SecretsManagerRead 
    - AmazonEC2FullAccess
    - AmazonS3FullAccess
    - AmazonDynamoDBFullAccess
5. Make initial terraform setup on AWS. (don't forget to change aws region, on that one dedicated for you)
    * Go to folder <root>\live\dev\webserver-cluster.
    * Run next commands
        * `terraform init`
        * `terraform plan` (check the generated output)
        * `terraform apply`
6. Wait Health status on your Application Load Balancer(ALB)
7. The Atlantis service on you EC2 cloud instance listen to you github webhook requests

##Future work
* switch github <-> atlantis communication to https
* move atlantis ASG to private network
* add bastion host for access to atlantis instances
* investigate why atlantis release lock doesn't work