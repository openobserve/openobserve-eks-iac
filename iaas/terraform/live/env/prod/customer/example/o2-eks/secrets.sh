helm repo add external-secrets https://charts.external-secrets.io -n openobserve
helm repo update
helm install external-secrets external-secrets/external-secrets -n openobserve