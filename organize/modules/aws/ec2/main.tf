resource "aws_instance" "test_server" {
  ami = "ami-0f19d220602031aed"
  instance_type = "t2.nano"
  subnet_id = var.subnet

  key_name = "terraformclass"

  tags = {
    name: "Test server"
    env: var.env
  }
}
