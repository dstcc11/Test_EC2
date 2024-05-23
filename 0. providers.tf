provider "aws" {
  region = "us-east-1"
}

/*
terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "KuTest"

    workspaces {
      name = "Test_EC2"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "test-tf-aws"
    key            = "terraform.tfstate" #name of the S3 object that will store the state file
    region         = "us-east-1"
    dynamodb_table = "test-tf-aws"
  }
}
*/

terraform {
  cloud {
    organization = "KuTest"

    workspaces {
      name = "Test_EC2"
    }
  }
}