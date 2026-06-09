# provider

provider "aws" {
  region = ap-south-1
}

# Creating VPC

resource "aws_vpc" "somu-project" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "somu-project"
  }

# Creating subnet

resource "aws_subnet" "somu-project-subnet" {
  count            = 2
  vpc_id            = aws_vpc.somu-project.id
  cidr_block        = cidrsubnet(aws_vpc.somu-project.cidr_block, 8, count.index)
  availability_zone = element(["ap-south-1a", "ap-south-1b"], count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "somu-project-subnet-${count.index + 1}"
  }

# Creating Internet Gateway
resource "aws_internet_gateway" "somu-project-igw" {
  vpc_id = aws_vpc.somu-project.id
  tags = {
    Name = "somu-project-igw"
  }
}

# creating route table
resource "aws_route_table" "somu-project-rt" {
  vpc_id = aws_vpc.somu-project.id
  tags = {
    Name = "somu-project-rt"

    route = {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.somu-project-igw.id
  }

  tags = {
    Name = "somu-project-rt"
  }
}

# Associating route table with subnet
resource "aws_route_table_association"somu-project-rt-association" {
  count          = 2
  subnet_id      = aws_subnet.somu-project-subnet[count.index].id
  route_table_id = aws_route_table.somu-project-rt.id
}

# Security group
resource "aws_security_group" "somu-cluster-sg" {
  name        = "somu-cluster-sg"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = aws_vpc.somu-project.id
}
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
      Name = "somu-cluster-sg"
    }
}
resource "aws_security_group" "somu-node-sg" {
  name        = "somu-node-sg"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = aws_vpc.somu-project.id
}
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

    tags = {
      Name = "somu-node-sg"
    }
  }
  }

# creating eks cluster
resource "aws_eks_cluster" "somu-cluster" {
  name     = "somu-cluster"
  role_arn = aws_iam_role.somu-eks-role.arn

  vpc_config {
    subnet_ids = aws_subnet.somu-project-subnet[*].id
    security_group_ids = [aws_security_group.somu-cluster-sg.id]
  }

  tags = {
    Name = "somu-cluster"
  }
}

# Creting node group
resource "aws_eks_node_group" "somu-node-group" {
  cluster_name    = aws_eks_cluster.somu-cluster.name
  node_group_name = "somu-node-group"
  node_role_arn   = aws_iam_role.somu-node-role.arn
  subnet_ids      = aws_subnet.somu-project-subnet[*].id
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
   
   instance_types = ["t3.medium"]
   remote_access {
    ec2_ssh_key = "var.ssh_key_name"    
    source_security_group_ids = [aws_security_group.somu-node-sg.id]
  }

  tags = {
    Name = "somu-node-group"
  }
}

# IAM role for EKS cluster
resource "aws_iam_role" "somu-eks-role" {
  name = "somu-eks-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "somu-eks-role-attachment" {
  role       = aws_iam_role.somu-eks-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM role for EKS node group
resource "aws_iam_role" "somu-node-role" {
  name = "somu-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "somu-node-role-attachment" {
  role       = aws_iam_role.somu-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "somu-node-cni-role-attachment" {
  role       = aws_iam_role.somu-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "somu-node-ec2-role-attachment" {
  role       = aws_iam_role.somu-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

