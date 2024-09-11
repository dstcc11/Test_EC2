locals {
  ec2 = {
    "test1" = {
      instance_type = "t2.micro"
      ami           = data.aws_ami.latest_ubuntu.id
      ebs_volumes = {
        "MountPoints" = {
          device_name = "/dev/sdd"
          size        = "1"
          type        = "gp3"
        }
      }
      tags = {
        "t1" = "a1"
        "t2" = "a2"
        "t3" = "a3"
      }
    }
  }
}
