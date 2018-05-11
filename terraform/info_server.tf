data "template_file" "info_page_generator" {
  template = "${file("templates/create_info_pages.rb.tpl")}"

  vars {
    automate_server_fqdn = "${aws_instance.automate.public_dns}"
    automate_token = "${trimspace(file("output/automate_api_token"))}"
    participant_names = "${join(" ", keys(zipmap(var.participants, aws_instance.workstation.*.public_dns)))}"
    participant_fqdns = "${join(" ", values(zipmap(var.participants, aws_instance.workstation.*.public_dns)))}"
    workstation_password = "${var.workstation_password}"
  }
}

resource "aws_instance" "info_server" {
  depends_on                  = ["aws_internet_gateway.workshop-gw"]
  ami                         = "${data.aws_ami.amazon_linux.id}"
  instance_type               = "t2.nano"
  vpc_security_group_ids      = ["${aws_security_group.workshop-sg.id}"]
  subnet_id                   = "${aws_subnet.workshop-subnet.id}"
  associate_public_ip_address = true
  key_name                    = "${aws_key_pair.admin.key_name}"

  tags {
    Name      = "${var.lab_prefix} - Info Server - ${terraform.workspace}"
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
      "sudo yum update -y && sudo yum install -y nginx ruby",
      "echo -n '${var.lab_prefix}:' | sudo tee /etc/nginx/.htpasswd",
      "openssl passwd -apr1 ${var.workstation_password} | sudo tee -a /etc/nginx/.htpasswd",
    ]
  }

  provisioner "file" {
    content = "${data.template_file.info_page_generator.rendered}"
    destination = "~/create_info_pages.rb"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo ruby ~/create_info_pages.rb"
    ]
  }

  provisioner "file" {
    source = "conf/nginx.conf"
    destination = "/tmp/nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/nginx.conf /etc/nginx/nginx.conf",
      "sudo chkconfig nginx on && sudo service nginx start"
    ]
  }
}

output "info_server_fqdn" {
  value = "${aws_instance.info_server.public_dns}"
}
