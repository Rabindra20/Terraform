
#Dynamic block
locals {
   ingress_rules = [{
      rule        = 100
      port        = 80
      description = "Ingress rules for port 80"
   },
   {
     rule        = 200
      port        = 22
      description = "Ingree rules for port 22"
   },
   {
     rule        = 300
      port        = 443
      description = "Ingree rules for port 433"
   }]
}
#================ VPC ================
# resource "aws_vpc" "vpc" {
#   cidr_block = "10.0.0.0/16"  #You can change the CIDR block as per required
  
#   tags = {
#     Name = "rab"
#   }
# }
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

output "out_vpc_id" {
  value = "${aws_vpc.vpc.id}"
}
output "out_vpc_cidr_block" {
  value = "${aws_vpc.vpc.cidr_block}"
}

#================ IGW ================
# resource "aws_internet_gateway" "igw" {
#   vpc_id = "${aws_vpc.vpc.id}"

#   tags = {
#     Name = "rab"
#   }
# }
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

#================ Public Subnet ================
# resource "aws_subnet" "pub_subnet_1" {
#   vpc_id = "${aws_vpc.vpc.id}"
#   cidr_block = "10.0.1.0/24"  #You can change the CIDR block as per required
#   availability_zone = "${var.aws_region}a"
#   map_public_ip_on_launch = "true"

#   tags = {
#     Name = "pub_subnet_1"
#   }
# }

# output "out_pub_subnet_1_id" {
#   value = "${aws_subnet.pub_subnet_1.id}"
# }

# resource "aws_subnet" "pub_subnet_2" {
#   vpc_id = "${aws_vpc.vpc.id}"
#   cidr_block = "10.0.2.0/24"  #You can change the CIDR block as per required
#   availability_zone = "${var.aws_region}b"
#   map_public_ip_on_launch = "true"

#   tags = {
#     Name = "pub_subnet_2"
#   }
# }
 resource "aws_subnet" "pub_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = "${length(var.public_subnets_cidr)}"
  cidr_block              = "${element(var.public_subnets_cidr, count.index)}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "${var.environment}-pub-subnet-${count.index}"
    Environment = var.environment
  }
}
output "out_pub_subnet_id" {
  value = "${aws_subnet.pub_subnet.id}"
}

#================ Private Subnet ================
# resource "aws_subnet" "pvt_subnet_1" {
#   vpc_id = "${aws_vpc.vpc.id}"
#   cidr_block = "10.0.3.0/24"  #You can change the CIDR block as per required
#   map_public_ip_on_launch = "false"
#   availability_zone = "${var.aws_region}b"

#   tags = {
#     Name = "pvt_subnet_1"
#   }
# }

# output "out_pvt_subnet_1_id" {
#   value = "${aws_subnet.pvt_subnet_1.id}"
# }

# resource "aws_subnet" "pvt_subnet_2" {
#   vpc_id = "${aws_vpc.vpc.id}"
#   map_public_ip_on_launch = "false"
#   availability_zone = "${var.aws_region}a"
#   cidr_block = "10.0.4.0/24"  #You can change the CIDR block as per required

#   tags = {
#     Name = "pvt_subnet_2"
#   }
# }
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = "${length(var.private_subnets_cidr)}"
  cidr_block              = "${element(var.private_subnets_cidr, count.index)}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  #map_public_ip_on_launch = false
  tags = {
    Name        = "${var.environment}-private-subnet-${count.index}"
    Environment = var.environment
  }
}

output "out_pvt_subnet_id" {
  value = "${aws_subnet.pvt_subnet.id}"
}

#================ RDS Subnet ================
# resource "aws_db_subnet_group" "rds_subnet" {
#   name = "rds_subnet"
#   subnet_ids = ["${aws_subnet.pvt_subnet_1.id}", "${aws_subnet.pvt_subnet_2.id}"]

#   tags {
#     Name = "rds_subnet"
#   }
# }

# output "out_rds_subnet_name" {
#   value = "${aws_db_subnet_group.rds_subnet.name}"
# }

#================ Public Route Table ================
# resource "aws_route_table" "pub_rtb" {
#   vpc_id = "${aws_vpc.vpc.id}"

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = "${aws_internet_gateway.igw.id}"
#   }

#   tags = {
#     Name = "pub_rtb"
#   }
# }
resource "aws_route_table" "pub_rtb" {
  vpc_id = aws_vpc.vpc.id
    route {
    cidr_block = var.vpc_cidr
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Name        = "${var.environment}-aws_route_table"
    Environment = var.environment
  }
}


/*
  If you do not want your internal servers to communicate with outer world,
  you can delete this optional section
*/
#================ Optional Start ================
#================ EIP ================
# resource "aws_eip" "nat_ip" {
#   vpc = "true"
# }
resource "aws_eip" "nat_ip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}
#================ NAT Gateway ================
# resource "aws_nat_gateway" "nat_gateway" {
#   allocation_id = "${aws_eip.nat_ip.id}"
#   subnet_id = "${aws_subnet.pub_subnet_1.id}"

