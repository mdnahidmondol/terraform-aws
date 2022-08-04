resource "aws_vpc" "nahid_vpc" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "terraform-dev"
  }
}


resource "aws_subnet" "nahid_public_subnet" {
  vpc_id                  = aws_vpc.nahid_vpc.id
  cidr_block              = "10.0.0.0/26"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-1a"

  tags = {
    Name = "nahid-public-subnet"
  }
}

resource "aws_internet_gateway" "nahid_internet_gateway" {
  vpc_id = aws_vpc.nahid_vpc.id

  tags = {
    Name = "Nahid-igw"
  }

}

resource "aws_route_table" "nahid_public_rt" {

  vpc_id = aws_vpc.nahid_vpc.id
  tags = {
    Name = "Nahid-publix-rt"
  }

}


resource "aws_route" "nahid_default_rt" {
  route_table_id         = aws_route_table.nahid_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.nahid_internet_gateway.id


}

resource "aws_route_table_association" "nahid_public_assoc" {
  subnet_id      = aws_subnet.nahid_public_subnet.id
  route_table_id = aws_route_table.nahid_public_rt.id
}


resource "aws_security_group" "nahid_sg" {
  name        = "Nahid-sg"
  description = "All Allow inbound traffic"
  vpc_id      = aws_vpc.nahid_vpc.id

  ingress {
    description      = "all allow from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "all allow from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Nahid_all_allow"
  }
}


resource "aws_key_pair" "nahid_auth" {
  key_name   = "nahid_key"
  public_key = file("~/.ssh/aws.pub")
}


resource "aws_instance" "terraform_test" {
  instance_type = "t2.micro"
  ami = data.aws_ami.server_ami.id

  tags = {
    Name = "terraform_test"
  }

  key_name = aws_key_pair.nahid_auth.id
  vpc_security_group_ids = [aws_security_group.nahid_sg.id]
  subnet_id = aws_subnet.nahid_public_subnet.id
  user_data = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }
}