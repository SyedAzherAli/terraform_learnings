provider "aws" {
    region = "ap-south-1"
}
//creating vpc 
resource "aws_vpc" "custom_vpc"{
    cidr_block = "20.0.0.0/16"
    tags = {
        Name = "awsProject-vpc"
    }
}

//creating public subnet-01
resource "aws_subnet" "pub_sub01" {
    vpc_id = aws_vpc.custom_vpc.id
    cidr_block = "20.0.0.0/19"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    tags = { 
        Name = "web-pub-sub1" 
    }
}
//creating public subnet-02
resource "aws_subnet" "pub_sub02" {
    vpc_id = aws_vpc.custom_vpc.id
    cidr_block = "20.0.32.0/19"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = true
    tags = { 
        Name = "web-pub-sub2" 
    }
}
//creating private subnet-01
resource "aws_subnet" "pvt_sub01" {
    vpc_id = aws_vpc.custom_vpc.id
    cidr_block = "20.0.64.0/19"
    availability_zone = "ap-south-1a"
    tags = { 
        Name = "app-pvt-sub1" 
    }
}
//creating private subnet-02
resource "aws_subnet" "pvt_sub02" {
    vpc_id = aws_vpc.custom_vpc.id
    cidr_block = "20.0.96.0/19"
    availability_zone = "ap-south-1b"
    tags = { 
        Name = "app-pvt-sub2" 
    }
}
//creating private db-subnet-01
resource "aws_subnet" "db_sub01" {
    vpc_id = aws_vpc.custom_vpc.id
    cidr_block = "20.0.128.0/19"
    availability_zone = "ap-south-1a"
    tags = { 
        Name = "db-pvt-sub1" 
    }
}
//creating private db-subnet-01
resource "aws_subnet" "db_sub02" {
    vpc_id = aws_vpc.custom_vpc.id
    cidr_block = "20.0.160.0/19"
    availability_zone = "ap-south-1b"
    tags = { 
        Name = "db-pvt-sub2" 
    }
}

//creating internet gateway 
resource "aws_internet_gateway" "custom_IGW" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "my-igw"
  }

}

//creating route table 
resource "aws_route_table" "route-web" {
    vpc_id = aws_vpc.custom_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.custom_IGW.id
    }

    tags = {
        Name = "route-web"
    }
}

//creating subnet association for public subnets
resource "aws_route_table_association" "subnet_association01" {
  subnet_id      = aws_subnet.pub_sub01.id
  route_table_id = aws_route_table.route-web.id
}
resource "aws_route_table_association" "subnet_association02" {
  subnet_id      = aws_subnet.pub_sub02.id
  route_table_id = aws_route_table.route-web.id
}

//Create a NAT Gateway for the private subnet (requires an Elastic IP)
resource "aws_eip" "nat_eip" {
 
}
resource "aws_nat_gateway" "my-nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.pub_sub01.id

  tags = {
    Name = "my-nat"
  }
}
//creating route table for private subnets to nat gateway 
resource "aws_route_table" "route-app" {
    vpc_id = aws_vpc.custom_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id  = aws_nat_gateway.my-nat.id
    }

    tags = {
        Name = "route-app"
    }
}

resource "aws_route_table_association" "subnet_association03" {
  subnet_id      = aws_subnet.pvt_sub01.id
  route_table_id = aws_route_table.route-app.id
}
resource "aws_route_table_association" "subnet_association04" {
  subnet_id      = aws_subnet.pvt_sub02.id
  route_table_id = aws_route_table.route-app.id
}
resource "aws_route_table_association" "subnet_association05" {
  subnet_id      = aws_subnet.db_sub01.id
  route_table_id = aws_route_table.route-app.id
}
resource "aws_route_table_association" "subnet_association06" {
  subnet_id      = aws_subnet.db_sub02.id
  route_table_id = aws_route_table.route-app.id
}

//crating security group 01 for jump-sg 
resource "aws_security_group" "jump_sg" {
  name        = "jump_sg"
  vpc_id      = aws_vpc.custom_vpc.id

  tags = {
    Name = "jump_sg"
  }
}
//inbound rules 
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.jump_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.jump_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
//outbound rules 
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.jump_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
//outbond rules for ipv6
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.jump_sg.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

