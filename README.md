# [![k3d](Docs/static/k3d_logo_black_blue.svg)](https://k3d.io/)

<h1 align="center">
Install K3d on MacOS / Linux
</h1>

## Install local k8s cluster with:

- k3d (K3s in Docker)
- Cilium CNI
- Metallb (LoadBalancer)
- Nginx Ingress Controller
- Persistent Volumes and CoreDNS

## Requirement

  - ### [Orbstack](https://orbstack.dev/download)
    #### Install Orbstack for macOS

  - ### [Docker](https://docs.docker.com/install/)
      #### Install Docker Engine or Docker Desktop for Linux
      #### Check Docker:
      ```
      docker --version
      docker info
      ```

- ### [Homebrew](https://brew.sh)
    #### Install Homebrew:
    ```
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```

- ### [k3d](https://k3d.io/stable/#releases)
    #### Install via Homebrew (Linuxbrew) or manually:
    ```
    brew install k3d
    ```
    #### Or via script:
    ```
    wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    ```
- ### [Helm](https://helm.sh/docs/intro/install/)
    #### Install Helm package manager:
    ```
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    ```

## Usage

#### Check out what you can do via `k3d help` or check the docs - [k3d.io](https://k3d.io)

#### Before start the first cluster check your version of k3d, k3s
```
k3d --version
```
![](Docs/static/k3d_version.png)
> [!NOTE]
> 
> Change specific version of kubernetes server into cluster.yaml. For release note k3s you can view link https://docs.k3s.io/release-notes/v1.30.X

## Step 1: Create k3d cluster

- #### Create Cluster with `kubectl`:

    ```
    k3d cluster create -c  ./cluster.yaml --verbose
    ```

- #### List clusters:

    ```
    k3d cluster list
    ```

- #### Merge and export cluster KUBECONFIG:

    ```
    k3d kubeconfig merge cluster-k3d-first --output ~/.kube/cluster-k3d-first
    export KUBECONFIG=~/.kube/cluster-k3d-first
    ```

- #### Check availability:

    ```
    kubectl get ns
    ```

## Step 2: Install Cilium (CNI)

- #### Install via Helm:

    ```
    helm repo add cilium https://helm.cilium.io/
    helm repo update
    helm upgrade --install --atomic cilium cilium/cilium --version 1.15.6 --namespace=kube-system --values=./cilium-values.yaml
    ```

- #### Verify Cilium:

    ```
    kubectl -n kube-system get pods | grep cilium
    kubectl -n kube-system get ds cilium
    ```

## Step 3: Install Metallb (LoadBalancer)

- #### Install native manifests:

    ```
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
    ```

- #### Determine your network range

    ```
    docker network inspect k3d-cluster-k3d-first
    ```
  
- #### Example output:

    ```
    {
        "Subnet": "172.17.0.0/16",
        "Gateway": "172.17.0.1"
    }
    ```

- #### Update Metallb configuration

    ```
    ---
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      name: default
      namespace: metallb-system
    spec:
    # IP address range within the Docker or Orbstack network
      addresses:
        - 172.17.0.200-172.17.0.250  
    ---
    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement
    metadata:
      name: default-advertisement
      namespace: metallb-system
    ```

- #### Apply your configuration:

    ```
    kubectl apply -f metallb.sh    
    ```

## Step 4: Create Persistent Volumes and CoreDNS

- #### Apply Persistent Volumes and CoreDNS yamls:

    ```
    kubectl apply -f $PWD/manifests/pv/pv.yaml
    kubectl apply -f $PWD/manifests/coredns/coredns.yaml
    ```

## Step 5: Install Nginx Ingress Controller

- #### Create namespace:

    ```
    kubectl create namespace nginx
    ```

- #### Add Helm repo:

    ```
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    ```

- #### Install:

    ```
    helm upgrade --install --atomic nginx ingress-nginx/ingress-nginx -f $PWD/manifests/nginx/nginx.yaml -n nginx
    ```

- #### Verify:

    ```
    kubectl get pods -n nginx
    ```

## Step 6: Test Deployment and Ingress

- #### Apply sample deployment and ingress:

    ```
    kubectl apply -f $PWD/manifests/nginx/ingress.yaml      
    ```

- #### Describe all created ingress, then make curl reguest for cheking

    ```
    kubectl get ingress -A
    ```

![](Docs/static/ingress.png)

- #### Test via curl:

    ```
    curl -v -H "Host: test-hello.dyn.example.com" http://<LoadBalancer_IP>
    ```

![](Docs/static/curl_request.png)

___
> [!TIP]
> ## Notes / Best Practices
>
>### Sequence matters:
>
>- #### Cluster → CNI (Cilium) → LoadBalancer (Metallb) → Storage & CoreDNS → Ingress
>- #### Installing CNI after workloads can break networking.
>
>### Docker network:
>
>- #### Metallb must use an IP range in the Docker bridge network or a custom network accessible from host.
>
>### Kubeconfig:
>
>- #### Always export correct `KUBECONFIG` before using `kubectl`.
>
>### Troubleshooting:
>
>- #### Pods stuck in `ContainerCreating` → check `kubectl describe pod <pod>` and `docker ps`.
>
>- #### LoadBalancer service not assigned → check IP pool and network connectivity.