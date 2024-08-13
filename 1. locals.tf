locals {
  ec2 = {
    "site-collector" = {
      instance_type = "t2.micro"
      ami           = data.aws_ami.latest_ubuntu.id
      volume_size   = "75"
      ebs_volumes = {
        "content_repository" = {
          device_name = "/dev/sdx"
          size        = "1"
          type        = "gp3"
        }
        "provenance_repository" = {
          device_name = "/dev/sdy"
          size        = "1"
          type        = "gp3"
        }
        "flowfile_repository" = {
          device_name = "/dev/sdz"
          size        = "1"
          type        = "gp3"
        }
      }
    }
  }
}