variable "name"                 { type = string }
variable "location"             { type = string }
variable "replication_locations" { 
    type = list(string) 
    default = [] 
}

variable "tags" { 
    type = map(string) 
    default = {} 
}