# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/main.tf ---

# ---------- LAB 1: BUILD A GLOBAL, SEGMENTED NETWORK WITH CENTRAL EGRESS ----------

# GLOBAL NETWORK
resource "aws_networkmanager_global_network" "global_network" {
  provider = aws.awsoregon

  description = "Cloud WAN Basics Workshop - Global Network."

  tags = {
    Name = "Global Network"
  }
}

# CORE NETWORK
resource "awscc_networkmanager_core_network" "core_network" {
  provider = awscc.awsccoregon

  description       = "Cloud WAN Basics Workshop - Core Network."
  global_network_id = aws_networkmanager_global_network.global_network.id
  policy_document   = jsonencode(jsondecode(data.aws_networkmanager_core_network_policy_document.core_nw_policy.json))

  tags = [{
    key   = "Name"
    value = "Core Network"
  }]
}

# RESOURCES IN OREGON (us-west-2)
# Spoke VPCs - definition in variables.tf
module "oregon_spoke_vpcs" {
  for_each  = var.oregon_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "= 3.1.0"
  providers = {
    aws     = aws.awsoregon
    awscc   = awscc.awsccoregon
  }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  # core_network = {
  #   id  = awscc_networkmanager_core_network.core_network.core_network_id
  #   arn = awscc_networkmanager_core_network.core_network.core_network_arn
  # }
  # core_network_routes = {
  #   workload = "0.0.0.0/0"
  # }

  subnets = {
    vpc_endpoints = { cidrs = slice(each.value.endpoint_subnet_cidrs, 0, each.value.number_azs) }
    workload      = { cidrs = slice(each.value.workload_subnet_cidrs, 0, each.value.number_azs) }
    # core_network = {
    #   cidrs              = slice(each.value.cnetwork_subnet_cidrs, 0, each.value.number_azs)
    #   ipv6_support       = false
    #   require_acceptance = false

    #   tags = {
    #     "${each.value.type}" = true
    #   }
    # }
  }
}

# EC2 Instances (1 instance per subnet in each Spoke VPC)
module "oregon_compute" {
  for_each = module.oregon_spoke_vpcs
  source   = "./modules/compute"
  providers = {
    aws = aws.awsoregon
  }

  project_name             = var.project_identifier
  vpc_name                 = each.key
  vpc_id                   = each.value.vpc_attributes.id
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "workload" })
  number_azs               = var.oregon_vpcs[each.key].number_azs
  instance_type            = var.oregon_vpcs[each.key].instance_type
  ec2_iam_instance_profile = module.iam.ec2_iam_instance_profile
  ec2_security_group       = local.oregon.security_groups.instance
}

# VPC endpoints (SSM access)
module "oregon_vpc_endpoints" {
  for_each = module.oregon_spoke_vpcs
  source   = "./modules/vpc_endpoints"
  providers = {
    aws = aws.awsoregon
  }

  project_name             = var.project_identifier
  vpc_name                 = each.key
  vpc_id                   = each.value.vpc_attributes.id
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "vpc_endpoints" })
  endpoints_security_group = local.oregon.security_groups.endpoints
  endpoints_service_names  = local.oregon.endpoint_service_names
}

# RESOURCES IN SEOUL REGION (ap-northeast-2)
# Spoke VPCs - definition in variables.tf
module "seoul_spoke_vpcs" {
  for_each = var.seoul_vpcs
  source   = "aws-ia/vpc/aws"
  version  = "= 3.1.0"
  providers = {
    aws   = aws.awsseoul
    awscc = awscc.awsccseoul
  }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  # core_network = {
  #   id  = awscc_networkmanager_core_network.core_network.core_network_id
  #   arn = awscc_networkmanager_core_network.core_network.core_network_arn
  # }
  # core_network_routes = {
  #   workload = "0.0.0.0/0"
  # }

  subnets = {
    vpc_endpoints = { cidrs = slice(each.value.endpoint_subnet_cidrs, 0, each.value.number_azs) }
    workload      = { cidrs = slice(each.value.workload_subnet_cidrs, 0, each.value.number_azs) }
    # core_network = {
    #   cidrs              = slice(each.value.cnetwork_subnet_cidrs, 0, each.value.number_azs)
    #   ipv6_support       = false
    #   require_acceptance = false

    #   tags = {
    #     "${each.value.type}" = true
    #   }
    # }
  }
}

# EC2 Instances (1 instance per subnet in each Spoke VPC)
module "seoul_compute" {
  for_each = module.seoul_spoke_vpcs
  source   = "./modules/compute"
  providers = {
    aws = aws.awsseoul
  }

  project_name             = var.project_identifier
  #vpc_name                 = each.key
  vpc_name                 = var.seoul_vpcs[each.key].name
  vpc_id                   = each.value.vpc_attributes.id
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "workload" })
  number_azs               = var.seoul_vpcs[each.key].number_azs
  instance_type            = var.seoul_vpcs[each.key].instance_type
  ec2_iam_instance_profile = module.iam.ec2_iam_instance_profile
  ec2_security_group       = local.seoul.security_groups.instance
}

