variable "mproject_id" {
  type=string
  description="Project Id"
  default=""
}
variable "mregion" {
  type=string
  description = "Region Name"
  default = ""
}
variable "mzone" {
  type=string
  description = "Zone name"
  default = ""
}
variable "muser" {
  type = string
  description = "Compute engine Login User ID"
  default = ""
}
variable "mpublic_key" {
  type = string
  description = "Public key of the login user"
  default = ""
}
variable "mprivatekeypath" {
  type = string
  description = "Private key path of the user"
  default = ""
}
variable "mpath" {
  type = string
  description = "Startup script path"
  default = ""
}
variable "mrouter_name" {
  type = string
  description = "Router Name"
  default = ""
}

