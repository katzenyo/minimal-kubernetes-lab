#  latest AMI for us-east-1
data "aws_ssm_parameter" "al2023_gp3_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

### Security group config

resource "aws_security_group" "kube-training-private" {
  name = "kube-training-private-sg"
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "kube-training-private-outbound" {
  security_group_id = aws_security_group.kube-training-private.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

### Launch Template Configuration

resource "aws_launch_template" "app" {
  name_prefix = "kube-worker-node-"
  image_id = data.aws_ssm_parameter.al2023_gp3_ami.value
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [ var.sg_app_id ]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum install -y httpd
    echo "hello world! this is my dev plan app tier $(hostname)" > /var/www/html/index.html
    systemctl enable --now httpd
  EOF
  )

  tag_specifications {
    resource_type = "instance"
  }
}

### IAM configuration

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [ "ec2.amazonaws.com" ]
    }
    actions = [ "sts:AssumeRole" ]
  }
}

resource "aws_iam_role" "ec2_role" {
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  name = "kube-training-ec2-ssm-role"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "kube-training-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_readonly" {
  role = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}