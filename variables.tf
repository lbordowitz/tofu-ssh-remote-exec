
# you might have to subscribe to Debian 12 to use its AMI in the project:
# https://aws.amazon.com/marketplace/pp/prodview-g5rooj5oqzrw4
variable "ami" {
    default = "ami-0f3febef860d6b7f6"
    type = string
}

variable "region" {
    default = "us-east-2"
    type = string
}

variable "vpc_id" {
    default = "vpc-81d162ea"
    type = string
}