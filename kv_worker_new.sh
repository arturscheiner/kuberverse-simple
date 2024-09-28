#!/bin/sh

# Source: http://kubernetes.io/docs/getting-started-guides/kubeadm

bash <(curl -s https://raw.githubusercontent.com/arturscheiner/kuberverse-simple/main/kv_base_new.sh)

### init k8s
#kubeadm reset -f
systemctl daemon-reload
service kubelet start

apt-mark unhold kubelet kubeadm kubectl kubernetes-cni

echo
echo "EXECUTE ON MASTER: kubeadm token create --print-join-command --ttl 0"
echo "THEN RUN THE OUTPUT AS COMMAND HERE TO ADD AS WORKER"
echo
