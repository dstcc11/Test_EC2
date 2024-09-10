locals {
  ec2 = {
    "test-1" = {
      instance_type = "t2.micro"
      ami           = data.aws_ami.latest_ubuntu.id
      tags = {
        "tag1" = "a1"
        "tag2" = "a2"
        "tag3" = "a3"
        }
    }
  }
}
