# Install Linkerd dashboard

(following the customisation guide) \
` linkerd viz install > linkerd.yaml` will produce dashboard.yaml

In [kustomization.yaml](./kustomization.yaml). The important part is `-enforced-host=.*` which turns off the host validation:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  template:
    spec:
      containers:
        - name: web
          args:
            - -linkerd-controller-api-addr=linkerd-controller-api.linkerd.svc.cluster.local:8085
            - -linkerd-metrics-api-addr=metrics-api.linkerd-viz.svc.cluster.local:8085
            - -cluster-domain=cluster.local
            - -grafana-addr=grafana.linkerd-viz.svc.cluster.local:3000
            - -controller-namespace=linkerd
            - -viz-namespace=linkerd-viz
            - -log-level=info
            - -enforced-host=.*
```

Run it!

`kubectl kustomize . | kubectl apply -f -`