//creating security group 02 for app-server  
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  vpc_id      = aws_vpc.custom_vpc.id

  tags = {
    Name = "app-sg"
  }
}
//inbound rules 
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp" #-1 means all protocols 
  to_port           = 22
}
resource "aws_vpc_security_group_ingress_rule" "all" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 0
  ip_protocol       = "tcp"
  to_port           = 65535
}
//outbound rules 
resource "aws_vpc_security_group_egress_rule" "ipv4" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
//outbond rules for ipv6
resource "aws_vpc_security_group_egress_rule" "ipv6" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

variable "key_pair_name" {
  description = "aws key pair"
}
variable "key_pair_source"{
    description = "key pair source path"
}
variable "key_pair_destination" {
    description = "path to key pair to be copied"
}

//creating ec2_instance from public subnet 
resource "aws_instance" "jump-server" {
  ami           = "ami-04a37924ffe27da53"
  instance_type = "t2.micro"
  key_name = var.key_pair_name
  subnet_id = aws_subnet.pub_sub01.id
  vpc_security_group_ids = [ aws_security_group.jump_sg.id ]
  user_data = file("ansible_install.sh")
provisioner "file" {
    source      = var.key_pair_source # Local file path
    destination = var.key_pair_destination       # Destination path on EC2
} 
provisioner "file" {
    source      = "ansible_playbook" # Local file path
    destination = "/home/ec2-user/ansible_playbook" # Destination path on EC2
}
connection {
      type     = "ssh"
      user     = "ec2-user"                      # Adjust if necessary for your AMI
      private_key = file(var.key_pair_source)        # Path to your private key
      host     = self.public_ip                   # Use public IP of the instance
    }
 tags = {
    Name = "jump-server"
  }           
}
//creating ec2_instances from private subnets
resource "aws_instance" "app_server01" {
  ami           = "ami-04a37924ffe27da53"
  instance_type = "t2.micro"
  key_name = var.key_pair_name
  subnet_id = aws_subnet.pvt_sub01.id
  vpc_security_group_ids = [ aws_security_group.app_sg.id ]
  tags = {
    Name = "app-server01"
  }
}
resource "aws_instance" "app_server02" {
  ami           = "ami-04a37924ffe27da53"
  instance_type = "t2.micro"
  key_name = var.key_pair_name
  subnet_id = aws_subnet.pvt_sub02.id
  vpc_security_group_ids = [ aws_security_group.app_sg.id ]
  tags = {
    Name = "app-server02"
  }
}

output "jump-server-public_ip" { 
    value = aws_instance.jump-server.public_ip
}
output "app_server01-private-ip" {
    value = aws_instance.app_server01.private_ip
}
output "app_server02-private-ip" {
    value = aws_instance.app_server02.private_ip
}


//creating security group 03 for RDS
resource "aws_security_group" "db_security_group" {
  name        = "db-sg"
  vpc_id      = aws_vpc.custom_vpc.id

  tags = {
    Name = "db-sg"
  }
}
//inbound rules 
resource "aws_vpc_security_group_ingress_rule" "sshallow" {
  security_group_id = aws_security_group.db_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}
//outbound rules 
resource "aws_vpc_security_group_egress_rule" "allowipv4" {
  security_group_id = aws_security_group.db_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
//outbond rules for ipv6
resource "aws_vpc_security_group_egress_rule" "allowipv6" {
  security_group_id = aws_security_group.db_security_group.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
//creating db subnet group 
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnetgroup"
  subnet_ids = [aws_subnet.db_sub01.id, aws_subnet.db_sub02.id]

  tags = {
    Name = "db-subnetgroup"
  }
}
//creating RDS service 
resource "aws_db_instance" "mysql-db" {
  identifier           = "mydb-project"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type = "gp3" 
  db_name              = "mydb"
  username             = "admin"
  password             = "adminadmin"
  publicly_accessible = false
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  skip_final_snapshot  = true
}

//creating a terget group
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.custom_vpc.id
  stickiness {
    enabled = true
    cookie_duration = 604800
    type = "lb_cookie"
  }
  target_health_state {
    enable_unhealthy_connection_termination = false
  }
}
resource "aws_lb_target_group_attachment" "tg-ath01" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_server01.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "tg-ath02" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_server02.id
  port             = 80
}

//creating load balancer 
resource "aws_lb" "application_lb" {
  name               = "project-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_sg.id]
  subnets            = [aws_subnet.pub_sub01.id, aws_subnet.pub_sub02.id] 
  enable_deletion_protection = false

  tags = {
    Environment = "project-alb"
  }
}
//creating load balancer listener 
resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.application_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

output "db-endpoint" {
  value = aws_db_instance.mysql-db.endpoint
}
output "dns_name" {
  value = aws_lb.application_lb.dns_name
}