# VPC endpoints (SSM access)
module "seoul_vpc_endpoints" {
  for_each = module.seoul_spoke_vpcs
  source   = "./modules/vpc_endpoints"
  providers = {
    aws = aws.awsseoul
  }

  project_name             = var.project_identifier
  vpc_name                 = each.key
  vpc_id                   = each.value.vpc_attributes.id
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "vpc_endpoints" })
  endpoints_security_group = local.seoul.security_groups.endpoints
  endpoints_service_names  = local.seoul.endpoint_service_names
}

# GLOBAL RESOURCES (IAM)
# IAM module creates the IAM roles needed to publish VPC Flow Logs into CloudWatch Logs, and for EC2 instances to connect to Systems Manager (regardless the AWS Region)
module "iam" {
  source = "./modules/iam"
  providers = {
    aws = aws.awsoregon
  }

  project_name = var.project_identifier
}

# # Transit Gateway RT Association
# resource "aws_ec2_transit_gateway_route_table_association" "oregon_tgw_rt_association" {
#   provider = aws.awsoregon

#   transit_gateway_attachment_id  = module.oregon_legacy_vpc.transit_gateway_attachment_id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.oregon_tgw_rt.id
# }

# # Transit Gateway RT Propagation
# resource "aws_ec2_transit_gateway_route_table_propagation" "oregon_tgw_rt_propagation" {
#   provider = aws.awsoregon

#   transit_gateway_attachment_id  = module.oregon_legacy_vpc.transit_gateway_attachment_id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.oregon_tgw_rt.id
# }

# # EC2 Instances (1 instance per subnet in each Spoke VPC)
# module "oregon_legacy_compute" {
#   source = "./modules/compute"
#   providers = {
#     aws = aws.awsoregon
#   }

#   project_name             = var.project_identifier
#   vpc_name                 = "oregon_legacy_vpc"
#   vpc_id                   = module.oregon_legacy_vpc.vpc_attributes.id
#   vpc_subnets              = values({ for k, v in module.oregon_legacy_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "workload" })
#   number_azs               = var.oregon_legacy_vpc.number_azs
#   instance_type            = var.oregon_legacy_vpc.instance_type
#   ec2_iam_instance_profile = module.iam.ec2_iam_instance_profile
#   ec2_security_group       = local.oregon.security_groups.instance
# }

# # VPC endpoints (SSM access)
# module "oregon_legacy_endpoints" {
#   source = "./modules/vpc_endpoints"
#   providers = {
#     aws = aws.awsoregon
#   }

#   project_name             = var.project_identifier
#   vpc_name                 = "oregon_legacy_vpc"
#   vpc_id                   = module.oregon_legacy_vpc.vpc_attributes.id
#   vpc_subnets              = values({ for k, v in module.oregon_legacy_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "vpc_endpoints" })
#   endpoints_security_group = local.oregon.security_groups.endpoints
#   endpoints_service_names  = local.oregon.endpoint_service_names
# }

# # Cloud WAN - Transit Gateway peering
# resource "aws_networkmanager_transit_gateway_peering" "cwan_oregon_peering" {
#   provider = aws.awsoregon

#   core_network_id     = awscc_networkmanager_core_network.core_network.core_network_id
#   transit_gateway_arn = aws_ec2_transit_gateway.oregon_tgw.arn
# }

# # Transit Gateway policy table (and association)
# resource "aws_ec2_transit_gateway_policy_table" "oregon_tgw_policy_table" {
#   provider = aws.awsoregon

#   transit_gateway_id = aws_ec2_transit_gateway.oregon_tgw.id

#   tags = {
#     Name = "tgw-policy-table-us-west-2"
#   }
# }

# resource "aws_ec2_transit_gateway_policy_table_association" "oregon_tgw_policy_table_association" {
#   provider = aws.awsoregon

#   transit_gateway_attachment_id   = aws_networkmanager_transit_gateway_peering.cwan_oregon_peering.transit_gateway_peering_attachment_id
#   transit_gateway_policy_table_id = aws_ec2_transit_gateway_policy_table.oregon_tgw_policy_table.id
# }

# # Transit Gateway Route Table attachment
# resource "aws_networkmanager_transit_gateway_route_table_attachment" "oregon_cwan_tgw_rt_attachment" {
#   provider = aws.awsoregon

#   peering_id                      = aws_networkmanager_transit_gateway_peering.cwan_oregon_peering.id
#   transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.oregon_tgw_rt.arn

#   tags = {
#     Name   = "us-west-2-tgw-rt-attachment"
#     legacy = true
#   }

#   depends_on = [
#     aws_ec2_transit_gateway_policy_table_association.oregon_tgw_policy_table_association
#   ]
# }

