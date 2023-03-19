# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/kms/variables.tf ---

variable "project_name" {
  type        = string
  description = "Project identifier."
  default     = "oregon-legacy"
}

variable "aws_region" {
  type        = string
  description = "AWS Region indicated in the variables - where the resources are created."
  default     = "us-west-2"
}
