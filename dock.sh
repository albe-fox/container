#!/usr/bin/env bash
#
# author: albedo
# email: albedo@foxmail.com
# date: 20190819
# usage: kubeadm deploy docker cluster
#

# stop firewalld && disable selinux
systemctl stop firewalld
systemctl disable firewalld
sed -ir 's/\(SELINUX=\).*$/\1DISABLE/g' /etc/selinux/config
setenforce 0
# install some depend service
yum install -y yum-utils device-mapper-persistent-data lvm2 git
# install aliyun source repository for docker latest version
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# install ## yum list docker-ce --showduplicates 
yum -y install docker-ce
# start docker and auto-start docker 
systemctl start docker
systemctl enable docker

# pull images for kubeadm
#docker pull mirrorgooglecontainers/kube-apiserver:v1.15.0
#docker tag mirrorgooglecontainers/kube-apiserver:v1.15.0 k8s.gcr.io/kube-apiserver:v1.15.0
#docker pull mirrorgooglecontainers/kube-controller-manager:v1.15.0
#docker tag mirrorgooglecontainers/kube-controller-manager:v1.15.0 k8s.gcr.io/kube-controller-manager:v1.15.0
#docker pull mirrorgooglecontainers/kube-scheduler:v1.15.0
#docker tag mirrorgooglecontainers/kube-scheduler:v1.15.0 k8s.gcr.io/kube-scheduler:v1.15.0
#docker pull mirrorgooglecontainers/kube-proxy:v1.15.0
#docker tag mirrorgooglecontainers/kube-proxy:v1.15.0 k8s.gcr.io/kube-proxy:v1.15.0
#docker pull mirrorgooglecontainers/pause:3.1
#docker tag mirrorgooglecontainers/pause:3.1 k8s.gcr.io/pause:3.1
#docker pull mirrorgooglecontainers/etcd:3.3.10-1
#docker tag mirrorgooglecontainers/etcd:3.3.10-1  k8s.gcr.io/etcd:3.3.10-1
#docker pull coredns/coredns:1.3.1
#docker tag coredns/coredns:1.3.1 k8s.gcr.io/coredns:1.3.1
sh load.sh

# down swap space
swapoff -a
#sed -ir '/swap/ s/^\(.*\)$/#\1/' /etc/fstab

# install kubeadm & kubelet
 cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum makecache fast -y
yum install -y kubelet kubeadm kubectl ipvsadm

cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
vm.swappiness=0
EOF
 sysctl --system
# load kernel module 
modprobe ip_vs
 modprobe ip_vs_rr
 modprobe ip_vs_wrr
 modprobe ip_vs_sh
 modprobe nf_conntrack_ipv4

DOCKER_CGROUPS=$(docker info | grep 'Cgroup' | cut -d' ' -f4)

cat >/etc/sysconfig/kubelet<<EOF
KUBELET_EXTRA_ARGS="--cgroup-driver=$DOCKER_CGROUPS --pod-infra-container-image=k8s.gcr.io/pause:3.1"
EOF

hname=`hostname`
if [ "$hname" = "master" ];then
# ---master--- initial kubeadm in master 
ip=`ip a | awk -F'[ /]+' 'NR==9{print $3}'`
ipde=`ip a | awk -F'[ :]+' 'NR==7{print $2}'`
kubeadm init --kubernetes-version=v1.15.0 --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$ip --ignore-preflight-errors=Swap &>kuadmjoin.txt

 rm -rf $HOME/.kube
 mkdir -p $HOME/.kube
 cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
 chown $(id -u):$(id -g) $HOME/.kube/config
# flannel
 cd ~ && mkdir flannel && cd flannel
wget https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
sed -ir 's/quay.io\/coreos\/flannel:v0.10.0-amd64/registry.cn-shanghai.aliyuncs.com\/gcr-k8s\/flannel:v0.10.0-amd64/g' kube-flannel.yml
sed -ir "/subnet/a\        - --iface=$ipde" kube-flannel.yml
sed -i "/Schedule/a\      - key: node.kubernetes.io/not-ready\n        operator: Exists\n        effect: NoSchedule" kube-flannel.yml
kubectl apply -f ~/flannel/kube-flannel.yml
systemctl enable kubelet
else
# ---node--- 启动kubelet
 systemctl daemon-reload
systemctl enable kubelet && systemctl restart kubelet
# get master's kuadmjoin.txt
# kubeadm join ...
fi