# RESOURCES IN SEOUL (ap-northeast-2)
# Legacy VPC
module "seoul_legacy_vpc" {
  source  = "aws-ia/vpc/aws"
  version = "= 3.1.0"
  providers = {
    aws   = aws.awsseoul
    awscc = awscc.awsccseoul
  }

  name       = var.seoul_legacy_vpc.name
  cidr_block = var.seoul_legacy_vpc.cidr_block
  az_count   = var.seoul_legacy_vpc.number_azs

  transit_gateway_id = aws_ec2_transit_gateway.seoul_tgw.id
  transit_gateway_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    vpc_endpoints = { cidrs = slice(var.seoul_legacy_vpc.endpoint_subnet_cidrs, 0, var.seoul_legacy_vpc.number_azs) }
    workload      = { cidrs = slice(var.seoul_legacy_vpc.workload_subnet_cidrs, 0, var.seoul_legacy_vpc.number_azs) }
    transit_gateway = {
      cidrs                                           = slice(var.seoul_legacy_vpc.tgw_subnet_cidrs, 0, var.seoul_legacy_vpc.number_azs)
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
    }
  }
}

# Transit Gateway
resource "aws_ec2_transit_gateway" "seoul_tgw" {
  provider = aws.awsseoul

  description                     = "Transit Gateway - Seoul."
  amazon_side_asn                 = var.transit_gateway_asn.seoul
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = "tgw-ap-northest-2"
  }
}

# Transit Gateway Route Table
resource "aws_ec2_transit_gateway_route_table" "seoul_tgw_rt" {
  provider = aws.awsseoul

  transit_gateway_id = aws_ec2_transit_gateway.seoul_tgw.id

  tags = {
    Name = "tgw-rt-ap-northeast-2"
  }
}

# Transit Gateway policy table (and association)
resource "aws_ec2_transit_gateway_policy_table" "seoul_tgw_policy_table" {
  provider = aws.awsseoul

  transit_gateway_id = aws_ec2_transit_gateway.seoul_tgw.id

  tags = {
    Name = "tgw-policy-table-ap-northeast-2"
  }
}

resource "aws_ec2_transit_gateway_policy_table_association" "seoul_tgw_policy_table_association" {
  provider = aws.awsseoul

  transit_gateway_attachment_id   = aws_networkmanager_transit_gateway_peering.cwan_seoul_peering.transit_gateway_peering_attachment_id
  transit_gateway_policy_table_id = aws_ec2_transit_gateway_policy_table.seoul_tgw_policy_table.id
}


# Transit Gateway RT Association (TGW <-> Legacy VPC)
resource "aws_ec2_transit_gateway_route_table_association" "seoul_tgw_rt_association" {
  provider                       = aws.awsseoul

  transit_gateway_attachment_id  = module.seoul_legacy_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.seoul_tgw_rt.id
}

# Transit Gateway RT Propagation
resource "aws_ec2_transit_gateway_route_table_propagation" "seoul_tgw_rt_propagation" {
  provider = aws.awsseoul

  transit_gateway_attachment_id  = module.seoul_legacy_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.seoul_tgw_rt.id
}

# EC2 Instances (1 instance per subnet in each Spoke VPC)
module "seoul_legacy_compute" {
  source = "./modules/compute"
  providers = {
    aws = aws.awsseoul
  }

  project_name             = var.project_identifier
  vpc_name                 = "seoul_legacy_vpc"
  vpc_id                   = module.seoul_legacy_vpc.vpc_attributes.id
  vpc_subnets              = values({ for k, v in module.seoul_legacy_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "workload" })
  number_azs               = var.seoul_legacy_vpc.number_azs
  instance_type            = var.seoul_legacy_vpc.instance_type
  ec2_iam_instance_profile = module.iam.ec2_iam_instance_profile
  ec2_security_group       = local.seoul.security_groups.instance
}

# VPC endpoints (SSM access)
module "seoul_legacy_endpoints" {
  source = "./modules/vpc_endpoints"
  providers = {
    aws = aws.awsseoul
  }

  project_name             = var.project_identifier
  vpc_name                 = "seoul_legacy_vpc"
  vpc_id                   = module.seoul_legacy_vpc.vpc_attributes.id
  vpc_subnets              = values({ for k, v in module.seoul_legacy_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "vpc_endpoints" })
  endpoints_security_group = local.seoul.security_groups.endpoints
  endpoints_service_names  = local.seoul.endpoint_service_names
}

# Cloud WAN - Transit Gateway peering
resource "aws_networkmanager_transit_gateway_peering" "cwan_seoul_peering" {
  provider = aws.awsseoul

  core_network_id     = awscc_networkmanager_core_network.core_network.core_network_id
  transit_gateway_arn = aws_ec2_transit_gateway.seoul_tgw.arn
}
