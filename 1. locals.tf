locals {
  ec2 = {
    "test1" = { #1
      instance_type        = "t2.micro"
      ami                  = data.aws_ami.latest_amz_linux.id
      iam_instance_profile = "ha"
      ebs_volumes = {
        "vol1" = {
          device_name = "/dev/sdh"
          size        = "50"
          type        = "io2"
          iops        = "5000"
        }
      }
    }
    "win1" = { #2
      instance_type        = "t2.micro"
      ami                  = data.aws_ami.latest_amz_windows2022srv.id
      iam_instance_profile = "ha"
      private_ip           = "172.31.35.101"
    }
    "win2" = { #2
      instance_type        = "t2.micro"
      ami                  = data.aws_ami.latest_amz_windows2022srv.id
      iam_instance_profile = "ha"
      private_ip           = "172.31.35.102"
    }
  }
}