#!/bin/bash
set -euo pipefail

ROLE=""             # master | worker
ZONE="us-central1-a"
ID=""               # last octet (1-255)

# Subnet
SUBNET="k8s-nodes"

# Startup script
STARTUP_SCRIPT="./startup-script.sh"

# Debian 12 (bookworm)
IMAGE_FAMILY="debian-12"
IMAGE_PROJECT="debian-cloud"

# Disk sizes & tags
MASTER_DISK_SIZE="30GB"
WORKER_DISK_SIZE="200GB"

MASTER_TAGS="k8s-node,master"
WORKER_TAGS="k8s-node,worker"

# Role-based defaults (set after ROLE is known)
CPU=""
MEM_GB=""

# IP ranges
MASTER_NET_PREFIX="10.240.1"
WORKER_NET_PREFIX="10.240.2"

usage() {
  cat <<EOF
Usage:
  $0 --role <master|worker> --id <1-255> [--cpu <NUM>] [--mem <GB>] [--zone <ZONE>]

Required:
  --role, -r        Node role: master or worker
  --id,   -i        Host ID (last IP octet), 1-255

Role-based defaults:
  master -> CPU=2, MEM=4GB, IP in 10.240.1.<ID>
  worker -> CPU=4, MEM=8GB, IP in 10.240.2.<ID>

Name & IP are generated automatically:
  master + ID=11  -> name: k8s-master-011, IP: 10.240.1.11
  worker + ID=21  -> name: k8s-worker-021, IP: 10.240.2.21

Examples:
  $0 --role master --id 11
  $0 -r worker --id 21
  $0 -r worker --id 123 --cpu 8 --mem 16
EOF
}

# --- Parse options ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --role|-r)
      ROLE="$2"; shift 2;;
    --id|-i)
      ID="$2"; shift 2;;
    --cpu|-c)
      CPU="$2"; shift 2;;
    --mem|-m)
      MEM_GB="$2"; shift 2;;
    --zone|-z)
      ZONE="$2"; shift 2;;
    --help|-h)
      usage; exit 0;;
    *)
      echo "Unknown option: $1" >&2
      usage; exit 1;;
  esac
done

# --- Required checks ---
if [[ "$ROLE" != "master" && "$ROLE" != "worker" ]]; then
  echo "ERROR: --role must be 'master' or 'worker'."
  exit 1
fi

if [[ -z "$ID" ]]; then
  echo "ERROR: --id is required."
  exit 1
fi

# ID must be integer 1-255
if ! [[ "$ID" =~ ^[0-9]+$ ]]; then
  echo "ERROR: --id must be an integer (got: '$ID')."
  exit 1
fi

ID_INT=$((10#$ID))
if (( ID_INT < 1 || ID_INT > 255 )); then
  echo "ERROR: --id must be between 1 and 255 (got: ${ID_INT})."
  exit 1
fi

# Build IP & name from role + ID
SUFFIX=$(printf "%03d" "$ID_INT")

if [[ "$ROLE" == "master" ]]; then
  PRIVATE_IP="${MASTER_NET_PREFIX}.${ID_INT}"
  NAME="k8s-master-${SUFFIX}"
else
  PRIVATE_IP="${WORKER_NET_PREFIX}.${ID_INT}"
  NAME="k8s-worker-${SUFFIX}"
fi

# --- Role-based default CPU/MEM (if not overridden) ---
if [[ "$ROLE" == "master" ]]; then
  CPU="${CPU:-2}"
  MEM_GB="${MEM_GB:-4}"
else
  CPU="${CPU:-4}"
  MEM_GB="${MEM_GB:-8}"
fi

# Convert GiB -> MiB
MEM_MB=$((MEM_GB * 1024))

# Build custom machine type
MACHINE_TYPE="e2-custom-${CPU}-${MEM_MB}"

# Role-specific config
if [[ "$ROLE" == "master" ]]; then
  BOOT_DISK_SIZE="$MASTER_DISK_SIZE"
  TAGS="$MASTER_TAGS"
else
  BOOT_DISK_SIZE="$WORKER_DISK_SIZE"
  TAGS="$WORKER_TAGS"
fi

echo ">>> Creating ${ROLE} instance"
echo "    Name: ${NAME}"
echo "    CPU: ${CPU}"
echo "    RAM: ${MEM_GB} GiB (${MEM_MB} MB)"
echo "    Machine Type: ${MACHINE_TYPE}"
echo "    Disk: ${BOOT_DISK_SIZE}"
echo "    Tags: ${TAGS}"
echo "    Zone: ${ZONE}"
echo "    Private IP: ${PRIVATE_IP}"
echo "    Image: Debian 12 (bookworm)"

gcloud compute instances create "${NAME}" \
  --zone="${ZONE}" \
  --machine-type="${MACHINE_TYPE}" \
  --image-family="${IMAGE_FAMILY}" \
  --image-project="${IMAGE_PROJECT}" \
  --boot-disk-size="${BOOT_DISK_SIZE}" \
  --subnet="${SUBNET}" \
  --private-network-ip="${PRIVATE_IP}" \
  --can-ip-forward \
  --tags="${TAGS}" \
  --metadata-from-file startup-script="${STARTUP_SCRIPT}"

echo ">>> Instance '${NAME}' (${ROLE}) created successfully."