##### ========== Declaring cloud provider ========== #####
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "eu-central-1"
}
##### ========== Defining availability zone ========== #####
data "aws_availability_zone" "my-zone" {
  name = "eu-central-1b"
}

##### ========== Creating VPC ========== #####
resource "aws_vpc" "my-vpc" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "my-vpc"
  }
}

##### ========== Creating subnet within the VPC and availability zone defined above ========== #####
resource "aws_subnet" "my-net" {
  vpc_id            = "${aws_vpc.my-vpc.id}"
  cidr_block        = "172.16.10.0/24"
  availability_zone = "${data.aws_availability_zone.my-zone.name}"

  #map_public_ip_on_launch = true
  tags {
    Name = "my-net"
  }
}

##### ========== Creating Internet Gateway for internet communication to/from instances in VPC ========== #####
resource "aws_internet_gateway" "my-igw" {
  vpc_id = "${aws_vpc.my-vpc.id}"

  tags {
    Name = "my-igw"
  }
}

##### ========== Creating route to provide a target to Internet-routable traffic from instances in VPC ========== #####
resource "aws_route" "my-route" {
  route_table_id         = "${aws_vpc.my-vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.my-igw.id}"
}

##### ========== Associating the above created route with subnet ========== #####
resource "aws_route_table_association" "my-net-association" {
  subnet_id      = "${aws_subnet.my-net.id}"
  route_table_id = "${aws_vpc.my-vpc.main_route_table_id}"
}

resource "aws_security_group" "my-elb-sg" {
  name = "my-elb-sg"

  vpc_id = "${aws_vpc.my-vpc.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ensure the VPC has an Internet gateway or this step will fail
  depends_on = ["aws_internet_gateway.my-igw"]
}

resource "aws_elb" "my-elb" {
  name = "my-elb"

  # The same availability zone as our instance
  subnets = ["${aws_subnet.my-net.id}"]

  security_groups = ["${aws_security_group.my-elb-sg.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  # The instance is registered automatically

  instances                   = ["${aws_instance.my-jetty-server1.id}", "${aws_instance.my-jetty-server2.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}

##### ========== Creating & Provisioning EC2 instance ========== #####
resource "aws_instance" "my-jetty-server1" {
  ami                         = "ami-97e953f8"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.my-net.id}"
  security_groups             = ["${aws_security_group.my-access-http.id}", "${aws_security_group.my-access-ssh.id}", "${aws_security_group.my-access-tcp.id}"]
  associate_public_ip_address = true
  key_name                    = "smavakey"

  #user_data = "${file("provisioning.sh")}"

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file("/root/.jenkins/workspace/jettyporject/smavakey.pem")}"
  }
  provisioner "file" {
    source      = "provisioning.sh"
    destination = "/root/.jenkins/workspace/jettyporject/provisioning.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /root/.jenkins/workspace/jettyporject/provisioning.sh",
      "/root/.jenkins/workspace/jettyporject/provisioning.sh",
    ]
  }
  tags {
    Name = "my-jetty-server1"
  }
}

resource "aws_instance" "my-jetty-server2" {
  ami                         = "ami-97e953f8"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.my-net.id}"
  security_groups             = ["${aws_security_group.my-access-http.id}", "${aws_security_group.my-access-ssh.id}", "${aws_security_group.my-access-tcp.id}"]
  associate_public_ip_address = true
  key_name                    = "smavakey"

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file("/root/.jenkins/workspace/jettyporject/smavakey.pem")}"
  }

  provisioner "file" {
    source      = "provisioning.sh"
    destination = "/root/.jenkins/workspace/jettyporject/provisioning.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /root/.jenkins/workspace/jettyporject/provisioning.sh",
      "/root/.jenkins/workspace/jettyporject/provisioning.sh",
    ]
  }

  tags {
    Name = "my-app-server2"
  }
}

##### ========== Creating Security Groups ========== #####
resource "aws_security_group" "my-access-http" {
  name   = "my-access-http"
  vpc_id = "${aws_vpc.my-vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "my-access-ssh" {
  name   = "my-access-ssh"
  vpc_id = "${aws_vpc.my-vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "my-access-tcp" {
  name   = "my-access-tcp"
  vpc_id = "${aws_vpc.my-vpc.id}"

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##### ========== Display the value of Public IP assigned to the EC2 instance ========== #####
output "elb_dns" {
  value = "${aws_elb.my-elb.dns_name}"
}

output "public_ip_1" {
  value = "${aws_instance.my-jetty-server1.public_ip}"
}

output "public_ip_2" {
  value = "${aws_instance.my-jetty-server2.public_ip}"
}

