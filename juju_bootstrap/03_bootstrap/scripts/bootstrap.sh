#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Prerequisites check
for cmd in juju lxc yq; do
  if ! command -v "$cmd" &>/dev/null; then
    log "Error: Required command '$cmd' is not installed or not in PATH."
    exit 1
  fi
done

# Configuration variables from environment or defaults
LXD_REMOTE_NAME="${LXD_REMOTE_NAME:-microcloud}"
LXD_REMOTE_URL="${LXD_REMOTE_URL:-https://192.168.10.75:8443}"
LXD_JUJU_OPERATOR_USERNAME="${LXD_JUJU_OPERATOR_USERNAME:-juju-operator}"
LXD_PROJECT="${LXD_PROJECT:-juju}"

JUJU_CLOUD_NAME="${JUJU_CLOUD_NAME:-$LXD_REMOTE_NAME}"
JUJU_CONTROLLER_NAME="${JUJU_CONTROLLER_NAME:-microcloud-controller}"
BOOTSTRAP_CONSTRAINTS="${BOOTSTRAP_CONSTRAINTS:-cores=2 mem=4G root-disk=20G root-disk-source=remote virt-type=virtual-machine}"
BOOTSTRAP_TARGET="${BOOTSTRAP_TARGET:-vm01}"

NIC_NAME="${NIC_NAME:-enp5s0}"
IP_CIDR="${IP_CIDR:-192.168.10.201/24}"
GATEWAY="${GATEWAY:-192.168.10.1}"
NAMESERVERS="${NAMESERVERS:-8.8.8.8}"

