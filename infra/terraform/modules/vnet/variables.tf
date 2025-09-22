variable "name"    { type = string }
variable "regions" { type = list(string) }
variable "rg_names" { type = map(string) }
variable "tags"    { 
    type = map(string) 
    default = {} 
}