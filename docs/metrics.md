# Monitoring in Kubernetes

This folder contains the Kubernetes resources required for deploying a complete monitoring stack.

It uses the [Prometheus Operator](https://coreos.com/operators/prometheus/docs/latest/) by CoreOS for deploying managed Prometheus instances and AlertManagers. It also contains a [Grafana](https://grafana.com/) instance preconfigured with your previously deployed Prometheus instance as a Datasource and a few dashboards showing cluster level metrics.

## Deploying the stack into a Kubernetes cluster

In order to deploy the stack you just have to apply all the files to Kubernetes. Each component is defined in its own file, alphabetically sorted to match dependencies between them. 

### Prerequisites

kubectl must be correctly setup to talk to your cluster and you will need priviledges for creating a ClusterRole, ClusterRoleBinding, a Namespace and resources in it.

### Deploying

In order to deploy the stack you have to run the enxt command from this directory

```
kubectl apply --recursive=true -f .
```

If everything went good, you should be able to see a prometheus and a prometheus-operator pod in the monitoring namespace:

```
kubectl get pods --namespace=monitoring
NAME                                   READY     STATUS        RESTARTS   AGE
prometheus-operator-78cc99d846-k2jcx   1/1       Running       0          1m
prometheus-prometheus-general-0        3/3       Running       1          46s

```

## Monitoring your application

In order to make Prometheus scrape the metrics of your application, you need to have a Service resource exposing your Pods. After that you have to create a ServiceMonitor object which will be discovered by Prometheus and will start the metrics collection. The ServiceMonitor object must select your service or services using matchers.
The next example will create a ServiceMonitor called example-app inside monitoring namespace, wich will fetch metrics from the pods in the Service with the label "app: app-example", scraping them in the port named "web".

```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: example-app
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: example-app
  endpoints:
  - port: web
```

In order to validate that Prometheus is correctly scraping your pods, you can check the "Targets" section in the Prometheus UI and verify that all your pods are listed and are green.
You can browse Prometheus doing `kubectl port-forward prometheus-prometheus-general-0 9090:9090` and visiting http://127.0.0.1:9090. Once there you can query Prometheus or check if your application is correctly scrapped clicking in Status -> Targets. There you should see your ServiceMonitor definition and all your pods in green.

