variable "name" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "subnet_ids" {
  type = list(string)
}

variable "ami_id" {
  type = string
}

variable "asg_max_size" {
  type = number
}

variable "spot_allocation_strategy" {
  type    = string
  default = "lowest-price"
}

variable "on_demand_base_capacity" {
  type    = number
  default = 0
}

variable "on_demand_percentage_above_base_capacity" {
  type    = number
  default = 0
}

variable "spot_max_price" {
  type = string
}

variable "spot_instance_pools" {
  type    = number
  default = 0
}

variable "instance_types" {
  type = map(number)
}

variable "target_capacity" {
  type    = number
  default = 80
}

variable "spot_capacity_provider_weight" {
  type    = number
  default = 1
}

variable "maximum_scaling_step_size" {
  type    = number
  default = 1
}

variable "minimum_scaling_step_size" {
  type    = number
  default = 1
}
