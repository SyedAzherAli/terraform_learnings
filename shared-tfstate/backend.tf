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