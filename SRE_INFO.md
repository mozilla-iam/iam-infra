# SRE Info

## Infra Access
Access to the EKS cluster is limited by those who have rights to access the IAM AWS account. At the moment of writing only Eric and Alberto have access to it from SRE team. If you need to access the cluster contact Kang or Andrew. In the future we will have a process for getting this kind of access, the progress is tracked [here](https://jira.mozilla.com/browse/IAM-25)

## Secrets
Secrets are stored in [iam-private](https://github.com/mozilla-it/iam-private/), a private repo using git-crypt

[Private repo with git-crypt guide](https://mana.mozilla.org/wiki/display/SRE/Private+repos+with+git-crypt)

## Source Repos
Infrastructure repo [iam-infra](https://github.com/mozilla-iam/iam-infra)

SSO Dashboard repo [sso-dashboard](https://github.com/mozilla-iam/sso-dashboard)

DinoPark is composed by several microservices, this are the most important:
* [dino-park-fence](https://github.com/mozilla-iam/dino-park-fence) Main microservice
* [dino-park-search](https://github.com/mozilla-iam/dino-park-search) Search functionality
* [dino-park-tree](https://github.com/mozilla-iam/dino-park-tree) Draws the org chart
* [dino-park-fossil](https://github.com/mozilla-iam/dino-park-fossil) Manages pictures
* [dino-park-lookout](https://github.com/mozilla-iam/dino-park-lookout) Updates profiles
* [dino-park-whoami](https://github.com/mozilla-iam/dino-park-whoami) Identity verification


## Monitoring
[Grafana Metrics](https://grafana.infra.iam.mozilla.com)
[Graylog Logs](https://https://graylog.infra.iam.mozilla.com)

## SSL Certificates
All the SSL certificates used by applications in the cluster are issued by Let's Encrypt on request by cert-manager.

[SSL Cert Monitoring](https://metrics.mozilla-itsre.mozit.cloud/d/EsrIYzmWz/traffic?orgId=1)

## Cloud Account
AWS account mozilla-iam 320464205386
