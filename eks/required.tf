terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0"
    }

    http = {
      source  = "hashicorp/http"
      version = ">= 2.1.0"
    }

  }

  required_version = "> 0.14"
}

