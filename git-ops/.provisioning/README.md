# Kubernetes Cluster Setup

This directory contains scripts for setting up and managing Kubernetes nodes on Google Cloud Platform.

## Network Configuration

- **VPC Range**: `10.240.0.0/20`
- **Master IP Range**: `10.240.1.1` - `10.240.1.255`
- **Worker IP Range**: `10.240.2.1` - `10.240.2.255`

## Node Naming Convention

Nodes follow the pattern: `k8s-{role}-{id}`

- **Master nodes**: `k8s-master-001`, `k8s-master-002`, etc.
- **Worker nodes**: `k8s-worker-001`, `k8s-worker-002`, etc.

The ID is zero-padded to 3 digits and corresponds to the last octet of the private IP address.

## Scripts

### `create-node.sh`

Creates a new Kubernetes node VM instance on GCP.

**Usage:**

```bash
./create-node.sh --role <master|worker> --id <1-255> [--cpu <NUM>] [--mem <GB>] [--zone <ZONE>]
```

**Required Parameters:**

- `--role, -r`: Node role (`master` or `worker`)
- `--id, -i`: Host ID (last IP octet, 1-255)

**Optional Parameters:**

- `--cpu, -c`: Number of CPUs (default: master=2, worker=4)
- `--mem, -m`: Memory in GB (default: master=4GB, worker=8GB)
- `--zone, -z`: GCP zone (default: `us-central1-a`)

**Examples:**

```bash
# Create a master node with ID 11 (IP: 10.240.1.11)
./create-node.sh --role master --id 11

# Create a worker node with ID 21 (IP: 10.240.2.21)
./create-node.sh -r worker --id 21

# Create a worker with custom resources
./create-node.sh -r worker --id 123 --cpu 8 --mem 16
```

**Default Resources:**

- **Master**: 2 CPU, 4GB RAM, 30GB disk
- **Worker**: 4 CPU, 8GB RAM, 200GB disk

**Features:**

- Automatically generates node name and private IP based on role and ID
- Uses Debian 12 (bookworm) image
- Applies `startup-script.sh` as metadata for automatic initialization
- Creates custom machine type based on specified CPU/MEM
- Assigns appropriate tags (`k8s-node,master` or `k8s-node,worker`)

### `startup-script.sh`

Initialization script that runs automatically when a new VM instance is created. This script:

1. **System Setup:**

   - Updates and upgrades system packages
   - Disables swap (required by Kubernetes)
   - Configures sysctl parameters for Kubernetes networking
   - Loads required kernel modules (`overlay`, `br_netfilter`, `iscsi_tcp`)

2. **Container Runtime:**

   - Installs and configures containerd
   - Sets up `crictl` configuration
   - Enables SystemdCgroup (required by kubelet)
   - Installs `open-iscsi` package for iSCSI storage support

3. **Kubernetes Components:**

   - Adds Kubernetes APT repository (v1.34)
   - Installs `kubelet`, `kubeadm`, `kubectl`
   - Prevents automatic upgrades of Kubernetes packages
   - Enables and starts kubelet, containerd, and iscsid services

4. **Storage Support:**

   - Configures iSCSI support (`iscsi_tcp` kernel module, `open-iscsi` package, `iscsid` service)
   - Required for persistent volume support in Kubernetes

5. **Idempotency:**
   - Uses marker file (`/var/lib/k8s-init.done`) to ensure the script only runs once

## Initializing the Cluster

### First Master Node Initialization

On the first master node, initialize the Kubernetes cluster:

```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --kubernetes-version=v1.34.2
```

After initialization completes:

1. Set up kubeconfig for your user:

   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

2. Save the join command output for adding worker nodes later.

**Note:** The `--pod-network-cidr` parameter is required for most CNI plugins (e.g., Calico, Flannel). Adjust the CIDR if it conflicts with your network configuration.

## Joining Nodes to Cluster

### Master Node Join

```bash
# On existing master node
sudo kubeadm init phase upload-certs --upload-certs
JOIN_CMD=$(kubeadm token create --print-join-command)
echo "$JOIN_CMD --control-plane --certificate-key"
```

### Worker Node Join

```bash
# On existing master node
kubeadm token create --print-join-command
```

Run the output command on the new node to join it to the cluster.

## Helm Installation

To install Helm on a node:

```bash
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update
sudo apt install helm
```

## Prerequisites

- GCP project configured with:
  - VPC network with subnet named `k8s-nodes`
  - Appropriate firewall rules for Kubernetes
  - Service account with compute instance creation permissions
- `gcloud` CLI installed and authenticated
- Scripts must be executable: `chmod +x *.sh`
