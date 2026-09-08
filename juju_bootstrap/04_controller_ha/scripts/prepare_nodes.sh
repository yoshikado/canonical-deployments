#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Prerequisites check
for cmd in juju lxc jq; do
  if ! command -v "$cmd" &>/dev/null; then
    log "Error: Required command '$cmd' is not installed or not in PATH."
    exit 1
  fi
done

# Configuration variables from environment or defaults
JUJU_CONTROLLER_NAME="${JUJU_CONTROLLER_NAME:-microcloud-controller}"
LXD_PROJECT="${LXD_PROJECT:-juju}"
NIC_NAME="${NIC_NAME:-enp5s0}"
GATEWAY="${GATEWAY:-192.168.151.1}"
NAMESERVERS="${NAMESERVERS:-8.8.8.8 8.8.4.4}"

NODE2_CONSTRAINTS="${NODE2_CONSTRAINTS:-cores=2 mem=4G root-disk=20G root-disk-source=remote virt-type=virtual-machine zones=vm02}"
NODE2_IP_CIDR="${NODE2_IP_CIDR:-192.168.151.202/24}"

NODE3_CONSTRAINTS="${NODE3_CONSTRAINTS:-cores=2 mem=4G root-disk=20G root-disk-source=remote virt-type=virtual-machine zones=vm03}"
NODE3_IP_CIDR="${NODE3_IP_CIDR:-192.168.151.203/24}"

# Format nameservers into YAML list entries
format_nameservers_yaml() {
  local ns_yaml=""
  for ns in $NAMESERVERS; do
    clean_ns=$(echo "$ns" | tr -d '",[] ')
    if [ -n "$clean_ns" ]; then
      ns_yaml="${ns_yaml}          - ${clean_ns}
"
    fi
  done
  echo "$ns_yaml"
}

# Wait for Juju machine to obtain a valid instance ID (LXD instance name)
wait_for_machine_instance() {
  local mid="$1"
  local max_attempts=150 # 5 minutes max
  local attempt=0
  local inst_name=""

  log "Waiting for machine ${mid} to get a valid instance ID from LXD..."
  while [ $attempt -lt $max_attempts ]; do
    inst_name=$(juju machines -m controller --format json 2>/dev/null | jq -r ".machines[\"${mid}\"][\"instance-id\"] // empty" 2>/dev/null || true)
    if [ -n "$inst_name" ] && [ "$inst_name" != "null" ] && [ "$inst_name" != "pending" ]; then
      echo "$inst_name"
      return 0
    fi
    sleep 2
    attempt=$((attempt + 1))
  done

  log "Error: Timed out waiting for machine ${mid} instance ID."
  return 1
}

# Wait for LXD VM instance to accept exec commands and have system bus ready
wait_for_lxd_exec() {
  local vm_name="$1"
  local max_attempts=150 # 5 minutes max
  local attempt=0

  log "Waiting for LXD instance '${vm_name}' to become ready (exec and system bus)..."
  while [ $attempt -lt $max_attempts ]; do
    if lxc exec "$vm_name" --project "$LXD_PROJECT" -- test -S /run/dbus/system_bus_socket 2>/dev/null; then
      log "Instance '${vm_name}' is ready (system bus active)."
      return 0
    fi
    sleep 2
    attempt=$((attempt + 1))
  done

  log "Error: Timed out waiting for LXD instance '${vm_name}' system bus."
  return 1
}

