terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.52.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  profile = "default"
  region     = "us-east-1"
  access_key = "na"
  secret_key = "na"
  #token = "FwoGZXIvYXdzEBgaDDpUrShI5Y8L1mxH6SKzAa3E5WHlH/LsdNQGPfrU+W32vvokriN62jPwrz49lvKVxWcrOuJREVbzUZDjWPTO3tI6wrdu2kjr+eP8mXb0OQLpM8NoGaAHXDq7zVfM6VDRFmiCH5nOViMRWv+GPStxntE2BaZJpTU2JDDHL/Mc+VqS8GIKv7Us7NQsdEvO1Ow+4+6lOR9tEFEjgVI4GFEb97qqlzqz31jRAahjcfDrIMLroOP/uLqdWJwrrMeLIMllB1s6KIjl254GMi0VfTJKAWX64Gl6HcivD0J+moKLj/EnbH0blONzLxVgu2LUkWwPq3br8uCDOSg="
}

# Create a VPC
#resource "aws_vpc" "example" {
#  cidr_block = "10.0.0.0/16"
#}