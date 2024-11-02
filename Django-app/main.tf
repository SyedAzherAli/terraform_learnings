provider "aws" {
    region = "ap-south-1"
}

//creating vpc 
resource "aws_vpc" "project_vpc"{
    cidr_block = "192.168.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
      "Name" = "Project_vpc"
    }
}
//creating subnet01
resource "aws_subnet" "public_subnet01" {
    vpc_id = aws_vpc.project_vpc.id
    cidr_block = "192.168.0.0/20"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    tags = {
      "name" = "pub_sub01"
    }
}
//creatin subnet02
resource "aws_subnet" "public_subnet02" { 
    vpc_id = aws_vpc.project_vpc.id
    cidr_block = "192.168.16.0/20"
    availability_zone = "ap-south-1b"
    tags = {
      "name" = "pub_sub02"
    }
}
//creating subnet03
resource "aws_subnet" "private_subnet03" {
  vpc_id = aws_vpc.project_vpc.id
  cidr_block = "192.168.32.0/20"
  availability_zone = "ap-south-1a"
  tags = {
    "name" = "pvt_sub01"
  }
}
//creating subnet04
resource "aws_subnet" "private_subnet04" {
  vpc_id = aws_vpc.project_vpc.id
  cidr_block = "192.168.48.0/20"
  availability_zone = "ap-south-1b"
  tags = {
    "name" = "pvt_sub02"
  }
}

//-------------public subnet configuration-------------
//creating internet gateway 
resource "aws_internet_gateway" "project_IGW" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = "project_IGW"
  }

}
//creating route table 01
resource "aws_route_table" "PUB_RT" {
    vpc_id = aws_vpc.project_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.project_IGW.id
    }

    tags = {
        Name = "pub_RT"
    }
}
//creating subnet association for public subnets 
resource "aws_route_table_association" "subnet_association01" {
  subnet_id      = aws_subnet.public_subnet01.id
  route_table_id = aws_route_table.PUB_RT.id
}
resource "aws_route_table_association" "subnet_association02" {
  subnet_id      = aws_subnet.public_subnet02.id
  route_table_id = aws_route_table.PUB_RT.id
}

//---------private subnet configuration------------
//Create a NAT Gateway for the private subnet (requires an Elastic IP)
resource "aws_eip" "nat_eip" {
 
}
resource "aws_nat_gateway" "project_NAT" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet01.id //creating nat in public subnet bcoz public ip can't allowcate in private subnet

  tags = {
    Name = "project-nat"
  }
} 
//creating route table for private subnets 
resource "aws_route_table" "PVT_RT" {
  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.project_NAT.id
  }
  
}
//creating subnet association for private subnets 
resource "aws_route_table_association" "subnet_association03" {
  subnet_id      = aws_subnet.private_subnet03.id
  route_table_id = aws_route_table.PVT_RT.id
}
resource "aws_route_table_association" "subnet_association04" {
  subnet_id      = aws_subnet.private_subnet04.id
  route_table_id = aws_route_table.PVT_RT.id
}

