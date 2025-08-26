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

resource "aws_vpc_security_group_ingress_rule" "kube-training-ingress" {
  security_group_id = aws_security_group.kube-training-private.id
  referenced_security_group_id = aws_security_group.kube-training-private.id
  ip_protocol = "-1"
}

### Launch Template Configuration

resource "aws_launch_template" "control-plane" {
  name_prefix = "kube-control-plane-"
  image_id = data.aws_ssm_parameter.al2023_gp3_ami.value
  instance_type = "t3.small"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [ aws_security_group.kube-training-private.id ]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    
  EOF
  )

  tag_specifications {
    resource_type = "instance"
  }
}

resource "aws_launch_template" "worker-node" {
  name_prefix = "kube-worker-node-"
  image_id = data.aws_ssm_parameter.al2023_gp3_ami.value
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [ aws_security_group.kube-training-private.id ]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF
  )

  tag_specifications {
    resource_type = "instance"
  }
}

### Initial server config

# resource "aws_ssm_document" "k8s_training_config" {
#   name          = "K8sTrainingConfiguration"
#   document_type = "Command"
#   document_format = "YAML"

#   content = <<DOC
# schemaVersion: '2.2'
# description: Configure K8s training environment
# mainSteps:
#   - action: aws:runShellScript
#     name: configureK8sServer
#     inputs:
#       runCommand:
#         - yum update -y
#         - systemctl start httpd
#         - systemctl enable httpd
# DOC
# }

# Association to run on all instances with specific tag
# resource "aws_ssm_association" "web_config" {
#   name = aws_ssm_document.k8s_training_config.name
  
#   targets {
#     key    = "tag:Environment"
#     values = ["training"]
#   }
# }

### EC2 instances

resource "aws_instance" "k8s_control_plane" {
  subnet_id = var.private_subnet_id

  launch_template {
    id = aws_launch_template.control-plane.id
    version = "$Latest"
  }
}

resource "aws_instance" "k8s_worker_nodes" {
  count = 2
  subnet_id = var.private_subnet_id

  launch_template {
    id = aws_launch_template.worker-node.id
    version = "$Latest"
  }

  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}

### IAM instance trust policy configuration

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