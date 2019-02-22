Central Logging Stack
=========

This document describes the components chosen for a central logging stack,
explains how to deploy it in a Kubernetes cluster, gives some tips for configure it, 
and provides some examples of usage.


Table of contents
=================

<!--ts-->
   * [Intro](#central-logging-stack)
   * [Table of contents](#table-of-contents)
   * [Components](#components)
     * [FluentD](#fluentd)
     * [Graylog server](#graylog-server)
     * [Elasticsearch](#elasticsearch)
   * [Deployment](#deployment)
   * [Configuration](#configuration)
   * [Usage](#usage)
<!--te-->


Components
============

This stack is composed by several components which facilitate the task of shipping logs (FluentD), receiving,
processing & querying logs (Graylog server), and storing logs (Elasticsearch).

FluentD
-------
[FluentD](https://www.fluentd.org/) is an opensource data collector that reads logs for containers and ships them to Graylog. 
In order to be able to read all the container logs, FluentD is deployed using a DaemonSet which will create
a pod running in each node of the cluster. 

The process inside the container is running as a privileged process 
(UID 0) in order to be able to read the logs from the different containers. The logs of each pod are located 
in `/var/log/containers/*.log` and contain the respective STDOUT and STDERR from the containers running inside the 
pod.

FluentD creates a state file per each logfile that is following, annotating the line where it's currently pointing,
so in case the process is restarted, or the Graylog server is unavailable, once FluentD can continue shipping logs
it will do it from the point where it stopped.

The Docker container used is maintained by the Fluent developer team in 
[fluent/fluentd-kubernetes-daemonset](https://github.com/fluent/fluentd-kubernetes-daemonset).


Graylog
--------------

[Graylog](https://www.graylog.org/) is an opensource centralized log management solution which takes care of capturing logs,
processing them, and exposing them for real time analysis.

What Graylog really does? Graylog does mainly 3 important things: receives logs, enriches logs and exposes a UI where
one can browse logs and do more fancy things, more on the UI later. 
What Graylog doesn't do is storing logs, after reception and processing they are stored in Elasticsearch.

**Receiving logs:** For receiving logs, Graylog can act as a Syslog server. But that's not all, it supports many different inputs: from GELF 
(an extended version of syslog which can handle multiline logs like stacktraces) to Kafka or RabbitMQ. This means that
you have a lot of flexibility in how to ship logs to it.

**Enriching logs:** Enriching logs is a key feature of Graylog, because it helps for later search, and for better debugging. Here are two 
examples of how can you use Graylog to enrich logs: 
 - You are receiving logs from NGINX, and due to privacy constrains, the IPs have to be hidden. You can instruct Graylog
   into applying a hash function to a certain log field, like the IP. Doing this you will still be able to properly debug
   problems without violating data protection rules.
 - You are receiving logs from containers running on Kubernetes and you want to create new fields containing metadata about 
   the running container like container_name. So later you can search for logs from a specific application. Since the information is already in 
   the log line but is unstructured, you can apply a splitting function to the specific input which receives Kubernetes logs.

**Browsing and segmenting logs:** The last key component of Graylog is the UI. It is very clean and makes it easy to search through the logs and find problems which
otherwise will remain unnoticed, effectively giving you more confidence in your systems.  
Using the UI, an administrator can configure "Streams". An stream is a sort of virtual container which contains the log messages
matching a specific set of rules. For example one can create a Stream containing all the logs from a specific application, or 
a Stream containing all the messages having the word Error on them. The streams are virtual because even if a message appears in two streams, 
there's no duplication of messages in Elasticsearch.  
Other cool thing of Streams is that you can give a user access to a certain set of Streams, so for example you could give
access to logs from Application A to the developers of that application, while not giving access to other application logs 
or systems logs.  
The last very cool feature os Streams is that they have Outputs. You can configure the stream to perform an action based on 
messages in that stream, this is very useful for monitoring.
Continuing with the example before where there was a Stream containing all the messages with the keyword "Error", an Output
rule can be configured saying that if the stream is receiving more than 5 messages/second, it will send a message to a slack 
channel informing about that. Ouputs are very configurable, they can call webhooks, send emails...

*Note: Graylog uses MongoDB for storing its internal configuration, but it doesn't put any logs on it. Having external
database for storing configuration enables Graylog to have a distributed master/slave setup. At the moment of writing this,
the database has a size of less than 1MB.*


Elasticsearch
-------------

[Elasticsearch](https://www.elastic.co/) is a opensource tool for storing and searching documents, mainly used for log 
collection.
In this setup, Elasticsearch is used as a backend of Graylog for actually storing messages. We are using the Elasticsearch as
a service service provided by AWS, however any cluster running ES<6 can be plugged in.



Deployment
============

Deploying the stack is as simple as running `kubectl apply -f *` in this directory. The files are sorted depending on their dependencies,
so `00-namespace.yml` will create the `logging` namespace where the components will be deployed and so on.
 
The proposed Graylog setup includes only one Graylog server acting as master, because for the moment one single master is
able to process all the logs in the cluster. However it can be horizontally scaled adding more Graylog instances as Slaves,
so the log processing will be shared among the cluster instances. Master and Slaves should point to the same MongoDB and Elasticsearch
instances. 


Configuration
============

In order to start using the stack, there are a few things which have to be configured in Graylog manually.  
First of all, Inputs have to be created and started. This is a very simple process which has to be done in the UI, 
`System->Inputs` where the type of Input (Syslog UDP, Syslog TCP, GELF,
Kafka...) has to be chosen. After, select which nodes will be receiving the input, and finally click "Start input". Once this is done, FluentD should be pointed to the choosen endpoint in order to start sending logs.
In case you haven't done it yet, you also have to specify the address of Elasticsearch and MongoDB in `05-graylog-config.yml`.

That's it, now you can start creating streams, outputs, roles and users.

In order to send Graylog alerts to Slack, in the UI `System / Outputs -> Outputs`  Choose `Slack Output` from the dropdown and click the `Launch new output` button.  In Slack, create a new App and corresponding Incoming Webhook, this will give you a URL which you will enter in the Webhook URL field in Graylog. Also enter the Channel to send to.


Usage
============

Graylog is running inside the Kubernetes cluster and it doesn't have a public endpoint. In order to browse the UI you have to
forward the port from the cluster to your local machine (this might change in the future). Also, sometimes is needed to have
an entry in your `/etc/hosts` mapping localhost to the Graylog URL. You can do ti running
```bash 
sudo /bin/sh -c "echo '127.0.0.1 graylog-master.logging.svc.cluster.local' >> /etc/hosts"

POD=$(kubectl get pods -n=logging | awk '/graylog-master/ { print $1}')
kubectl port-forward -n=logging "$POD" 9000:9000`
```
Now, open Firefox and go to `localhost:9000` where you will be prompted by the logging form.
Moving forward, Graylog will be behind Auth0, but for the moment if you want to have a user in there, please create a Github Issue in this repository.
 


