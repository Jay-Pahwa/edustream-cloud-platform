output "vpc_id" {
  description = "The ID of the main VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of Public Subnet IDs"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "web_subnet_ids" {
  description = "List of Web Subnet IDs"
  value       = [aws_subnet.web_a.id, aws_subnet.web_b.id]
}

output "data_subnet_ids" {
  description = "List of Data Subnet IDs"
  value       = [aws_subnet.data_a.id, aws_subnet.data_b.id]
}