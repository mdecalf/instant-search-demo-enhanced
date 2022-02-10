**Note:** this repository is hosting the demo that was previously located at [algolia/examples](https://github.com/algolia/examples/tree/master/instant-search/instantsearch.js/)

-----

Instant-Search Demo Enhanced
====================

The same sample project but enhanced

## Features +
* The simplest dockerfile of the world
* A simple multiarch Makefile
* A simple kubernetes manifest to ensure graceful handling of failures
* A k3s cluster with
  * Traefik Ingress
  * Argo rollout for release

## Prerequisites

You need to have installed :

* Docker from docker ( you need buildx if you want to build image )
  * https://docs.docker.com/desktop/mac/install/
  * https://docs.docker.com/engine/install/ubuntu/
  

* Install Kubectl
```shell
sudo curl -sSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo chmod +x /usr/local/bin/kubectl
```

* Install Argo rollout Kubectl plugin
```shell
sudo curl -sSL -o /usr/local/bin/kubectl-argo-rollouts https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
sudo chmod +x /usr/local/bin/kubectl-argo-rollouts 
```

* Install ArgoCD cli
```shell
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd
```

* <span style="color:red"> Shoot your MDM ( or be kind with him ) because it could be a problem with port binding, among other things. </span>
  
  * If you can't or if you have a problem with it please run into a VM with multipass for example or contact me for providing it

## Get the project (if you want to see it or build it)

```sh
git clone git@github.com:algolia/mdecalf/instant-search-demo-enhanced.git
cd instant-search-demo-enhanced
```

## Build application (if you want or use image below)

```sh
export IMAGE=<YOUR_IMAGE_NAME>
export TAG=<DESIRED_TAG>
# Make sure you have done a docker login
export DOCKER_REPO=<YOUR_DOCKER_REPO>

make image
```

## Install k3d

```shell
wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash

k3d cluster create algolia --api-port 6443 -p "8080:80@loadbalancer" -p "8443:443@loadbalancer"

```

## Install argocd and argo rollout

```shell
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Terrible hack for avoid ssl passthrough problem, sorry
cat <<EOF | kubectl -n argocd patch deployment argocd-server --patch '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "argocd-server",
            "command": [
              "argocd-server",
              "--repo-server",
              "argocd-repo-server:8081",
              "--insecure"
            ]
          }
        ]
      }
    }
  }
}'
EOF

cat <<EOF | kubectl -n argocd apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-http-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
spec:
  rules:
  - host: cd.algolia.hire.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
  tls:
  - hosts:
    - cd.algolia.hire.com
    secretName: argocd-secret
EOF
```

## Login to Argocd

You can access to the UI through [cd.algolia.hire.com](https://cd.algolia.hire.com:8443)

Get admin password

```shell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

You can connect through the UI with user admin and the password above ( maybe you need refresh page at login )

Connect with argocd cli

```shell
# use password provided below
argocd login --insecure --grpc-web cd.algolia.hire.com:8443 --username admin
```

## Deploy application

For the purpose of this demo one image with two tags **green** and **blue** were pushed on dockerhub [acronys/instant-search-demo-enhanced](https://hub.docker.com/repository/docker/acronys/instant-search-demo-enhanced)

```shell
kubectl create ns algolia-search

kubectl -n algolia-search apply -f deployments/search-app-rollout.yml

# Verify that your application is deployed with argo rollout
kubectl argo rollouts -n algolia-search get rollout search-app-rollout --watch

# OR
# TODO for raw github
```

## Access the app

You can access app through [http://127.0.0.1:8080](http://127.0.0.1:8080) or [https://127.0.0.1:8443](http://127.0.0.1:8443) on your browser

It's the blue version for the purpose of this demo

## Hurt the app

By design our application is replicated and load balanced so you can delete a pod

```shell
# Get the pods and choose one or more
kubectl -n algolia-search get  po

# Delete a chosen pod
kubectl -n algolia-search delete po <YOUR_VICTIM>

# It will be re-created again and again
kubectl -n algolia-search get  po 
NAME                                  READY   STATUS              RESTARTS   AGE
search-app-rollout-6d459b5df6-8gn69   1/1     Running             1          11h
search-app-rollout-6d459b5df6-7wxx5   1/1     Running             1          11h
search-app-rollout-9c56c956f-x67lp    1/1     Running             1          11h
search-app-rollout-6d459b5df6-frvl6   1/1     Running             1          11h
search-app-rollout-6d459b5df6-r5cn8   0/1     ContainerCreating   0          2s
search-app-rollout-6d459b5df6-2r6c2   0/1     Terminating         0          15s
```



### On 
If you want to replicate this demo using your own Algolia credentials that you can obtain creating a free account on Algolia.com.

Just install the Ruby `algoliasearch` gem and use the `push.rb` script to send the data and automatically configure the product index (same for both versions).

```sh
$ gem install algoliasearch
$ ./dataset_import/push.rb YourApplicationID YourAdminAPIKey YourIndexName
```

Then, you'll need to replace the demo credentials with your own:
- in `search.js` and `search-simplified.js`, set your own `APPLICATION_ID` instead of `"latency"` (which is our demo `APPLICATION_ID`),
- in `search.js` and `search-simplified.js`, set your own `SEARCH_ONLY_API_KEY` instead of `"6be0576ff61c053d5f9a3225e2a90f76"`,
- in `search.js` and `search-simplified.js`, set your own `index` name instead of `"instant_search"`.


We've extracted 20 000+ products from the [Best Buy Developer API](https://developer.bestbuy.com). You can find the associated documentation [here](https://developer.bestbuy.com/documentation/products-api).

## Tutorial

**Follow this [step by step tutorial](https://www.algolia.com/doc/tutorials/search-ui/instant-search/build-an-instant-search-results-page/instantsearchjs/) (on Algolia.com) to learn how this implementation works** and how it has been built using the [instantsearch.js library](https://community.algolia.com/instantsearch.js/).

A more general overview of filtering and faceting is available in a [dedicated tutorial](https://www.algolia.com/doc/tutorials/search-ui/instant-search/filtering/faceting-search-ui/instantsearchjs/).

