#!/bin/bash


echo "enter your zone: "
read zone
export zone=$zone
export region="${zone%-*}"


username=$(gcloud auth list --format="value(account)" | awk -F@ '{print $1}')
export username

echo "[+] Creating VM..."
gcloud compute instances create my-vm \
  --zone=$zone \
  --machine-type=e2-medium \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --quiet

sleep 10

if [ ! -f ~/.ssh/id_rsa ]; then
    echo "[+] Generating SSH key..."
    ssh-keygen -t rsa -f ~/.ssh/id_rsa -q -N ""
fi

echo "[+] Adding SSH key to instance metadata..."
gcloud compute instances add-metadata my-vm \
  --metadata-from-file ssh-keys=<(echo "$username:$(cat ~/.ssh/id_rsa.pub)") \
  --zone=$zone \
  --quiet

sleep 10

echo "[+] Copying main2.sh to VM..."
gcloud compute scp ./test2.sh $username@my-vm:/home/$username --zone=$zone --quiet

echo "[+] Creating GKE cluster..."
gcloud container clusters create-auto lab-cluster \
  --region=$region \
  --quiet


gcloud compute ssh my-vm --zone=$zone
