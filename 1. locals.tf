locals {
  ec2 = {
    "test1" = {
      instance_type = "t2.micro"
      ami           = data.aws_ami.latest_ubuntu.id
      tags = {
        "t1" = "a1"
      }
    }
  }
}
