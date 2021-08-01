# Admission web hook
Follow https://github.com/fdns/simple-admission
- Remove the `namespaceSelector` because it's confusing. It selects on attributes of the metadata, not the namespace itself. 
- Run ./generate_certs k8s-admission k8s-admission to generate the validation web hook manifest and SSL cert secrets. 

The web hook will be called by Kube at `https://k8s-admission.k8s-admission.svc/validate` so the service port needs to be 443. 