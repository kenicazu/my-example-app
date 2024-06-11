module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = var.network.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.network.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.network.vpc_cidr, 8, k + 48)]

  enable_nat_gateway   = var.network.enable_nat_gateway
  single_nat_gateway   = var.network.single_nat_gateway
  enable_dns_hostnames = var.network.enable_dns_hostnames

  # Manage so we can name
  manage_default_network_acl    = var.network.manage_default_network_acl
  default_network_acl_tags      = { Name = "${var.general.name}-default" }
  manage_default_route_table    = var.network.manage_default_route_table
  default_route_table_tags      = { Name = "${var.general.name}-default" }
  manage_default_security_group = var.network.manage_default_security_group
  default_security_group_tags   = { Name = "${var.general.name}-default" }

  tags = var.tags
}