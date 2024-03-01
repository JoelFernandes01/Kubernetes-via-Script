#----------------------------------------------------------------------------
# Instalação automatizada do Kubernetes no Ubuntu Server 22.04
#
# Download da ISO do Ubuntu Server
# https://releases.ubuntu.com/22.04.3/ubuntu-22.04.3-live-server-amd64.iso
#----------------------------------------------------------------------------
# Desenvolvido e personalizado por Joel Fernandes
# Meus contatos :
# - Celular:  (61) 98468-1921
# - Linkedin: https://www.linkedin.com/in/joel-fernandes-25838425/
# - Facebook: https://www.facebook.com/JoelFernandesSilvaFilho/
#
# Pré-requistos
# Acesso como root ou com previlégios de root
# Protocol  Direction   Port Range  Purpose               Used By
# TCP       Inbound     6443*       Kubernetes API server   All
# TCP       Inbound     2379-2380   etcd server client API  kube-apiserver, etcd
# TCP       Inbound     10250       Kubelet API             Self, Control plane
# TCP       Inbound     10251       kube-scheduler          Self
# TCP       Inbound     10252       kube-controller-manager Self
# 
# Atualização dos pacotes do Ubuntu Server
sudo apt update -y

# Comente ou descomente a linha de acordo com o servidor que irá executar o script 
echo "Nomeando o servidor para o Control Plane" ### COMENTE ESSA LINHA QUANDO EXECUTAR NO WORKER-01 ####
sudo hostnamectl set-hostname controlplane-01

#echo "Nomeando o servidor para o worker-01"
#sudo hostnamectl set-hostname worker-01 ### DESCOMENTE ESSA LNHA QUANDO EXECUTAR NO WORKER-01 ###

echo "Disabling swap"
swapoff -a; sed -i '/swap/d' /etc/fstab

echo "Disabling Firewall"
systemctl disable --now ufw

echo "Enabling and Loading Kernel modules"
{
cat >> /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter
}

echo "Adding Kernel settings"
{
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system
}

echo "Install Containerd runtime"
{
  apt update
  apt install -y containerd apt-transport-https
  mkdir /etc/containerd
  containerd config default > /etc/containerd/config.toml
  systemctl restart containerd
  systemctl enable containerd
}

echo "Installing Kubernetes"
{
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
}

# Instalar as ferramentas de administração do Kubernetes
apt update && apt install -y kubeadm=1.28.2-00 kubelet=1.28.2-00 kubectl=1.28.2-00

# Extrair o valor inet da primeira placa de rede excluindo a interface "lo" e armazenar em uma variável
inet_value=$(ifconfig | awk '/inet / && $1 !~ /lo/{gsub("addr:",""); print $2; exit}')

echo "Parabéns, seu ambiente Kubernetes está instalado com sucesso !"
echo    "########============================================########"
echo "Copie e cole o comando abaixo, para iniciar seu cluste 
echo "kubeadm init --control-plane-endpoint="$inet_value:6443" --upload-certs --apiserver-advertise-address=$inet_value --pod-network-cidr=10.244.0.0/16