provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "region2"
  region = var.region2 # Update with the desired region for the backup copy
}

terraform { 
  cloud { 
    
    organization = "KuTest" 

    workspaces { 
      name = "Test_EC2" 
    } 
  } 
}