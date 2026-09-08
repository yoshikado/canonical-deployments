lxd_remote_name = "microcloud"
lxd_remote_url  = "https://192.168.10.75:8443"

lxd_project_name_juju      = "juju"
lxd_juju_operator_username = "juju-operator"

juju_cloud_name       = "microcloud"
juju_controller_name  = "microcloud-controller"
bootstrap_constraints = "cores=2 mem=4G root-disk=20G root-disk-source=remote virt-type=virtual-machine"
bootstrap_target      = "vm01"

controller_nic_name    = "enp5s0"
controller_ip_cidr     = "192.168.151.201/24"
controller_gateway     = "192.168.151.1"
controller_nameservers = ["8.8.8.8"]
