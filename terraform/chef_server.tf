data "template_file" "generate_keys" {
  template = "${file("templates/generate_keys.sh.tpl")}"

  vars {
    chef_admin_username = "${var.chef_admin_username}"
    users = "${join(" ", formatlist("'%s'", var.participants))}"
  }
}

data "template_file" "add_keys" {
  template = "${file("templates/add_keys.sh.tpl")}"

  vars {
    user_password = "${var.workstation_password}"
  }
}

resource "aws_instance" "chef_server" {
  depends_on                  = ["aws_internet_gateway.workshop-gw"]
  ami                         = "${data.aws_ami.amazon_linux.id}"
  instance_type               = "t2.medium"
  vpc_security_group_ids      = ["${aws_security_group.workshop-sg.id}"]
  subnet_id                   = "${aws_subnet.workshop-subnet.id}"
  associate_public_ip_address = true
  key_name                    = "${aws_key_pair.admin.key_name}"

  tags {
    Name      = "${var.lab_prefix} - Chef Server - ${terraform.workspace}"
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


  provisioner "local-exec" {
    command = "${data.template_file.generate_keys.rendered}"
    working_dir = "output"
  }

  provisioner "file" {
    source = "output/keys/public"
    destination = "/home/ec2-user/public_keys"
  }

  provisioner "remote-exec" {
    inline = [
      "curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef-server",
      "sudo chef-server-ctl reconfigure",
      "sudo chef-server-ctl user-create ${var.chef_admin_username} Chef Administrator ${var.chef_admin_username}@workshop.com '${var.chef_admin_password}' --filename /tmp/chef_server_admin.pem > /dev/null",
      "sudo chef-server-ctl org-create ${var.chef_admin_username} 'Chef Admin Org' -a ${var.chef_admin_username} --filename /tmp/${var.chef_admin_username}-validator.pem > /dev/null",
    ]
  }

  provisioner "file" {
    content =  "${data.template_file.add_keys.rendered}"
    destination = "~/add_keys.sh"
  }

  provisioner "remote-exec" {
    inline = ["sh ./add_keys.sh"]
  }

  provisioner "local-exec" {
    command = "scp -o 'StrictHostKeyChecking no' ubuntu@${aws_instance.automate.public_dns}:/tmp/automate_api_token output/automate_api_token"
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"api_fqdn '${aws_instance.chef_server.public_dns}'\" | sudo tee /etc/opscode/chef-server.rb",
      "echo \"data_collector['root_url'] = 'https://${aws_instance.automate.public_dns}/data-collector/v0'\" | sudo tee -a /etc/opscode/chef-server.rb",
      "echo \"data_collector['token'] = '${trimspace(file("output/automate_api_token"))}'\" | sudo tee -a /etc/opscode/chef-server.rb",
      "echo \"profiles['root_url'] = 'https://${aws_instance.automate.public_dns}'\" | sudo tee -a /etc/opscode/chef-server.rb",
      "sudo chef-server-ctl reconfigure"
    ]
  }
}

output "chef_server_fqdn" {
  value = "${aws_instance.chef_server.public_dns}"
}