WATCHER_PID=""
cleanup() {
  if [ -n "$WATCHER_PID" ] && kill -0 "$WATCHER_PID" 2>/dev/null; then
    log "Stopping background watcher process (PID: $WATCHER_PID)..."
    kill "$WATCHER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

# Ensure LXD client certificates and remote are configured in the environment
setup_lxd_remote() {
  local config_dir="$HOME/snap/lxd/common/config"
  mkdir -p "$config_dir"

  # 1. Ensure client certificate and key are placed where snap LXD expects them
  if [ ! -f "$config_dir/client.crt" ] || [ ! -f "$config_dir/client.key" ]; then
    log "Configuring LXD client certificate in '$config_dir'..."
    local cert_file="$HOME/${LXD_JUJU_OPERATOR_USERNAME}.crt"
    local key_file="$HOME/${LXD_JUJU_OPERATOR_USERNAME}.key"

    if [ -f "$cert_file" ] && [ -f "$key_file" ]; then
      cp "$cert_file" "$config_dir/client.crt"
      cp "$key_file" "$config_dir/client.key"
      chmod 644 "$config_dir/client.crt"
      chmod 600 "$config_dir/client.key"
      log "Copied client certificates from $HOME/${LXD_JUJU_OPERATOR_USERNAME}.{crt,key}"
    else
      log "Warning: Client certificate or key not found in $HOME (${LXD_JUJU_OPERATOR_USERNAME}.{crt,key})."
    fi
  else
    log "LXD client certificates already present in '$config_dir'."
  fi

  # 2. Add LXD remote if not already registered
  if ! lxc remote list --format csv 2>/dev/null | grep -q "^${LXD_REMOTE_NAME},"; then
    log "Adding LXD remote '${LXD_REMOTE_NAME}' pointing to '${LXD_REMOTE_URL}'..."
    lxc remote add "${LXD_REMOTE_NAME}" "${LXD_REMOTE_URL}" --accept-certificate
  else
    log "LXD remote '${LXD_REMOTE_NAME}' is already configured."
  fi

  # 3. Switch default remote to the configured remote and project
  lxc remote switch "${LXD_REMOTE_NAME}" 2>/dev/null || true
  lxc project switch "${LXD_PROJECT}" 2>/dev/null || true
}

# Background watcher function to inject Netplan static IP into the controller VM
watch_and_configure_network() {
  log "Network watcher started. Polling for controller instance in LXD project '${LXD_PROJECT}'..."
  BOOTSTRAP_CONFIG="$HOME/.local/share/juju/bootstrap-config.yaml"
  CONTAINER_NAME=""
  
  # Maximum wait time for instance detection: 10 minutes (300 iterations * 2s)
  local max_attempts=300
  local attempt=0

  while [ $attempt -lt $max_attempts ]; do
    # Check method 1: via bootstrap-config.yaml once juju bootstrap creates/updates it
    if [ -f "$BOOTSTRAP_CONFIG" ]; then
      UUID=$(yq eval ".controllers[\"${JUJU_CONTROLLER_NAME}\"][\"controller-model-uuid\"] // \"\"" "$BOOTSTRAP_CONFIG" 2>/dev/null || true)
      if [ -n "$UUID" ] && [ "$UUID" != "null" ]; then
        SUFFIX="${UUID: -6}"
        C_NAME="juju-${SUFFIX}-0"
        # Verify the instance exists and is running in LXD
        if lxc list --project "$LXD_PROJECT" --format csv -c n,s 2>/dev/null | grep -iq "^${C_NAME},RUNNING"; then
          CONTAINER_NAME="$C_NAME"
          break
        fi
      fi
    fi

    # Check method 2: fallback by checking lxc list for any running juju-*-0 VM in the project
    C_NAME=$(lxc list --project "$LXD_PROJECT" --format csv -c n,t,s 2>/dev/null | grep -i "juju-.*-0,virtual-machine,RUNNING" | head -n1 | cut -d',' -f1 || true)
    if [ -n "$C_NAME" ]; then
      CONTAINER_NAME="$C_NAME"
      break
    fi

    sleep 2
    attempt=$((attempt + 1))
  done

  if [ -z "$CONTAINER_NAME" ]; then
    log "Error: Timed out waiting for controller instance to appear in LXD project '${LXD_PROJECT}'."
    exit 1
  fi

  log "Found controller instance: '${CONTAINER_NAME}'. Waiting for LXD agent / exec readiness..."

  # Wait until lxc exec succeeds
  local exec_attempts=150 # 5 minutes max
  local exec_attempt=0
  local exec_ready=false

  while [ $exec_attempt -lt $exec_attempts ]; do
    if lxc exec "$CONTAINER_NAME" --project "$LXD_PROJECT" -- true 2>/dev/null; then
      exec_ready=true
      break
    fi
    sleep 2
    exec_attempt=$((exec_attempt + 1))
  done

  if [ "$exec_ready" != "true" ]; then
    log "Error: Timed out waiting for '${CONTAINER_NAME}' to accept lxc exec commands."
    exit 1
  fi

  log "Instance '${CONTAINER_NAME}' is ready. Applying static Netplan configuration..."

  # Format nameservers for Netplan YAML
  local ns_yaml=""
  for ns in $NAMESERVERS; do
    clean_ns=$(echo "$ns" | tr -d '",[] ')
    if [ -n "$clean_ns" ]; then
      ns_yaml="${ns_yaml}          - ${clean_ns}
"
    fi
  done

  # Inject Netplan static configuration
  lxc exec "$CONTAINER_NAME" --project "$LXD_PROJECT" -- bash -c "cat << 'EOF' > /etc/netplan/50-static.yaml
network:
  version: 2
  ethernets:
    ${NIC_NAME}:
      dhcp4: false
      dhcp6: false
      addresses:
        - ${IP_CIDR}
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses:
${ns_yaml}EOF
netplan apply
"

  log "Static IP (${IP_CIDR}) applied successfully to ${CONTAINER_NAME}."
}

# 1. Setup LXD client credentials and remote
setup_lxd_remote

# Clean up any stale bootstrap config entry for this controller from previous runs
BOOTSTRAP_CONFIG="$HOME/.local/share/juju/bootstrap-config.yaml"
if [ -f "$BOOTSTRAP_CONFIG" ]; then
  yq eval "del(.controllers[\"${JUJU_CONTROLLER_NAME}\"])" -i "$BOOTSTRAP_CONFIG" 2>/dev/null || true
fi

# 2. Start the watcher in the background
watch_and_configure_network &
WATCHER_PID=$!

# 3. Run juju bootstrap
log "Starting Juju bootstrap for controller '${JUJU_CONTROLLER_NAME}' on cloud '${JUJU_CLOUD_NAME}'..."
juju bootstrap "$JUJU_CLOUD_NAME" "$JUJU_CONTROLLER_NAME" \
  --bootstrap-constraints "$BOOTSTRAP_CONSTRAINTS" \
  --config project="$LXD_PROJECT" \
  --to "$BOOTSTRAP_TARGET"

log "Waiting for background watcher to conclude..."
wait "$WATCHER_PID" 2>/dev/null || true
WATCHER_PID=""

log "Juju controller '${JUJU_CONTROLLER_NAME}' bootstrapped successfully!"
