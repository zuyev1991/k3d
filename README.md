**Social:**

# [![k3d](Docs/static/k3d_logo_black_blue.svg)](https://k3d.io/)

## Install K3d on MacOS
<div align="center">
Install local k8s cluster with:
</div>

- k3d
- calico cni
- metallb
- nginx-ingress-controller

## Requirement
- [homebrew](https://brew.sh)
  - Install Homebrew:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
- [docker](https://docs.docker.com/install/)
  - Note: Install docker-desktop
- [k3d](https://k3d.io/v5.6.0/#install-specific-release)
  - Install k3d:
```
brew install k3d
``` 
## Usage
Check out what you can do via `k3d help` or check the docs @ [k3d.io](https://k3d.io)

Example Workflow: Create a new cluster and use it with `kubectl`
#### 1. Initial cluster with config cluster.yaml:
```
k3d cluster create -c  ./cluster.yaml --verbose
```
#### 2. List all available cluster:
```
k3d cluster list
```
#### 3. Megre and export cluster KUBECONFIG:
```
k3d kubeconfig merge cluster-k3d-first \
    --output ~/.kube/cluster-k3d-first
```
```
export KUBECONFIG=~/.kube/cluster-k3d-first
```
#### 4. Check availability:
```
kubectl get ns
```
#### 5. Install Calico Component:
   - Note: Check the files: `./Manifest/calico/Installation.yaml` and `./cluster.yaml`
  
*cidr* into `./Manifest/calico/Installation.yaml` and *--cluster-cidr=192.168.0.0/16* into ./cluster.yaml should be the same
```
kubectl apply -f  $PWD/Manifest/calico/installation.yaml
```
*And wait when all pods will status ready:*
![](Docs/static/pod_status.png)
#### 6. Install Metallb into cluster
```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml
```
```
cd $PWD/scripts
chmod +x metallb.sh
./metallb.sh cluster-k3d-first
cd ..
```
#### 7. Create PV storage
```
kubectl apply -f $PWD/Manifest/pv/pv.yaml
```
#### 8. Create Nginx-ingress-controller
  - Name of the ingressClass: nginx-public-app
```
kubectl create namespace nginx
```
```
helm repo update nginx
helm repo add nginx https://kubernetes.github.io/ingress-nginx -n nginx
```
```
helm upgrade --install --atomic nginx nginx/ingress-nginx -f $PWD/Manifest/nginx/nginx.yaml -n nginx
```
___
