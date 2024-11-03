# Kubernetes manifests
This folder is being monitored by [Flux CD](https://fluxcd.io/flux/installation/bootstrap/github/). Edit the manifests in Git and they will be automatically deployed. 

```sh
flux bootstrap github \                                                                                                                                                                     6.94% 10/67GB 
  --token-auth \
  --owner=DylanMunyard \
  --repository=pi-setup-notes \
  --branch=main \
  --path=k3s
```
