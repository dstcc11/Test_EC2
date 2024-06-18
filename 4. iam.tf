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
        "ec2:describeinstancestatus",
        "ec2:describenetworkinterfaces",
        "ec2:assignprivateipaddresses"
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