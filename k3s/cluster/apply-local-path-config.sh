#!/bin/bash
kubectl create configmap local-path-config -n kube-system --from-file=config.json=local-path-config.yaml -o yaml --dry-run=client | kubectl apply -f - 