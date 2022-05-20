# Sock-shop app deploy on EKS cluster with monitoring

## Table of contents
* [General info](#general-info)
* [Prerequisites](#Prerequisites)
* [Set up your Terraform workspaces and provision resources](#Set-up-your-Terraform-workspaces-and-provision-resources)
* [Configure kubectl](#Configure-kubectl)
* [Deploy and access Kubernetes Dashboard with kubectl](#Deploy-and-access-Kubernetes-Dashboard-with-kubectl)
* [Deploy Kubernetes Metrics Server](#Deploy-Kubernetes-Metrics-Server)
* [Deploy Kubernetes Dashboard](#Deploy-Kubernetes-Dashboard)
* [Installing sock-shop on Kubernetes](#Installing-sock-shop-on-Kubernetes)
* [Monitoring Using Prometheus Operator](#Monitoring-Using-Prometheus-Operator)
* [Clean up your workspace](#Clean-up-your-workspace)
* [Things to improve](#things-to-improve)

## General info

The repository contains components and instructions needed to deploy Sock-shop application on a provisioned EKS cluster as well as [kube-prometheus-stack](https://github.com/prometheus-operator/kube-prometheus) - end-to-end Kubernetes cluster monitoring with [Prometheus](https://prometheus.io/) using [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator).

## Prerequisites

* GIT
* Terraform
* an AWS account with the IAM permissions listed on the EKS module documentation,
* a configured AWS CLI with profile name "scalac"
* AWS IAM Authenticator
* kubectl v1.23.6
* Kubernetes 1.16+
* Helm 3+

## Set up Terraform workspaces and provision resources
```
$ git clone https://github.com/hashicorp/learn-terraform-provision-eks-cluster
$ cd eks-cluster
```
In this directory you should find 6 files neccessary to provision a VPC, security groups and EKS cluster. Expected output: 

1. main.tf```*``` - inside ```remote-state``` folder
2. vpc.tf - provisions a new VPC, subnets and availability zones using the [AWS VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/2.32.0).
3. security-groups.tf - provisions the security groups used by the EKS cluster.
4. eks-cluster.tf```**``` - provisions all the resources (AutoScaling Groups, etc...) required to set up an EKS cluster using the AWS EKS Module.
5. outputs.tf - defines the output configuration.
6. versions.tf - sets the Terraform version to at least 0.14. It also sets versions for the providers used in this sample and backend for storing terraform state.

```*```There might be a need to change the bucket name in ```main.tf``` file as it has to be unique. If this is the case, the bucket name in the backend in ```versions.tf``` has to be changed respectively.

```**``` Under ```map_users``` fill your user's details (userarn and username).

### Initialize and provision Terraform remote-state workspace
After cloning the repository, initialize the Terraform workspace to download and configure the providers.

1. Go to ```remote-state``` folder and run following commands to initialize workspace:
```
$ terraform init
```
2. Run ```terraform plan``` to review the planned actions:
```
$ terraform plan
```
3. The plan should have 2 resources to create. If correct, run:
```
$ terraform apply
```
Confirm the apply with typing: ```yes```.


### Initialize and provision Terraform EKS cluster workspace

1. Go back to ```eks-cluster``` directory and repeat the process:
```
$ terraform init
```

2. Run ```terraform plan``` to review the planned actions:
```
$ terraform plan
```
3. The plan should have 53 resources to create. If correct, run:
```
$ terraform apply
```
Confirm the apply with typing: ```yes```.

## Configure kubectl
Run the following command to retrieve the access credentials for your cluster and automatically configure kubectl.
```
$ aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)
```

## Deploy and access Kubernetes Dashboard with kubectl
To verify that your cluster is configured correctly and running, we can deploy the Kubernetes dashboard and navigate to it in your local browser.

### Deploy Kubernetes Metrics Server
The Kubernetes Metrics Server is used to gather metrics such as cluster CPU and memory usage over time but it's not deployed by default in EKS clusters.

Deploy the metrics server to the cluster by running the command below:
```
$ kubectl apply -f metrics-server-0.3.6/deploy/1.8+/
```
Verify that the metrics server has been deployed. If successful, you should see something like this:
```
$ kubectl get deployment metrics-server -n kube-system
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
metrics-server   1/1     1            1           4s
```
### Deploy Kubernetes Dashboard
The command below will schedule the resources necessary for the dashboard:
```
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
```
Create a proxy server that will allow you to navigate to the dashboard from the browser on your local machine. This will continue running until you stop the process by pressing ```CTRL + C```.
```
$ kubectl proxy
```
You should be able to access the Kubernetes dashboard [here](http://127.0.0.1:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/) - (http://127.0.0.1:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/)

<img width="1133" alt="Screenshot 2022-05-17 at 10 52 24" src="https://user-images.githubusercontent.com/65422273/168780841-63183673-6a99-49ff-9fbe-fa08393fd2eb.png">

## Authenticate the dashboard
To use the Kubernetes dashboard, you need to create a ```ClusterRoleBinding``` and provide an authorization token. This gives the cluster-admin permission to access the kubernetes-dashboard. Authenticating using kubeconfig is not an option. You can read more about it in the [Kubernetes documentation](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/#accessing-the-dashboard-ui).

In another terminal (do not close the kubectl proxy process), create the ClusterRoleBinding resource by going to ```eks-cluster/kubernetes-dashboard-admin``` and running the command:
```
$ kubectl apply -f kubernetes-dashboard-admin.rbac.yaml
```
Generate the authorization token:
```
$ kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep service-controller-token | awk '{print $1}')
```

Select "Token" on the Dashboard UI then copy and paste the entire token you generated into the [dashboard authentication](http://127.0.0.1:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/) screen to sign in. 

<img width="1097" alt="Screenshot 2022-05-17 at 10 53 29" src="https://user-images.githubusercontent.com/65422273/168779854-a65aa199-b3b9-481b-a0c8-89df500dc3aa.png">

Navigate to the "Cluster" page by clicking on "Cluster" in the left navigation bar. You should see a list of nodes in your cluster.

<img width="1782" alt="Screenshot 2022-05-17 at 10 54 05" src="https://user-images.githubusercontent.com/65422273/168779842-7a126be0-8e74-49a7-96b8-945faaacf8d0.png">

## Installing Sock-Shop on Kubernetes

Go to main directory(```techtask-eks/```) and run:
```
kubectl apply -f sock-shop-app/complete-demo.yaml
```
Verify that the application has been deployed. If successful, you should see something like this:
```
$ kubectl get deployment -n sock-shop
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
carts          1/1     1            1           3d5h
carts-db       1/1     1            1           3d5h
catalogue      1/1     1            1           3d5h
catalogue-db   1/1     1            1           3d5h
front-end      1/1     1            1           3d5h
orders         1/1     1            1           3d5h
orders-db      1/1     1            1           3d5h
payment        1/1     1            1           3d5h
queue-master   1/1     1            1           3d5h
rabbitmq       1/1     1            1           3d5h
session-db     1/1     1            1           3d5h
shipping       1/1     1            1           3d5h
user           1/1     1            1           3d5h
user-db        1/1     1            1           3d5h
```
To access and test the application's front-end service in the local browser run:
```
$ kubectl port-forward service/front-end -n sock-shop 8080:80
```
You should now have access to the service [here](http:/localhost:8080/) (http://localhost:8080/).

## Monitoring Using Prometheus Operator
[Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator) provides a simple and Kubernetes native way to deploy and configure a Prometheus server

To keep Prometheus resources isolated, we should use a separate namespace monitoring to deploy the Prometheus operator and respective resource:
```
$ kubectl create ns monitoring
```
### Install Prometheus Stack
At first, you have to install Prometheus operator in your cluster. In this section, we are going to install Prometheus operator from ```prometheus-community/kube-prometheus-stack```.

### Get Helm Repository Info
Add necessary helm repositories:
```
$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
$ helm repo update
```
### Install kube-prometheus-stack chart:
```
$ helm install -f helm-charts/kube-prometheus-stack/values.yaml prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring
```
This chart will install ```prometheus-operator/prometheus-operator```, ```kubernetes/kube-state-metrics```, ```prometheus/node_exporter```, and ```grafana/grafana``` etc.

The above chart will also deploy a Prometheus server. Verify that the Prometheus server has been deployed by running the following command:
```
$ kubectl get prometheus -n monitoring
NAME                                    VERSION   REPLICAS   AGE
prometheus-stack-kube-prom-prometheus   v2.35.0   1          47h
```
A service for the Prometheus server so that we can access the Prometheus Web UI has albo been created. To verify it run:
```
$ kubectl get service -n monitoring
NAME                                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
alertmanager-operated                       ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP   2d
prometheus-operated                         ClusterIP   None             <none>        9090/TCP                     2d
prometheus-stack-grafana                    ClusterIP   172.20.70.192    <none>        80/TCP                       2d
prometheus-stack-kube-prom-alertmanager     ClusterIP   172.20.6.184     <none>        9093/TCP                     2d
prometheus-stack-kube-prom-operator         ClusterIP   172.20.153.178   <none>        443/TCP                      2d
prometheus-stack-kube-prom-prometheus       ClusterIP   172.20.125.16    <none>        9090/TCP                     2d
prometheus-stack-kube-state-metrics         ClusterIP   172.20.75.90     <none>        8080/TCP                     2d
prometheus-stack-prometheus-node-exporter   ClusterIP   172.20.67.21     <none>        9100/TCP                     2d
```
### Add service monitors for Sock-shop app
To create service monitors needed to enable Prometheus the ability to scrape metrics from certain Sock-shop services, go to ```sock-shop-app``` directory and run:
```
kubectl apply -f service-monitors-complete.yml -n monitoring
```
### Verify Monitoring
To access the Prometheus web UI, we need to forward port of ```prometheus-stack-kube-prom-prometheus``` service. Run the following command on a separate terminal:
```
$ kubectl port-forward -n monitoring service/prometheus-stack-kube-prom-prometheus 9090:9090
```

Now, you can access the Web UI [here](http://localhost:9090) - (http://localhost:9090). 

To access Grafana web UI, we need to forward port of ```prometheus-stack-kube-prom-grafana``` service. Run the following command on a separate terminal:
```
$ kubectl port-forward -n monitoring service/prometheus-stack-grafana 3000:80
```

Now, you can access the Web UI [here](http://localhost:3000) - (http://localhost:3000).

To login into Grafana use Username: ```admin``` and Password: ```prom-operator```.

### Cleanup
To cleanup the Kubernetes resources and the namespace created above run:
```
$ helm delete prometheus-stack -n monitoring
$ kubectl delete ns monitoring
```
## Clean up your workspace

To destroy all the resources created in the previous steps go to ```eks-cluster``` and run:
```
$ terraform destroy
```
Then, go to ```remote-state``` directory and run: 
```
$ terraform destroy
```

## Things to improve
- Add Grafana dashboards visualising the Sock-shop app's performance
- Add exporters for Sock-shop's db services e.g. rabbitmq as the provided version does not expose metrics.
- Add alerting e.g mail, slack.
- Find the reason why app's targets in Prometheus are duplicated
- Add log management e.g ELK stack
- Terraform code
- Introduce more automation to the set-up e.g scripts 
- Remove uneccessary dashboards, targets etc that come with kube-prometheus-stack - overall focusing more on customization

