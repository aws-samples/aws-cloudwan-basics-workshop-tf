# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/variables.tf ---

# Project identifier
variable "project_identifier" {
  type        = string
  description = "Project Identifier."

  default = "CloudWAN_Basics_Workshop"
}

# AWS Regions to use in this example
variable "aws_regions" {
  type        = map(string)
  description = "AWS regions to spin up resources."

  default = {
    seoul     = "ap-northeast-2"
    oregon    = "us-west-2"
  }
}

# Transit Gateway ASNs
variable "transit_gateway_asn" {
  type        = map(number)
  description = "Transit Gateway ASNs."

  default = {
    seoul    = 64515
    #oregon   = 64516
  }
}

# Definition of the VPCs to create in Oregon Region
variable "seoul_vpcs" {
  type        = any
  description = "Information about the VPCs to create in ap-northeast-2."

  default = {
    "dev" = {
      type                  = "dev"
      name                  = "seoul-DEV"
      number_azs            = 1
      cidr_block            = "10.82.0.0/24"
      workload_subnet_cidrs = ["10.82.0.0/27" , "10.82.0.32/27"]
      endpoint_subnet_cidrs = ["10.82.0.64/27", "10.82.0.96/27"]
      instance_type         = "t3.micro"
    }
    "prod" = {
      type                  = "prod"
      name                  = "seoul-PROD"
      number_azs            = 1
      cidr_block            = "10.82.1.0/24"
      workload_subnet_cidrs = ["10.82.1.0/27" , "10.82.1.32/27"]
      endpoint_subnet_cidrs = ["10.82.1.64/27", "10.82.1.96/27"]
      instance_type         = "t3.micro"
    }
  }
}

# Definition of the VPCs to create in Oregon Region
variable "oregon_vpcs" {
  type        = any
  description = "Information about the VPCs to create in us-west-2."

  default = {
    "dev" = {
      type                  = "dev"
      name                  = "oregon-DEV"
      number_azs            = 1
      cidr_block            = "10.1.0.0/24"
      workload_subnet_cidrs = ["10.1.0.0/27" , "10.1.0.32/27"]
      endpoint_subnet_cidrs = ["10.1.0.64/27", "10.1.0.96/27"]
      instance_type         = "t3.micro"
    }
    "prod" = {
      type                  = "prod"
      name                  = "oregon-PROD"
      number_azs            = 1
      cidr_block            = "10.1.1.0/24"
      workload_subnet_cidrs = ["10.1.1.0/27" , "10.1.1.32/27"]
      endpoint_subnet_cidrs = ["10.1.1.64/27", "10.1.1.96/27"]
      instance_type         = "t3.micro"
    }
  }
}


variable "seoul_legacy_vpc" {
  type        = any
  description = "Information about the Legacy VPC to create in ap-northeast-2."

  default = {
    name                  = "seoul-LEGACY"
    cidr_block            = "10.99.0.0/24"
    workload_subnet_cidrs = ["10.99.0.0/27"   , "10.99.0.32/27" ]
    endpoint_subnet_cidrs = ["10.99.0.64/27"  , "10.99.0.96/27" ] 
    tgw_subnet_cidrs      = ["10.99.0.128/27" , "10.99.0.160/27"]
    number_azs            = 1
    instance_type         = "t3.micro"
  }
}
