#!/bin/bash

zone=$(curl -s -H "Metadata-Flavor: Google" \
"http://metadata.google.internal/computeMetadata/v1/instance/zone" | awk -F/ '{print $NF}')
export zone="$zone"

export project=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/project/project-id)

sudo apt-get update
sudo apt-get install -y google-cloud-cli-gke-gcloud-auth-plugin kubectl


# Install Helm and k8sgpt
echo "[+] Installing Helm and k8sgpt..."

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
sudo apt-get update
sudo apt-get install -y apt-transport-https gnupg

curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm

helm repo add k8sgpt https://charts.k8sgpt.ai/
helm repo update
helm install release k8sgpt/k8sgpt-operator -n k8sgpt-operator-system --create-namespace

curl -LO https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.4.1/k8sgpt_amd64.deb
sudo dpkg -i k8sgpt_amd64.deb

# Authenticate k8sgpt
echo "Enter the API Key: "
read key
k8sgpt auth add --backend google --model="gemini-2.0-flash" --password="$key"


# Wait for the cluster to be ready
echo "[+] Waiting for GKE cluster 'lab-cluster' to be ready..."

while true; do
  cluster_status=$(gcloud container clusters describe lab-cluster --zone="$zone" --project="$project" --format="value(status)" 2>/dev/null)

  if [[ "$cluster_status" == "RUNNING" ]]; then
    echo "[+] Cluster 'lab-cluster' is now running!"
    break
  else
    echo "[-] Cluster not ready yet (status: $cluster_status). Retrying in 30 seconds..."
    sleep 30
  fi
done

# Connect to the GKE cluster
echo "[+] Setting up credentials for GKE cluster..."
gcloud container clusters get-credentials lab-cluster --zone "$zone" --project "$project"
