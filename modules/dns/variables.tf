variable "domain_name" {
  description = "Domain name for the hosted zone (e.g. tst-plt.echotwin.xyz)"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to the hosted zone"
  type        = map(string)
  default     = {}
}

variable "comment" {
  description = "Optional comment for the hosted zone"
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "Allow deleting hosted zone even if it contains records (use with care)"
  type        = bool
  default     = false
}
