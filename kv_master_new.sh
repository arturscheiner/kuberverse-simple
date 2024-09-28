#!/bin/sh

# Source: http://kubernetes.io/docs/getting-started-guides/kubeadm

#bash <(curl -s https://raw.githubusercontent.com/arturscheiner/kuberverse-simple/main/kv_base_new.sh)


# etcdctl
ETCD_VER=v3.5.16

# choose either URL
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GOOGLE_URL}
DOWNLOAD_PATH='/tmp'
EXTRACT_PATH='/tmp/etcd-download-test'
MACHINE="$(uname -m)"

if [[ $MACHINE == "x86_64" || $MACHINE == "amd64" ]]; then
    rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
    rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test

    curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o ${DOWNLOAD_PATH}/etcd-${ETCD_VER}-linux-amd64.tar.gz
    tar xzvf ${DOWNLOAD_PATH}/etcd-${ETCD_VER}-linux-amd64.tar.gz -C ${DOWNLOAD_PATH}/etcd-download-test --strip-components=1
    rm -f ${DOWNLOAD_PATH}/etcd-${ETCD_VER}-linux-amd64.tar.gz

    ${EXTRACT_PATH}/etcd --version
    ${EXTRACT_PATH}/etcdctl version
    ${EXTRACT_PATH}/etcdutl version
    mv ${EXTRACT_PATH}/* /usr/bin/
    # rm -rf ${ETCDCTL_VERSION_FULL} ${ETCDCTL_VERSION_FULL}.tar.gz
else
    snap install etcd
fi

apt -y autoremove

### init k8s
rm /root/.kube/config || true
kubeadm init --ignore-preflight-errors=NumCPU --skip-token-print

mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config

curl -sS https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/calico.yaml -O
kubectl apply -f calico.yaml

echo
echo "### COMMAND TO ADD A WORKER NODE ###"
kubeadm token create --print-join-command --ttl 0
