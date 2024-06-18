# ------------------------------- IAM for Barracuda --------------------------------------------

resource "aws_iam_policy" "multi-ip" {
  name   = "${var.site}-multi-ip"
  path   = "/"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeNetworkInterfaces",
                "ec2:UnassignPrivateIpAddresses",
                "ec2:AssignPrivateIpAddresses"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "multi-ip" {
  path = "/"
  name = "${var.site}-multi-ip"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "multi-ip" {
  policy_arn = aws_iam_policy.multi-ip.arn
  role       = aws_iam_role.multi-ip.name
}

resource "aws_iam_instance_profile" "multi-ip" {
  name = "${var.site}-multi-ip-iam-instance-profile"
  role = aws_iam_role.multi-ip.name
}

# ------------------------------- IAM for ha --------------------------------------------

resource "aws_iam_policy" "ha" {
  name        = "${var.site}-ha"
  description = "Policy for HA to communicate with BIG-IP VE instances"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
                "ec2:DescribeNetworkInterfaces",
                "ec2:ModifyInstanceAttribute",
                "ec2:AssignPrivateIpAddresses",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:UnassignPrivateIpAddresses",
                "ec2:DescribeSubnets",
                "ec2:DescribeInstances"
            ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "ha" {
  name = "${var.site}-ha"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ha" {
  role       = aws_iam_role.ha.name
  policy_arn = aws_iam_policy.ha.arn
}

resource "aws_iam_instance_profile" "ha" {
  name = "${var.site}-ha"
  role = aws_iam_role.ha.name
}