//---------------creating iam role for ec2 instance--------------
// Create an IAM Role for EC2 with a Trust Policy
resource "aws_iam_role" "ec2_codedeploy_role" {
  name = "project_EC2_CodeDeploy_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
// Attach the AmazonEC2RoleforAWSCodeDeploy Policy
resource "aws_iam_policy_attachment" "ec2_codedeploy_policy" {
  name       = "ec2_codedeploy_policy_attachment"
  roles      = [aws_iam_role.ec2_codedeploy_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

// Attach the AmazonS3FullAccess Policy
resource "aws_iam_policy_attachment" "s3_full_access_policy" {
  name       = "s3_full_access_policy_attachment"
  roles      = [aws_iam_role.ec2_codedeploy_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

// Attach the AWSCodeDeployFullAccess Policy
resource "aws_iam_policy_attachment" "codedeploy_full_access_policy" {
  name       = "codedeploy_full_access_policy_attachment"
  roles      = [aws_iam_role.ec2_codedeploy_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}
// create iam instance profile
resource "aws_iam_instance_profile" "ec2_codedeploy_profile" {
  name = "EC2_CodeDeploy_Instance_Profile"
  role = aws_iam_role.ec2_codedeploy_role.name
}
//---------------creating iam role for codedeploy--------------
resource "aws_iam_role" "codedeploy_S3_role" {
  name = "CodeDeploy_S3_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codedeploy.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
// Attach the AWSCodeDeployRole Policy
resource "aws_iam_policy_attachment" "codedeploy_role_policy" {
  name       = "codedeploy_role_policy_attachment"
  roles      = [aws_iam_role.codedeploy_S3_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}
// Attach the AmazonS3FullAccess Policy
resource "aws_iam_policy_attachment" "s3_full_access_codedeploy_policy" {
  name       = "s3_full_access_policy_attachment"
  roles      = [aws_iam_role.codedeploy_S3_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
// Attach the AmazonEC2FullAccess Policy
resource "aws_iam_policy_attachment" "ec2_full_access_policy" {
  name       = "ec2_full_access_policy_attachment"
  roles      = [aws_iam_role.codedeploy_S3_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
//----------Create aws security group, for application allow port 80 and 22---------
resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.project_vpc.id

  tags = {
    Name = "app_sg"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4        = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "allow_jenkins_port" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4       = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" // semantically equivalent to all ports
}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" // semantically equivalent to all ports
}

variable "KeyPairName" {
  description = "name of key pair"
}

//-----------Create the Launch Template----------------
resource "aws_launch_template" "launch_template" {
  name_prefix   = "project-LT"
  description   = "Launch template for web server"
  // EBS storage allocation 
  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20
    }
  }
  // AMI ID for ubuntu 24
  image_id      = "ami-0dee22c13ea7a9a67"  // Replace with a valid AMI ID
  // IAM role for instance
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_codedeploy_profile.name
  }
  // Instance Type
  instance_type = "t2.micro"

  // Optional: Key Pair
  key_name =  var.KeyPairName // Replace with your existing key pair name

  // Optional: Security Group
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  // Optional: User Data Script
  user_data = base64encode(<<-EOF
    #!/bin/bash

    # Function to run the installation steps
    install_dependencies() {
    apt update -y
    apt install -y python3 python3-pip
    apt install -y python3-venv
    apt install -y libpq-dev
    apt install -y nginx
    apt install -y ruby-full
    apt install -y gdebi-core
    wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto
    systemctl enable codedeploy-agent
    systemctl start codedeploy-agent
    }

    # Run the installation function twice
    echo "Running the installation script for the first time..."
    install_dependencies
    sleep 20
    echo "Running the installation script for the second time..."
    install_dependencies
 
EOF
)

  // Tags
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Application-Instance"
    }
  }
}

//--------creating instance for Jenkins server------------
resource "aws_instance" "Jenkins_server" {
  ami           = "ami-0dee22c13ea7a9a67" 
  instance_type = "t2.micro"
  key_name = var.KeyPairName
  subnet_id = aws_subnet.public_subnet01.id
  vpc_security_group_ids = [ aws_security_group.app_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_codedeploy_profile.name
  user_data = <<-EOF
    #!/bin/bash

    # Update the package index to ensure we have the latest list of available packages
    apt update -y

    # Install fontconfig and OpenJDK 17, both are dependencies required for Jenkins
    apt install fontconfig openjdk-17-jre -y

    # Download the Jenkins signing key and save it to the system’s trusted keyring
    wget -O /usr/share/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

    # Add the Jenkins repository to the system’s package sources, referencing the signing key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

    # Update the package index again to include packages from the newly added Jenkins repository
    apt-get update -y

    # Install Jenkins from the Jenkins repository
    apt-get install jenkins -y
  EOF

  tags = {
    Name = "Jenkins_server"
  }
}
output "Jenkins-server-IP" {
  value = aws_instance.Jenkins_server.public_ip
}
variable "BucketName" {
  description = "your bucket unique name"
}
variable "ACCOUNTID" {
  description = "your aws account id"
}
//-------------creating S3 bucket to store application media files and static files--------------
// Create an S3 Bucket
resource "aws_s3_bucket" "project_bucket" {
  bucket = var.BucketName  

  tags = {
    Name        = "MediaAndCodeDeployBucket"
  }
}
resource "aws_s3_bucket_ownership_controls" "project_bucket_ownership_controls" {
  bucket = aws_s3_bucket.project_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_public_access_block" "project_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.project_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  restrict_public_buckets = false
  ignore_public_acls      = false
}
resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.project_bucket_ownership_controls,
    aws_s3_bucket_public_access_block.project_bucket_public_access_block
  ]

  bucket = aws_s3_bucket.project_bucket.id
  acl    = "public-read"
}
// Apply the Bucket Policy
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.project_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "ExamplePolicy01",
    Statement = [
      {
        Sid       = "ExampleStatement01",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${var.ACCOUNTID}:root"  
        },
        Action = [
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.project_bucket.arn}",
          "${aws_s3_bucket.project_bucket.arn}/*"
        ]
      }
    ]
  })
}

