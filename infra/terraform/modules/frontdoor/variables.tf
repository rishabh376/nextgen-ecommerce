variable "name"                 { type = string }
variable "regions"              { type = list(string) }
variable "backends_public_ips"  { type = map(string) }
variable "tags"                 { 
    type = map(string) 
    default = {} 
}