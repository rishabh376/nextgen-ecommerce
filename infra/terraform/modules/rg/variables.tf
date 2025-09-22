variable "name"    { type = string }
variable "regions" { type = list(string) }
variable "tags"    { 
type = map(string) 
default = {} 
}