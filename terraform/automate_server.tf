data "template_file" "add_automate_users" {
  template = "${file("templates/add_automate_users.rb.tpl")}"

  vars {
    users = "${join(" ", var.participants)}"
    user_password = "${var.workstation_password}"
  }
}

resource "aws_iam_policy" "scanning" {
  name = "${var.lab_prefix}-automate-scanning-policy-${terraform.workspace}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ssm:*",
        "ec2:DescribeRegions",
        "sts:GetCallerIdentity",
        "ec2:DescribeInstanceStatus",
        "iam:GenerateCredentialReport",
        "iam:Get*",
        "iam:List*",
        "iam:SimulateCustomPolicy",
        "iam:SimulatePrincipalPolicy"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "scanning" {
  name = "${var.lab_prefix}-scanning-role-${terraform.workspace}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "scanning" {
  role = "${aws_iam_role.scanning.name}"
  policy_arn = "${aws_iam_policy.scanning.arn}"
}

resource "aws_iam_instance_profile" "automate" {
  name = "${var.lab_prefix}-automate-instance-profile-${terraform.workspace}"
  role = "${aws_iam_role.scanning.name}"
}

resource "aws_instance" "automate" {
  depends_on                  = ["aws_internet_gateway.workshop-gw"]
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.medium"
  vpc_security_group_ids      = ["${aws_security_group.workshop-sg.id}"]
  subnet_id                   = "${aws_subnet.workshop-subnet.id}"
  associate_public_ip_address = true
  key_name                    = "${aws_key_pair.admin.key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.automate.name}"

  tags {
    Name      = "${var.lab_prefix} - Automate Server - ${terraform.workspace}"
    X-Contact = "${var.aws_tag_x_contact}"
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "20"
    delete_on_termination = true
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file("${var.ssh_private_key_path}")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sudo apt-get install -y unzip ruby",
      "curl https://packages.chef.io/files/${var.automate_channel}/automate/latest/chef-automate_linux_amd64.zip | gunzip - > chef-automate",
      "sudo sysctl -w vm.max_map_count=262144",
      "sudo sysctl -w vm.dirty_expire_centisecs=20000",
      "sudo chmod +x chef-automate",
      "sudo ./chef-automate init-config --channel '${var.automate_channel}' --file '/tmp/config.toml'",
      "sudo sed -i 's/fqdn = .*/fqdn = \"${aws_instance.automate.public_dns}\"/' /tmp/config.toml",
      "sudo ./chef-automate deploy /tmp/config.toml --admin-password '${var.automate_admin_password}' --accept-terms-and-mlsa && sudo rm /tmp/config.toml",
      "sudo ./chef-automate license apply ${var.automate_license}",
      "sudo ./chef-automate admin-token > /tmp/automate_api_token 2>/dev/null",
    ]
  }

  provisioner "file" {
    content = "${data.template_file.add_automate_users.rendered}"
    destination = "~/add_automate_users.rb"
  }

  provisioner "remote-exec" {
    inline = ["ruby ./add_automate_users.rb https://${aws_instance.automate.public_dns} $(cat /tmp/automate_api_token)"]
  }
}

output "automate_server_fqdn" {
  value = "${aws_instance.automate.public_dns}"
}