#   tags = {
#     Name = "test_vpc_nat"
#   }
# }
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.pub_subnet[0].id
  depends_on    = [aws_internet_gateway.igw]
  
  tags = {
    Name        = "${var.environment}-nat"
    Environment = var.environment
  }
}
#================ Optional End ================

#================ Private Route Table ================
# resource "aws_default_route_table" "pvt_rtb" {
#   default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"

#   route {
#     cidr_block = "0.0.0.0/0"
#     nat_gateway_id = "${aws_nat_gateway.nat_gateway.id}" #Optional
#   }

#   tags = {
#     Name = "pvt_rtb"
#   }
# }
resource "aws_default_route_table" "pvt_rtb" {
    default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"

  route {
    cidr_block = var.vpc_cidr
    nat_gateway_id = "${aws_nat_gateway.nat_gateway.id}" #Optional
  }
  
  tags = {
    Name        = "${var.environment}-private-route-table"
    Environment = var.environment
  }
}
#================ Route Table Association ================
resource "aws_route_table_association" "pub_rtb_assoc_1" {
  subnet_id = "${aws_subnet.pub_subnet.id}"
  route_table_id = "${aws_route_table.pub_rtb.id}"
}

resource "aws_route_table_association" "pub_rtb_assoc_2" {
  subnet_id = "${aws_subnet.pub_subnet.id}"
  route_table_id = "${aws_route_table.pub_rtb.id}"
}

# resource "aws_route_table_association" "pub_rtb_assoc" {
#   count          = "${length(var.pvt_subnets_cidr)}"
#   subnet_id      = "${element(aws_subnet.pvt_subnet.*.id, count.index)}"
#   route_table_id = aws_route_table.pvt.id
# }

#================ NACL ================
resource "aws_network_acl" "pub_nacl" {
  vpc_id = "${aws_vpc.vpc.id}"
  count          = "${length(var.pub_subnets_cidr)}"
  subnet_ids = "${element(aws_subnet.pub_subnet.*.id, count.index)}"

  # #HTTP Port
  # ingress {
  #   rule_no = 100
  #   action = "allow"
  #   from_port = 80
  #   to_port = 80
  #   protocol = "tcp"
  #   cidr_block = "0.0.0.0/0"
  # }
  # #HTTPS Port
  # ingress {
  #   rule_no = 200
  #   action = "allow"
  #   from_port = 443
  #   to_port = 443
  #   protocol = "tcp"
  #   cidr_block = "0.0.0.0/0"
  # }
  # #SSH Port
  # ingress {
  #   rule_no = 300
  #   action = "allow"
  #   from_port = 22
  #   to_port = 22
  #   protocol = "tcp"
  #   cidr_block = "0.0.0.0/0"  #You must restrict this to your own IP address
  # }
      dynamic "ingress" {
      for_each = local.ingress_rules

      content {
         rule_no = ingress.value.rule
         action = "allow"
        #  description = ingress.value.description
         from_port   = ingress.value.port
         to_port     = ingress.value.port
         protocol    = "tcp"
         cidr_block = "0.0.0.0/0"
      }
   } 
  #Ephemeral Ports
  ingress {
    rule_no = 400
    action = "allow"
    from_port = 1024
    to_port = 65535
    protocol = "tcp"
    cidr_block = "0.0.0.0/0"
  }



  #HTTP Port
  egress {
    rule_no = 100
    action = "allow"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_block = "0.0.0.0/0"
  }
  #HTTPS Port
  egress {
    rule_no = 200
    action = "allow"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_block = "0.0.0.0/0"
  }
  #SSH Port
  egress {
    rule_no = 300
    action = "allow"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_block = "0.0.0.0/0"  #You must restrict this to your own IP address
  }
  #Ephemeral Port
  egress {
    rule_no = 400
    action = "allow"
    from_port = 1024
    to_port = 65535
    protocol = "tcp"
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "pub_nacl"
  }
}

# resource "aws_default_network_acl" "pvt_nacl" {
#   default_network_acl_id = "${aws_vpc.vpc.default_network_acl_id}"

#   ingress {
#     rule_no = 100
#     action = "allow"
#     from_port = 0
#     to_port = 0
#     protocol = "-1"
#     cidr_block = "${aws_vpc.vpc.cidr_block}"
#   }

#   egress {
#     rule_no = 100
#     action = "allow"
#     from_port = 0
#     to_port = 0
#     protocol = "-1"
#     cidr_block = "${aws_vpc.vpc.cidr_block}"
#   }

#   tags {
#     Name = "pvt_nacl"
#   }
# }