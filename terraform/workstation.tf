resource "aws_iam_role" "ssm" {
  name = "${var.lab_prefix}-ssm-role-${terraform.workspace}"
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

resource "aws_iam_role_policy_attachment" "ssm" {
  role = "${aws_iam_role.ssm.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "workstation" {
  name = "${var.lab_prefix}-ssm-instance-profile-${terraform.workspace}"
  role = "${aws_iam_role.ssm.name}"
}

resource "aws_instance" "workstation" {
  count = "${length(var.participants)}"
  depends_on                  = ["aws_internet_gateway.workshop-gw", "aws_instance.chef_server"]
  ami                         = "${data.aws_ami.amazon_linux.id}"
  instance_type               = "t2.nano"
  vpc_security_group_ids      = ["${aws_security_group.workshop-sg.id}"]
  subnet_id                   = "${aws_subnet.workshop-subnet.id}"
  associate_public_ip_address = true
  key_name                    = "${aws_key_pair.admin.key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.workstation.name}"

  tags {
    Name      = "${var.participants[count.index]} - Workstation - ${var.lab_prefix} - ${terraform.workspace}"
    X-Contact = "${var.aws_tag_x_contact}"
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "20"
    delete_on_termination = true
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = "${file("${var.ssh_private_key_path}")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo service sshd restart",
      "sudo useradd ${var.participants[count.index]} -m -s /bin/bash",
      "echo '${var.participants[count.index]}:${var.workstation_password}' | sudo chpasswd",
      "echo '${var.participants[count.index]} ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/${var.participants[count.index]}",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /tmp/user_files/.chef",
      "sudo chown $(whoami) -R /tmp/user_files",
    ]
  }

  provisioner "file" {
    source = "conf/example_kitchen.yml"
    destination = "/tmp/user_files/example_kitchen.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "echo '${aws_instance.automate.public_ip} automate.workshop.com' | sudo tee -a /etc/hosts",
      "sudo yum update -y && sudo yum install -y docker unzip jq",
      "sudo service docker start && sudo chkconfig docker on",
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chefdk",
      "chef exec gem install kitchen-dokken"
    ]
  }

  # Used to get current InSpec, remove once ChefDK ships InSpec newer than 2.1.59
  provisioner "remote-exec" {
    inline = [
      "curl https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh | sudo bash",
      "sudo hab pkg install chef/inspec",
      "echo 'alias inspec=\"hab pkg exec chef/inspec inspec\"' | sudo tee -a /home/${var.participants[count.index]}/.bashrc",
    ]
  }

  provisioner "file" {
    source = "output/keys/private/${var.participants[count.index]}.pem"
    destination = "/tmp/user_files/.chef/${var.participants[count.index]}.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/user_files/{.,}* /home/${var.participants[count.index]} > /dev/null 2>&1",
      "sudo chown -R ${var.participants[count.index]}:${var.participants[count.index]} /home/${var.participants[count.index]}",
      "sudo touch /home/${var.participants[count.index]}/.chef/knife.rb",
      "sudo runuser -l ${var.participants[count.index]} -c 'cd && knife configure --server-url https://${aws_instance.chef_server.public_dns}/organizations/${var.participants[count.index]} -u ${var.participants[count.index]} --defaults --yes'",
      "sudo runuser -l ${var.participants[count.index]} -c 'cd && knife ssl fetch'",
    ]
  }
}

output "workstation_info" {
  value = "${zipmap(var.participants, aws_instance.workstation.*.public_dns)}"
}
