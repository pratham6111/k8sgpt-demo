#!/bin/bash

echo "Enter your zone: "
read zone
export zone=$zone

export project=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/project/project-id)


sudo apt-get update
sudo apt-get install -y google-cloud-cli-gke-gcloud-auth-plugin kubectl


cluster_name=$(gcloud container clusters list --zone="$zone" --format="value(name)")

if [ "$cluster_name" == "lab-cluster" ]; then
    echo "Cluster 'lab-cluster' found in zone $zone. Setting up credentials..."

    gcloud container clusters get-credentials lab-cluster --zone "$zone" --project "$project"

    
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

    
    echo "Enter the API Key: "
    read key

    k8sgpt auth add --backend google --model="gemini-2.0-flash" --password="$key"

else 
    echo "YOUR CLUSTER IS NOT YET READY.... PLEASE RE-RUN THIS SCRIPT AFTER THE CLUSTER IS CREATED...."
fi
