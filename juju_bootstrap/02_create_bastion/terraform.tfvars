lxd_remote_name = "local"
lxd_remote_url = "unix://"

# SSH public key for the bastion container (e.g., from ~/.ssh/id_ed25519.pub):
# ssh_public_key = "ssh-ed25519 AAAA..."

# Optional: customize network configuration (e.g. multiple nameservers, search domains):
# bastion_network_config = <<-EOF
#   version: 2
#   ethernets:
#     eth0:
#       dhcp4: false
#       dhcp6: false
#       addresses: [192.168.151.200/24]
#       routes:
#       - to: default
#         via: 192.168.151.1
#       nameservers:
#         addresses:
#           - 1.1.1.1
#           - 8.8.8.8
#         search:
#           - example.com
# EOF