# Inject Netplan static IP configuration into the instance
configure_netplan() {
  local vm_name="$1"
  local ip_cidr="$2"
  local ns_yaml="$3"

  log "Applying static IP (${ip_cidr}) to instance '${vm_name}'..."
  lxc exec "$vm_name" --project "$LXD_PROJECT" -- bash -c "
# 1. Permanently disable cloud-init network configuration to prevent overwriting Netplan
mkdir -p /etc/cloud/cloud.cfg.d
echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

# 2. Remove default cloud-init netplan files that configure DHCP
rm -f /etc/netplan/50-cloud-init.yaml /etc/netplan/*cloud-init*.yaml

# 3. Write static Netplan configuration
cat << 'EOF' > /etc/netplan/50-static.yaml
network:
  version: 2
  ethernets:
    ${NIC_NAME}:
      dhcp4: false
      dhcp6: false
      addresses:
        - ${ip_cidr}
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses:
${ns_yaml}
EOF

chmod 600 /etc/netplan/50-static.yaml
netplan apply
"
  log "Static IP (${ip_cidr}) applied successfully to '${vm_name}'."
}

# Wait for machine agent status in Juju to report 'started'
wait_for_machine_started() {
  local mid="$1"
  local max_attempts=180 # 6 minutes max
  local attempt=0
  local a_status=""

  log "Waiting for machine ${mid} agent status to become 'started' in Juju..."
  while [ $attempt -lt $max_attempts ]; do
    a_status=$(juju machines -m controller --format json 2>/dev/null | jq -r ".machines[\"${mid}\"][\"juju-status\"].current // .machines[\"${mid}\"][\"agent-status\"].current // empty" 2>/dev/null || true)
    if [ "$a_status" = "started" ]; then
      log "Machine ${mid} agent is started."
      return 0
    fi
    sleep 2
    attempt=$((attempt + 1))
  done

  log "Warning: Machine ${mid} agent status is '${a_status:-unknown}'."
}

# -------------------------------------------------------------
# MAIN WORKFLOW
# -------------------------------------------------------------

log "Preparing controller nodes for HA on controller '${JUJU_CONTROLLER_NAME}'..."

# 1. Verify controller connectivity
juju switch "${JUJU_CONTROLLER_NAME}" 2>/dev/null || true
if ! juju show-controller "${JUJU_CONTROLLER_NAME}" &>/dev/null; then
  log "Error: Controller '${JUJU_CONTROLLER_NAME}' is not reachable or not registered in Juju client."
  exit 1
fi

# 2. Check if HA is already enabled
existing_units=$(juju status -m controller --format json 2>/dev/null | jq -r '.applications["controller"].units | keys[]' 2>/dev/null || true)
if echo "$existing_units" | grep -q "controller/1" && echo "$existing_units" | grep -q "controller/2"; then
  log "Controller '${JUJU_CONTROLLER_NAME}' already has HA enabled (units: $(echo $existing_units | tr '\n' ' '))."
  exit 0
fi

# 3. Add machines to controller model
machines_json=$(juju machines -m controller --format json 2>/dev/null || echo "{}")

# Node 2
if echo "$machines_json" | jq -e '.machines["1"]' &>/dev/null; then
  m1_id="1"
  log "Machine 1 already exists in controller model."
else
  log "Adding machine for HA Node 2 (constraints: ${NODE2_CONSTRAINTS})..."
  m1_out=$(juju add-machine -m controller --constraints "${NODE2_CONSTRAINTS}")
  m1_id=$(echo "$m1_out" | grep -oE '[0-9]+' | head -n1 || echo "1")
  log "Created machine ID: ${m1_id}"
fi

sleep 15

# Node 3
if echo "$machines_json" | jq -e '.machines["2"]' &>/dev/null; then
  m2_id="2"
  log "Machine 2 already exists in controller model."
else
  log "Adding machine for HA Node 3 (constraints: ${NODE3_CONSTRAINTS})..."
  m2_out=$(juju add-machine -m controller --constraints "${NODE3_CONSTRAINTS}")
  m2_id=$(echo "$m2_out" | grep -oE '[0-9]+' | head -n1 || echo "2")
  log "Created machine ID: ${m2_id}"
fi

# 4. Wait for LXD instance names
vm_1_name=$(wait_for_machine_instance "$m1_id")
log "Machine ${m1_id} resolved to LXD instance: ${vm_1_name}"

vm_2_name=$(wait_for_machine_instance "$m2_id")
log "Machine ${m2_id} resolved to LXD instance: ${vm_2_name}"

# 5. Wait for LXD exec readiness
wait_for_lxd_exec "$vm_1_name"
wait_for_lxd_exec "$vm_2_name"

# 6. Apply static IP configurations via Netplan
ns_yaml=$(format_nameservers_yaml)
configure_netplan "$vm_1_name" "$NODE2_IP_CIDR" "$ns_yaml"
configure_netplan "$vm_2_name" "$NODE3_IP_CIDR" "$ns_yaml"

# 7. Wait for machine agents to initialize and communicate with controller
wait_for_machine_started "$m1_id"
wait_for_machine_started "$m2_id"

log "========================================================="
log "Nodes 2 and 3 prepared with static IPs and started in Juju."
log "Ready for action 'juju_enable_ha' invocation."
log "========================================================="
