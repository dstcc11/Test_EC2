locals {
  ec2 = {
    "test-101" = {
      instance_type = "t2.micro"
      ami           = data.aws_ami.latest_ubuntu.id
    }
     "test-3" = {
      instance_type = "t2.micro"
      ami           = data.aws_ami.latest_ubuntu.id
    }
  }
}
