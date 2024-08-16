locals {
  ec2 = {
    "test-1111" = {
      instance_type = "t2.micro"
      ami           = data.aws_ami.latest_ubuntu.id
    }
  }
}
