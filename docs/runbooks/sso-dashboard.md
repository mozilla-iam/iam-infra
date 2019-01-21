# SSO Dashboard Runbook

# Table of Contents

- [Introduction](#toc-introduction)
- [Overview](#toc-overview)
  - [Service owner and SLA](#toc-service-owner)
  - [AWS account resources](#toc-aws-resources)
  - [Build and deployment steps](#toc-build-and-deploy)
  - [DNS](#toc-dns)
  - [Monitoring](#toc-monitoring)
  - [Links](#toc-links)
- [How to deploy](#toc-howto-deploy)
  - [Helm template rendering](#toc-helm-template)
  - [Apply with kubectl](#toc-kubectl-apply)
- [Troubleshooting](#toc-troubleshooting)
  - [CI/CD](#toc-troubleshooting-cicd)
  - [Networking](#toc-troubleshooting-networking)
  - [Kubernetes deployment](#toc-troubleshooting-deployment)

# <a id="toc-introduction"></a>Introduction

This runbook is meant to provide an overview of the SSO Dashboard deployment, steps to re-deploy and troubleshooting steps if a problem occurs.

The SSO Dashboard production site can be found at https://sso.mozilla.com/. The staging site can be found at https://sso.allizom.org/.

# <a id="toc-overview"></a>Overview

## <a id="toc-service-owner"></a>Service owner and SLA

The service owner is Andrew Krug. An SLA still needs to be agreed upon for this service. Until that is done, we should do our best to keep it up and running as often as we can and work to resolve issues quickly. The website is used by all Mozillians to access sites and services that they need every day.

## <a id="toc-aws-resources"></a>AWS account resources

The SSO Dashboard spans three different AWS accounts. The staging and production website is deployed to the mozilla-iam AWS account. The pod needs to assume an AWS role in an InfoSec prod and InfoSec dev AWS account in order to access resources like DynamoDB. In the future, everything should be moved into the mozilla-iam account but right now we are spread across all three accounts. Andrew can provide access to the InfoSec accounts if it is needed.

## <a id="toc-build-and-deploy"></a>Build and deployment steps

We use CodeBuild to track changes in the project's GitHub repository:

https://github.com/mozilla-iam/sso-dashboard

If a change is pushed to the master or production branches, CodeBuild will use the `buildspec-k8s.yml` file in the source repository to build and deploy a new container image.

A push to the master branch will deploy to the staging environment. A push to the production branch will deploy to the production environment.

We have two namespaces in Kubernetes:

- sso-dashboard-staging
- sso-dashboard-prod

This is how we separate the environments.

## <a id="toc-dns"></a>DNS

DNS is currently managed manually in the mozilla-iam account. The sso.mozilla.com and sso.allizom.org addresses should be an alias record set which points to the ELB address for the Kubernetes ingress controller.

This ELB address can be found in the `ingress-nginx` namespace: `kubectl get svc/ingress-nginx -n ingress-nginx`.

I will elaborate more on this in the networking section. You just need to know that the traffic gets routed to the ingress controller and then each environment has a specific ingress resource to route traffic to the appropriate services.

## <a id="toc-monitoring"></a>Monitoring

From the MOC [New Relic](https://synthetics.newrelic.com/) sub-account, you can access the two active Synthetics monitors.

## <a id="toc-links"></a>Links

- [Source repository](https://github.com/mozilla-iam/sso-dashboard)
- [Helm template for deployment](https://github.com/mozilla-iam/sso-dashboard/tree/master/k8s)
- [Buildspec for CodeBuild](https://github.com/mozilla-iam/sso-dashboard/blob/master/buildspec-k8s.yml)

# <a id="toc-howto-deploy"></a>How to deploy

You should review the `buildspec.yml` first. If any changes are made, this documentation may end up out of date.

## <a id="toc-helm-template"></a>Helm template rendering

Helm template rendering will require that you have `helm` installed. With that, you can run the following to render the Kubernetes YAML:

`helm template -f k8s/values.yaml -f k8s/values/${DEPLOY_ENV}.yaml --set registry=${DOCKER_REPO},namespace=sso-dashboard-${DEPLOY_ENV},rev=${COMMIT_SHA},assume_role=${ASSUME_ROLE_ARN} k8s/ | kubectl apply -f -`

There are some environment variables that you will have to override here:

- DEPLOY_ENV will depend on where you need to deploy this. The options are available in the `k8s/values/` folder. You should find dev, staging and prod
- The DOCKER_REPO can be found in the CodeBuild job environment configuration
- The commit SHA should match the tag of the container image that you want to deploy. These can be seen in AWS ECR if you need to look it up
- The ASSUME_ROLE_ARN can be found in the InfoSec account corresponding to the deployment (dev or prod). I keep these ARNs in Parameter Store in the mozilla-iam account and you can look them up there

## <a id="toc-kubectl-apply"></a>Apply with kubectl

Once the Helm template rendering is working, you can pipe the output to `kubectl apply -f -`. Here is an example:

`helm template -f k8s/values.yaml -f k8s/values/staging.yaml... | kubectl apply -f -`

You can also write the output to a file if you would prefer.

# <a id="toc-troubleshooting"></a>Troubleshooting

## <a id="toc-troubleshooting-cicd"></a>CI/CD

When you access the CodeBuild service in AWs, you can review the state of a specific job. Search for the SSO dashboard and then review the job history until you find a failed job. The console output will show you what specific error was encountered.

If CodeBuild jobs are not being triggered, you will want to work with an admin for the SSO dashboard project to open the repository settings and review the webhook configuration. You will see a webhook for CodeBuild and you can review the configuration and previous webhook payloads.

## <a id="toc-troubleshooting-networking"></a>Networking

The network configuration is not easy to reason through if you are not familiar with Kubernetes so I want to make a note about that here. As I mentioned in the DNS section above, the DNS records for the site will be alias records that point to the ELB for the ingress controller in the cluster.

You want to validate that this address is correct by comparing the Route 53 configuration with the output of `kubectl get svc/ingress-nginx -n ingress-nginx`. If it needs to be changed, Route 53 records are currently managed manually so you can do it from the AWS console or CLI.

If this is configured correctly, you will want to check the ingress resource for the service. The YAML is available in the Helm template output. You can also use kubectl get to get it via `kubectl get ingress/sso-dashboard -n sso-dashboard-staging -o yaml`. You may need to change the namespace environment to prod.

With this, you should review the rules, TLS configuration and any annotations that might modify the Nginx configuration.

```
  spec:
    rules:
    - host: sso.allizom.org
      http:
        paths:
        - backend:
            serviceName: sso-dashboard
            servicePort: 8000
          path: /
    tls:
    - hosts:
      - sso.allizom.org
      secretName: sso-dashboard-secret
```

The rules are fairly simple. You just want to verify that the backend is configured correctly.

If you need more information, it can be helpful to review the output of:

- `kubectl describe ingress/sso-dashboard` to see any possible events that may indicate an issue
- `kubectl get pods -n ingress-nginx` to get the ingress controller pod (nginx-ingress-controller-*) and then use `kubectl logs $POD` to review the Nginx logs for potential issues
- If it is an issue with the TLS certificate, you can use `kubectl get pods -n cert-manager` to get the cert-manager pod and then use `kubectl logs $POD` to review the cert-manager log output

## <a id="toc-troubleshooting-deployment"></a>Kubernetes deployment

Much like the commands above, you can use `kubectl` to get the name of a pod in the staging or prod namespace: `kubectl get pods -n sso-dashboard-prod`. With that, you can use `kubectl logs $POD` to review the log output. This is also captured in Graylog which provides a much nicer environment to review logs.

If pods are being evicted, you should look at the `kubectl describe pod/$POD` output to see if you can get more information about the reason. We have usually found this to be caused by excessive memory utilization by pods. Memory and CPU constraints have been put in place for the SSO dashboard but they may need to be adjusted in the future.

You can use `kubectl describe deployment/sso-dashboard` to review the kube2iam annotations that are set in the pod. I'm not sure what this failure state might look like but if users are unable to login but they are being directed to Auth0, you may want to see if the annotation is correct. If the prod site was deployed with the staging role annotation, that should cause issues.