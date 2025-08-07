terraform {
  required_version = ">= 1.0.0"
  
  backend "s3" {
    bucket         = "eks-microservices-platform-tfstate"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.default_tags
  }
}

module "vpc" {
  source = "./modules/vpc"
  
  environment     = var.environment
  vpc_cidr       = var.vpc_cidr
  cluster_name   = var.cluster_name
  azs            = var.availability_zones
}

module "eks" {
  source = "./modules/eks"
  
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  node_groups     = var.node_groups
  depends_on      = [module.vpc]
}

module "monitoring" {
  source = "./modules/monitoring"
  
  cluster_name     = var.cluster_name
  eks_cluster_id   = module.eks.cluster_id
  depends_on       = [module.eks]
}

module "app_mesh" {
  source = "./modules/app_mesh"
  
  mesh_name        = "${var.cluster_name}-mesh"
  cluster_name     = var.cluster_name
  eks_cluster_id   = module.eks.cluster_id
  depends_on       = [module.eks]
}
