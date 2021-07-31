# Prometheus Operator
Followed these instructions https://github.com/cablespaghetti/k3s-monitoring to install Prometheus + Grafana.

1. Git clone https://github.com/cablespaghetti/k3s-monitoring
2. Edit `kube-prometheus-stack-values.yaml` 
3. Under `prometheusSpec` add runAsGroup, runAsNonRoot, runAsUser and fsGroup:
```yaml
prometheus:
  prometheusSpec:
    retention: 3d
    runAsGroup: 1000
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000

```
4. After deploy, go to the `k3s_storage` path and change ownership on the created volumes to `$(id):$(id)`:
`sudo chown -R bansion:bansion pvc-123`