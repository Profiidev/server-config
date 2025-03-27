#!/bin/bash
openssl genrsa -out vault.key 2048
openssl req -new -key vault.key -subj "/CN=system:node:vault-server-tls.vault.svc/O=system:nodes" -out vault.csr -config csr.conf
cp csr.yaml cdr.tmp.yaml
cat vault.csr | base64 | tr -d "\n"
k apply -f csr.tmp.yaml
k certificate approve vault-csr
set serverCert $(kubectl get csr vault-csr -o jsonpath='{.status.certificate}')
echo "$serverCert" | openssl base64 -d -A -out vault.crt
kubectl create secret generic vault-server-tls --namespace vault --from-file=vault.key=vault.key --from-file=vault.crt=vault.crt --from-file=vault.ca=vault.ca
kubectl apply -f token.yaml
kubectl create secret generic cluster-ca-cert --namespace external-secrets --from-file=ca.crt=vault.cu