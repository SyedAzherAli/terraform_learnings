# Terraform Shared State file 

## What Is a Terraform State File?
The Terraform state file (terraform.tfstate) is a JSON file that Terraform uses to:

* **Track Infrastructure State**:
It keeps a record of the resources managed by Terraform and their current state in the real world.
* **Plan Changes**:
During terraform plan or terraform apply, Terraform uses the state file to determine what changes are needed.
* **Prevent Drift**:
By comparing the state file with actual infrastructure, Terraform ensures that changes are applied only when necessary.

## Why Share the State File?
When working in a team or across multiple systems, state file sharing provides these benefits:

1.**Consistency**:
All users or automation systems use the same state file, ensuring that changes reflect the actual state of the infrastructure.

2.**Collaboration**:
Multiple team members can work on the same infrastructure without stepping on each other’s changes.

3.**State Locking**:
By sharing the state file via a backend like S3 with DynamoDB locking, Terraform prevents simultaneous updates that could corrupt the state.

4.**Version Control**:
Shared state files ensure everyone has access to the latest infrastructure configuration and changes.

5.**Disaster Recovery**:
Storing the state file in a centralized and reliable backend (e.g., S3) ensures it is not lost if a team member's local machine fails.

6.**CI/CD Pipelines**:
Automated pipelines in tools like Jenkins, GitLab CI, or GitHub Actions can use the shared state to apply changes safely.

7.**Multi-Environment Management**:
When managing multiple environments (e.g., dev, staging, prod), shared state ensures consistent resource management across environments.

8.**Auditing and Tracking**:
By centralizing the state, you can track infrastructure changes and debug issues more effectively.

# Implementation
## Create s3 bucket and Dynomodb 
```
provider "aws" {
  region = "ap-south-1"
}
resource "aws_s3_bucket" "state_bucket" {
  bucket = ""       // Add unique bucket name

  # Prevent accidental deletion of this S3 bucket, comment these block to actual delete s3 bucket 
  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_s3_bucket_versioning" "VC_enable" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_server_side_encription_enable" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# DynamoDB for locking with Terraform
resource "aws_dynamodb_table" "state_lock" {
  name         = ""                       // Add dynomodb table name
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```
Now apply the config 
```
$ terraform init 
$ terraform apply 
```
**Now bucket, we can use these bucket to store our state files using terrafrom backent**
* create a file name backend.tf 
```
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = ""                             // Hardcode bucket name 
    key            = "./terraform.tfstate"
    region         = "ap-south-1"

    # Replace this with your DynamoDB table name!
    dynamodb_table = ""                             // Hardcode dynomoDB name 
    encrypt        = true
  }
}
```
>**NOTE: Any variables or referances are not allowed hear**
>
Run terrafrom init again and apply 
```
$ terraform init

Initializing the backend...
Acquiring state lock. This may take a few moments...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" 
  backend to the newly configured "s3" backend. No existing state 
  was found in the newly configured "s3" backend. Do you want to 
  copy this state to the new "s3" backend? Enter "yes" to copy and 
  "no" to start with an empty state.

  Enter a value:
```
Terraform will automatically detect that you already have a state file locally and prompt you to copy it to the new S3 backend. If you type yes, you should see the following:
```
Successfully configured the backend "s3"! Terraform will automatically use this backend unless the backend configuration changes.
```
After running this command, your Terraform state will be stored in the S3 bucket. You can check this by heading over to the S3 Management Console in your browser and clicking your bucket.
* Now you can use this backend configuration in any of your Terraform projects with your team. The state file will be securely stored in the S3 bucket.
