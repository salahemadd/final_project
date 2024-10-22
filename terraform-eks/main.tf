terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.0"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name               = local.name
  cidr               = local.vpc_cidr
  azs                = local.azs
  public_subnets     = local.public_subnets
  private_subnets    = local.private_subnets
  intra_subnets      = local.intra_subnets
  enable_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"

  cluster_name                   = local.name
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  eks_managed_node_group_defaults = {
    ami_type                              = "AL2_x86_64"
    instance_types                        = ["t2.small"]
    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    salahs-cluster-wg = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = ["t2.small"]
      capacity_type  = "SPOT"
      tags           = { ExtraTag = "helloworld" }
    }
  }

  tags = local.tags
}
