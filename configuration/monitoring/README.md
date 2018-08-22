# Monitoring in Kubernetes (WIP)

This folder contains the Kubernetes resources required for deploying a cluster and applications monitoring solution.
It uses the [Prometheus Operator](https://coreos.com/operators/prometheus/docs/latest/) by CoreOS for deploying managed Prometheus instances and AlertManagers. It also deploys a [Grafana](https://grafana.com/) instance preconfigured with your previously deployed Prometheus instance as a Datasource and few basic dashboards.

## Getting Started

Each component is defined in its own file, alphabetically sorted to match dependencies between them. For example 00-namespace.yml will create a namespace in your cluster called "monitoring" where other components are going to live in.

### Prerequisites

kubectl must be correctly setup to talk to your cluster and you will need priviledges for creating a ClusterRole, ClusterRoleBinding, a Namespace and resources in it.

### Deploying

In order to deploy a Prometheus instance ready to monitor your applications you have to:

```
kubectl apply -f 00-namespace.yml -f 10-prometheus-operator.yml
sleep 3
kubectl apply -f 15-prometheus-object.yml
kubectl apply -f 17-node-exporter.yml
```

If everything went good, you should be able to see a prometheus and a prometheus-operator pod in the monitoring namespace:

```
kubectl get pods --namespace=monitoring
NAME                                   READY     STATUS        RESTARTS   AGE
prometheus-operator-78cc99d846-k2jcx   1/1       Running       0          1m
prometheus-prometheus-general-0                3/3       Running       1          46s

```

After that, you might want to deploy a Grafana instance in order to visualize your metrics:

```
kubectl apply -f 20-grafana-dashboardDatasources.yaml -f 20-grafana-dashboardSources.yaml -f 25-grafana-deployment.yaml
```

## Getting metrics for an application

In order to make Prometheus scrape the metrics of your application, you need to have a Service resource defining your Pods. After that you have to create a ServiceMonitor object which will be discovered by Prometheus.
For example the next ServiceMonitor will select Services containing the labels `app: example-app` using the port `web`:

```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: example-app
  labels:
    team: frontend
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: example-app
  endpoints:
  - port: web
```

Now you have to make sure there's a Prometheus object selecting your ServiceMonitor. The next Prometheus objects will select the ServiceMonitor based on the label `team: frontend`

```
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: prometheus-general
  namespace: monitoring
spec:
  serviceAccountName: prometheus
  serviceMonitorNamespaceSelector:
  serviceMonitorSelector:
    matchLabels:
      team: frontend
  resources:
    requests:
      memory: 400Mi
```

You can see which Prometheus objects are running with `kubectl get prometheus`.

The idea behind this setup is to have different Prometheus servers monitoring logical groups of Services, for example all the ones for the frontend team.
To make sure that your application was picked up by a Prometheus instance you can browse the Prometheus UI, go to "Targets" section and find your application there.
You can access Prometheus UI locally running this (with the name of your Prometheus instance) ` kubectl port-forward prometheus-prometheus-general-0 9090:9090`
Now you are ready to start building dashboards in Grafana.



## Customizing

This deployment can be easily customized and adapted to other environments, for example adding specific Prometheus instance for each namespace or group of applications, ServiceMonitors or adding different data sources to Grafana. If you want to modify the environment but you can't find the case in the next lines, feel free to open an issue.

### Prometheus

### Grafana

#### Adding or modifying Datasources:

The configuration of the Datasources can be found in 20-grafana-dashboardDatasources.yaml encoded in base64. You can easily read it running `awk '/prometheus.yaml/ {print $2}' 20-grafana-dashboardDatasources.yaml | base64 -d`. Make the modifications you want, encode it again with `base64` and replace the prometheus.yml part of 20-grafana-dashboardDatasources.yaml.
After that apply it running `kubectl apply -f 20-grafana-dashboardDatasources.yaml` and killing the Grafana container in order to reload the configuration.
