# kuberverse-simple
Simple shell scripts to provision k8s clusters

# kv-master
```
sudo -i
bash <(curl -s https://raw.githubusercontent.com/arturscheiner/kuberverse-simple/main/kv_master.sh)
```

# kv-worker
sudo -i
bash <(curl -s https://raw.githubusercontent.com/arturscheiner/kuberverse-simple/main/kv_worker.sh)


# run the printed kubeadm-join-command from the master on the worker
