variable "location" {
    type = "string"
    default = "westus2"

}
variable "prefix" {
    type = "string"
    default = "0511"
}
variable "tags" {
    type = "map"

    default = {
        Environment = "Terraform QA"
        Dept = "QA Testing"
  }
}
