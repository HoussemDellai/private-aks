# It is okay to keep this backend tf state file in local machine
# or even to lose it.
terraform {
  backend "local" {
    # path = "relative/path/to/terraform.tfstate"
  }
}