resource "aws_security_group" "allow_load_balancer_access" {
  name = "allow_load_balancer_access"
  description = "Allows connections from load balancer and access to the internet"

  ingress = [{
    cidr_blocks = ["0.0.0.0/0"]
    description = "loadbalancer ingress"
    protocol = "tcp"
    from_port = 8000
    to_port = 8000
    self = false

    ipv6_cidr_blocks = []
    security_groups  = []
    prefix_list_ids = []
  }]

  egress = [{
    cidr_blocks = ["0.0.0.0/0"]
    description = "internet egress"
    protocol = "-1"
    from_port = 0
    to_port = 0

    self = false
    ipv6_cidr_blocks = []
    security_groups  = []
    prefix_list_ids = []
  }]
}

resource "aws_s3_bucket" "instance_information" {
  bucket = "instance-information-store"
}

resource "aws_instance" "test_server" {
  count = 3
  ami = "ami-0f19d220602031aed"
  instance_type = "t2.nano"

  key_name = "terraformclass"

  vpc_security_group_ids = [aws_security_group.allow_load_balancer_access.id]
  depends_on = [aws_s3_bucket.instance_information]

  user_data = <<-EOF
    #!/bin/bash
    python3 -m http.server
  EOF

  tags = {
    name: "Test server ${count.index}"
    env: var.env
  }
}

# Load balancer
resource "aws_elb" "test_load_balancer" {
  name               = "test-load-balancer"
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]

  listener {
    instance_port     = 8000 # assumes an application is running at port 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  instances                   = aws_instance.test_server[*].id
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "test-server-terraform-elb"
  }
}
