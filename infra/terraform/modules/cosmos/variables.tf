variable "name"       { type = string }
variable "locations"  { type = list(string) }
variable "multi_write" { 
    type = bool 
    default = true 
}
variable "tags"       { 
    type = map(string) 
    default = {} 
}