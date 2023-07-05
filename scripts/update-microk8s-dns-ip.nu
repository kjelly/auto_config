#!/usr/bin/env nu

let dns = ( kubectl get svc -A -l k8s-app=kube-dns -o json|from json|get items.0.spec.clusterIP )
if ( echo /etc/systemd/resolved.conf.d/00-k8s-dns-resolver.conf | path exists ) {
  open /etc/systemd/resolved.conf.d/00-k8s-dns-resolver.conf|str replace "DNS=.+" $"DNS=($dns)"|sudo tee /etc/systemd/resolved.conf.d/00-k8s-dns-resolver.conf
} else {
  echo $"
[Resolve]
Cache=yes
DNS=($dns)
Domains=default.svc.cluster.local svc.cluster.local cluster.local
" | sudo tee /etc/systemd/resolved.conf.d/00-k8s-dns-resolver.conf
}

sudo systemctl restart systemd-resolved

