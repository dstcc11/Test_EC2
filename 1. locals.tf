locals {
  ec2 = {
    "test-1" = {
      instance_type = "t2.micro"
      ami           = data.aws_ami.latest_ubuntu.id
      tags = {
        "tag1" = "b1"
        "tag2" = "b2"
        "tag3" = "b3"
      }
    }
  }
}