// Create security group for DB 
resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.project_vpc.id

  tags = {
    Name = "db_sg"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}
resource "aws_vpc_security_group_egress_rule" "allow_all_ipv4" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" // semantically equivalent to all ports
}
resource "aws_vpc_security_group_egress_rule" "allow_all_ipv6" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" // semantically equivalent to all ports
}
variable "DB_PWD" {
  description = "postgres db password"
}
# Create a DB Subnet Group for RDS
resource "aws_db_subnet_group" "subnet_group_RDS" {
  name       = "rds-subnet-group"
  subnet_ids = [
    aws_subnet.public_subnet01.id,
    aws_subnet.public_subnet02.id
  ]
}
//------------Create RDS for application---------------------
resource "aws_db_instance" "postgres-db" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "16.3"            // Set the desired PostgreSQL version
  instance_class       = "db.t3.micro"        // Choose an instance type
  db_name              = "Django_backend"     // Initial database name
  username             = "Django_usr"         // Master username
  password             = var.DB_PWD         // Master password
  //parameter_group_name   = "default.postgres13"
  db_subnet_group_name = aws_db_subnet_group.subnet_group_RDS.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible  = true                 // Enable public access
  skip_final_snapshot  = true                 // Skip snapshot on deletion for development
  //availability_zone = "ap-south-1a"
  tags = {
    Name = "PublicPostgresRDSInstance"
  }
}
output "DB_NAME" {
  value = aws_db_instance.postgres-db.db_name
}
output "DB_USER" {
  value = aws_db_instance.postgres-db.username
}
output "DB_PASSWORD" {
  value = var.DB_PWD
}
output "DB_HOST" {
  value = aws_db_instance.postgres-db.endpoint
}
//--------Create target group---------------
resource "aws_lb_target_group" "project_tg" {
  name     = "project-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id  = aws_vpc.project_vpc.id
  stickiness {
    enabled = true
    cookie_duration = 604800
    type = "lb_cookie"
  }
  target_health_state {
    enable_unhealthy_connection_termination = false
  }
}

//--------Create auto-scaling group------------ 
resource "aws_autoscaling_group" "project_ASG" {
  vpc_zone_identifier = [aws_subnet.private_subnet03.id, aws_subnet.private_subnet04.id] // Deploying application in private subnets
  desired_capacity   = 2
  max_size           = 4
  min_size           = 2

  // This will automatically register instances with the specified target group
  target_group_arns = [aws_lb_target_group.project_tg.arn]
  
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }
}
//----------Create load balancer------------
resource "aws_lb" "project_lb" {
  name               = "project-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_sg.id]
  subnets            = [aws_subnet.public_subnet01.id, aws_subnet.public_subnet02.id]
}
// Listener for Load Balancer
resource "aws_lb_listener" "project_lb_listener" {
  load_balancer_arn = aws_lb.project_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project_tg.arn
  }
}

//----------Create code deploy----------------
resource "aws_codedeploy_app" "project_codedeploy" {
  compute_platform = "Server"
  name             = "django-app"
}
//--------Creating code deployment group----------
resource "aws_codedeploy_deployment_group" "project_CDG" {
  app_name              = aws_codedeploy_app.project_codedeploy.name
  deployment_group_name = "django-app-DG"
  service_role_arn      = aws_iam_role.codedeploy_S3_role.arn

  deployment_style {
    deployment_type = "IN_PLACE"
  }

  autoscaling_groups = [ aws_autoscaling_group.project_ASG.id ]

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.project_lb_listener.arn]
      }
      target_group {
        name = aws_lb_target_group.project_tg.name
      }
    }

  }
}
output "S3_BUCKET" {
  value = aws_s3_bucket.project_bucket.bucket_domain_name
}
output "APPLICATION_NAME" {
  value = aws_codedeploy_app.project_codedeploy.name
}
output "APPLICATION_GROUP" {
  value = aws_codedeploy_deployment_group.project_CDG.deployment_group_name
}