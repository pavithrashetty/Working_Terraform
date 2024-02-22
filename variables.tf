variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = "pavi-g-hello-tf"
}
variable "file_location" {
  description = "S3 object location"
  type        = string
  default     = "./build/libs/g-hello-0.0.1-SNAPSHOT.jar"
}
variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "pavi_ec2_g-hello"
}
