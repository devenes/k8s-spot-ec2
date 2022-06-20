#! /bin/bash
apt-get update -y
apt-get upgrade -y
hostnamectl set-hostname kube-master
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
# docker installation
apt install -y docker.io
systemctl start docker
mkdir -pv /etc/docker
cat <<EOF | tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
usermod -aG docker ubuntu
newgrp docker
apt install -y apt-transport-https
# kubernetes installation
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt update
apt install -y kubelet kubeadm kubectl
systemctl start kubelet
systemctl enable kubelet
kubeadm init --pod-network-cidr=172.16.0.0/16 --ignore-preflight-errors=All
mkdir -pv /home/ubuntu/.kube
cp -vi /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown -v ubuntu:ubuntu /home/ubuntu/.kube/config
#kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
su - ubuntu -c 'kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml'
