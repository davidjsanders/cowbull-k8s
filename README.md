# cowbull-k8s
Set of scripts (yaml) for Cowbull app

* Delete: ./scripts/delete.sh -s dsanderscan -t k8s-master:32081 -l load-balancer-ip
* Load  : ./scripts/load.sh -s dsanderscan -t k8s-master:32081 -l load-balancer-ip
* Show  : kubectl get pod,svc,ing,pv,pvc,sc -n cowbull

That's it (so far)