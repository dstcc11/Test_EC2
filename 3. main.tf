data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "latest_amz_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn-ami-*"]
  }
}

data "aws_ami" "latest_amz_windows2019srv" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
}

data "aws_ami" "latest_amz_windows2022srv" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}

resource "aws_security_group" "sg" {
  for_each = local.ec2
  name     = each.key
  vpc_id   = data.aws_vpc.default.id
  dynamic "ingress" {
    for_each = try(each.value.ingress_rules, [
      {
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "-1"
        from_port   = "0"
        to_port     = "0"
        description = "default_rule"
      }
    ])
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.key
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ec2-${each.key}"
  }
}

resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Create the Key Pair
resource "aws_key_pair" "key_pair" {
  key_name   = "my-key-pair"
  public_key = tls_private_key.key_pair.public_key_openssh
}

# Save file
resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.key_pair.key_name}.pem"
  content  = tls_private_key.key_pair.private_key_pem
}

output "key" {
  value = aws_key_pair.key_pair.key_name
}

resource "aws_instance" "ec2" {
  for_each                    = local.ec2
  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  subnet_id                   = data.aws_subnet.default.id
  private_ip                  = can(each.value.private_ip) ? (each.value.private_ip != "" ? each.value.private_ip : null) : null
  secondary_private_ips       = can(each.value.secondary_private_ips) ? (each.value.secondary_private_ips != "" ? each.value.secondary_private_ips : null) : null
  vpc_security_group_ids      = [aws_security_group.sg["${each.key}"].id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key_pair.key_name
  iam_instance_profile = can(each.value.iam_instance_profile) ? (each.value.iam_instance_profile != "" ? (
    each.value.iam_instance_profile == "multi-ip" ? aws_iam_instance_profile.multi-ip.name :
    each.value.iam_instance_profile == "ha" ? aws_iam_instance_profile.ha.name :
    null) :
  null) : null
  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = can(each.value.volume_size) ? (each.value.volume_size != "" ? each.value.volume_size : null) : null
  }
  lifecycle {
    ignore_changes = [ami, secondary_private_ips]
    #prevent_destroy = true
  }
  tags = merge(
    lookup(each.value, "tags", {}),
    { Name = "ec2-${each.key}" }
  )

}

resource "aws_ebs_encryption_by_default" "ebs_encrypt" {
  enabled = true
}

locals {
  ebs_volumes_list = flatten([
    for s in keys(local.ec2) : [
      for name, ebs_volume in try(local.ec2[s].ebs_volumes, {}) : {
        key           = "${name}"
        instance_name = s
        device_name   = ebs_volume.device_name
        size          = ebs_volume.size
        type          = can(ebs_volume.type) ? (ebs_volume.type != "" ? ebs_volume.type : null) : null
        iops          = can(ebs_volume.iops) ? (ebs_volume.iops != "" ? ebs_volume.iops : null) : null
      }
    ]
  ])
}

locals {
  vol = { for s in local.ebs_volumes_list : "${s.instance_name}-${s.key}" => s }
}

resource "aws_ebs_volume" "ebs_volumes" {
  for_each          = local.vol
  availability_zone = "us-east-1a"
  size              = each.value.size
  type              = each.value.type
  iops              = each.value.iops
  tags = {
    Name = "${each.key}-ebs"
  }
}

resource "aws_volume_attachment" "ebs_attach" {
  for_each    = local.vol
  device_name = each.value.device_name
  instance_id = aws_instance.ec2[each.value.instance_name].id
  volume_id   = aws_ebs_volume.ebs_volumes[each.key].id
}

/*
resource "aws_ec2_tag" "ec2_tag" {
  for_each    = { for k, v in local.ec2 : k => v if lookup(v, "tags", "") != "" }
  resource_id = aws_instance.ec2[each.key].id
  key         = split(":", each.value.tags)[0]
  value       = split(":", each.value.tags)[1]
}
*/

