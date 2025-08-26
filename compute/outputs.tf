output "control_plane_ip" {
  value = aws_instance.k8s_control_plane.private_ip
}

output "control_plane_public_ip" {
  value = aws_instance.k8s_control_plane.public_ip
}

output "worker_ips" {
  value = aws_instance.k8s_worker_nodes[*].private_ip
}

output "worker_public_ips" {
  value = aws_instance.k8s_worker_nodes[*].public_ip
}