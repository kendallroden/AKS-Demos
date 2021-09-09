terraform {
	required_providers {
		azurerm = {
			source = "hashicorp/azurerm"
			version = "~> 2.70.0"
		}
	}
}

provider azurerm {
	alias = "hub"
	subscription_id = var.hubSubscriptionId
	features {}
}

provider azurerm {
	alias = "spoke"
	subscription_id = var.spokeSubscriptionId
	features {}
}

variable "prefix" {
  type = string
  default = "rk"
}
variable "hubSubscriptionId" {
  type = string
}

variable "spokeSubscriptionId" {
  type = string
}

variable "hub_address_space" {
  type = string
  default = "10.0.0.0/16"
}

variable "spoke_address_space" {
  type = string
  default = "192.168.0.0/16"
}

locals {
  prefix = "${var.prefix}csitest"
  location = "eastus"
}
