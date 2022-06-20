
variable "myRegion" {
  default = "us-east-2"
}

variable "myAZs" {
  default = "us-east-2a"
}

variable "myKey" {
  default = "us-east2-key"
}

variable "tags" {
  default = "jenkins-server"
}

variable "myAmi" {
  description = "amazon linux 2 ami"
  default     = "ami-0aeb7c931a5a61206"
}

variable "myInstancetype" {
  default = "m4.large"
}
