juju_controller_name  = "microcloud-controller"
lxd_project_name_juju = "juju"

controller_nic_name    = "enp5s0"
controller_gateway     = "192.168.151.1"
controller_nameservers = ["8.8.8.8", "8.8.4.4"]

node2_zone        = "vm02"
node2_ip_cidr     = "192.168.151.202/24"
node2_constraints = "cores=2 mem=4G root-disk=20G root-disk-source=remote virt-type=virtual-machine zones=vm02"

node3_zone        = "vm03"
node3_ip_cidr     = "192.168.151.203/24"
node3_constraints = "cores=2 mem=4G root-disk=20G root-disk-source=remote virt-type=virtual-machine zones=vm03"
