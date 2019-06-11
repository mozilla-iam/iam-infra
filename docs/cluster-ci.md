# Deploying applications to the cluster

This document provides an overview of our CI/CD pipeline and an example to help you setup your first deployment pipeline to your new EKS cluster.

See the [README](/README.md) for related documents.

# Table of Contents

- [Introduction](#toc-introduction)
- [Overview](#toc-overview)
  - [Build and deployment steps](#toc-build-and-deploy)
- [Creating a deployment pipeline using Terraform (preferred)](#toc-pipeline-terraform)
  - [Create the pipeline](#toc-template-terraform)
  - [The build stage](#toc-build-terraform)
  - [The deployment stage](#toc-deploy-console)
- [Creating a deployment pipeline using AWS console](#toc-first-pipeline-console)
  - [Create the pipeline](#toc-codepipeline-resources-console)
  - [The build stage](#toc-build-console)
  - [The deployment stage](#toc-deploy-console)

# <a id="toc-introduction"></a>Introduction

This document explains two supported ways of creating a CodePipeline and CodeBuild project for deploying your code to Kubernetes. The first supported method is "automatic" and consists in using a Terraform template to create your AWS resource. The second method "manual" uses the AWS console. We really encourage you to use the first method, contacting us for any kind of problem you experience. PRs to the terraform template as well as to this document are welcome.

# <a id="toc-overview"></a>Overview

## <a id="toc-build-and-deploy"></a>Build and deploy
After following this guide, you will have created:
- An AWS CodeBuild job which will run your `buildspec-k8s.yml`.
- A webhook enabling automatic builds for selected branches. Note: for this to work AWS has to be able to access your Github repo with OAuth credentials.
- A new Docker repository hosting your containers.
- An IAM role with the right permissions to do all its magic.
- An ARN of the IAM role for getting access to deploy into the cluster

In order to create a Pipeline, all you need is:
- A project to build, preferrably in Github.
- A `buildspec-k8s.yml` like [this](https://github.com/mozilla/mozmoderator/blob/helm-example/buildspec.yml) which builds the Docker image for the application, logs into ECR, tags and pushes the image to ECR
- Terraform configured to make changes to the IAM AWS account. If you don't have the right permissions, you always can create a PR with the right configuration, and one of the cluster adminitrators will deploy your changes for you.

# <a id="toc-pipeline-terraform"></a>Creating a deployment pipeline using Terraform (preferred)
This section will walk you through the steps needed for deploying your project into one of our Kubernetes clusters.

## <a id="toc-template-terraform"></a>Create the pipeline
In this section your are going to be using Terraform code to define the AWS resources needed to roll out your own pipeline for building a container and storing it in a Docker repository. Don't worry if you have never used Terraform before, we have prepared a template where you only will have to modify few variables to get it done.

1. Clone this repository and create a new branch.
2. Inside the repository change directory to the codebuild root: `cd infrastructure/global/codebuild`
3. Copy the template directory using the same name that your project, and change directory to it: `cp -r template my-project && cd my-project`
4. Set the path for your Terraform shared state file running (use your real project's name): `export PROJECT_NAME=my-project && sed -i -e "s/template/$PROJECT_NAME/g" provider.tf`. This can't be done using variables interpolation in Terraform because the state is loaded in a very early stage of the Terraform run, when variables are unknown.
5. Modify the variables.tf:
  * Change the field "default" in "project_name" with your project's name.
  * Add the address of your github repository to "github_repo".
  * Modify "deploy_environment" to choose if deploying to the production or staging/development cluster.
  * If you want to customize the image used for building your project, change the value of "build_image"
  * If your buildspec is not named buildspec-k8s.yml, you can reflect it in "buildspec"
  * If you want to deploy a Webhook for automatically build on push to a branch, write in "github_branch" a regular expression matching those branch names. You also have to uncomment the "aws_codebuild_webhook" in main.tf and give AWS access to your Github account.
6. Run `terraform init` in order to initialize your state. Do this only one time.
7. Run `terraform plan` and check that only new resources are going to be created, no modify, no destroy.
8. Run `terraform apply` to create the resources. This operation should take 2 to 3 minutes.
9. After successfully finishing, Terraform will output the ARN of the new user and the URL of the new container registry. Copy this, you will need it later.

## <a id="toc-build-terraform"></a>The build stage
Now that you have created all the AWS components needed for deploying your project, you have to write a buildspec-k8s.yml file. This file contains the instructions for telling CodeBuild how to build and deploy your project.
The steps here are highly dependent on your project: language, tests, artifact to generate... Thus, we are providing few working examples as well as a link to the AWS reference page where you can check all the possible options. The only thing to take into account is to use the URL of the container registry created before. This URL can be optained at anytime running `terraform output`.
1. [Minimal example](https://github.com/The-smooth-operator/test-deployment-pipeline/blob/master/buildspec-k8s.yml) on how to build a container, push it to ECR and deploy it as a service in Kubernetes.
2. [Another example](https://github.com/mozilla-iam/sso-dashboard/blob/master/buildspec-k8s.yml) of a Buildspec file using Helm for rendering Kubernetes manifests.
3. [More complex example](https://github.com/mozilla-iam/dino-park-fence/blob/master/buildspec.yml) using the [Myke task manager](https://github.com/goeuro/myke) and Helm for rendering Kubernetes manifests.

## <a id="toc-deploy"></a> The deployment stage
Now that you have created the AWS resources, and writed your builspec for packing your app and pushing it to a container registry, the last piece is to get this container running into the Kubernetes cluster.
In order to allow your CodeBuild job to talk to the Kubernetes cluster, the user running this job has to be explicitely allowed to do so. This is an easy manual process for a cluster operator. However at the moment due to the AWS EKS implementation is difficult to automate. We will revisit this in the future.
So, please open an Issue in this repository specifying the ARN of the user (you got it in the last Terraform step) and which namespaces should be able to deploy into. As fast as we can we will grant the user permissions to do so.
If you are a cluster admin, you can do it yourself following [this section.](https://github.com/mozilla-iam/iam-infra/blob/master/docs/kubernetes-administration.md#toc-allow-codebuild)

# <a id="toc-pipeline-console"></a>Creating a deployment pipeline using AWS Console

## <a id="toc-codepipeline-resources-console"></a>Create the pipeline

With the instructions below, AWS will request access to your GitHub project. It will use this access to automatically add a webhook to your project which will trigger the CodePipeline to run.

As a prerequisite, you must have a GitHub repository available with a `Dockerfile` checked in. This will build the container that we run in Kubernetes.

1. Select the region where your EKS cluster has been created
2. Open [CodePipeline](https://us-west-2.console.aws.amazon.com/codepipeline/home?region=us-west-2#/dashboard) under "Services / Developer Tools / CodePipeline"
3. Click "Create Pipeline"
4. Provide a pipeline name like `myTestCodePipelineForEKS`
5. Select GitHub as the source provider
6. Click "Connect to GitHub" and approve access
7. Select your repository and branch
8. Click "Next step"
9. Specify "AWS CodeBuild" as your build provider
10. Under "Configure your project" select "Create a new build project"
11. Set a project name like `myTestCodeBuildForEKS`
12. For "Environment image", use "Use an image managed by AWS CodeBuild"
13. For "Operating system", use "Ubuntu"
14. For "Runtime", use "Docker"
15. For "Version", use what is available
16. For "Build specification", use "Use the buildspec.yml in the source code root directory"
17. Cache type can default to "No cache"
18. For the "AWS CodeBuild service role", use "Create a service role in your account"
19. For "VPC ID", use the default of "No VPC"
20. Select "Save build project"
21. Click "Next step" if there are no errors
22. For "Deployment provider", use "No Deployment"
23. Click "Next step"
24. For "Role name" under "AWS Service Role", I have used a role available to me called "AWS-CodePipeline-Service"
25. Review your pipeline and click "Create pipeline"

Once complete, you will be presented with your pipeline. The "Source" stage will trigger automatically and result in a success if your repository exists. The Build stage will fail if you have not created a `buildspec.yml`. That will be done in the next section.

## <a id="toc-build-console"></a>The build stage

In order to complete a build, you need an ECR repository to push the Docker image. Create a new ECR repository like this:

1. Open [Amazon ECR](https://us-west-2.console.aws.amazon.com/ecs/home?region=us-west-2#/repositories) in the region where your EKS cluster was created. This can be found in "Services / Computer / Elastic Container Service / Amazon ECR / Repositories"
2. Click "Create repository"
3. Specify a repository name like `test-eks`
4. Make a note of the "Build, tag, and push Docker image" instructions and click "Done"
5. Select the "Permissions" tab and click "Add"
6. Enter "codebuild.amazonaws.com" under "Principal", select the CodeBuild service role you used for your CodeBuild job. Under "All IAM entities", click ">> Add" and select "All actions" under "Action". This can be more carefully scoped if you take care to find the right options
7. Select "Save all" at the top

Take the push commands you noted earlier and create a `buildspec.yml` that looks like the following. If you missed these commands, you can visit your ECR repository and click "View Push Commands".

Example `buildspec.yml`:

```yaml
version: 0.1

phases:
  build:
    commands:
      - echo Build started on `date`
      - ACCOUNT_ID=`aws sts get-caller-identity --output text --query 'Account'`
      - REPOSITORY_URI=${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${YOUR_REPO_NAME}
      - aws ecr get-login --region ${AWS_REGION} --no-include-email | bash
      - docker build -t ${YOUR_REPO_NAME} .
      - docker tag redirector ${REPOSITORY_URI}:${CODEBUILD_SOURCE_VERSION}
      - docker push ${REPOSITORY_URI}:${CODEBUILD_SOURCE_VERSION}
  post_build:
    commands:
      - echo Build completed on `date`
```

In this example, `CODEBUILD_SOURCE_VERSION`, is an environment variable that is set in the CodeBuild environment. You can see a list of all environment variables in the [documentation](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-env-vars.html). `AWS_REGION` will provide the region that your CodeBuild job is running.

Once you have replaced all of the variables, except `CODEBUILD_SOURCE_VERSION`, you can push this `buildspec.yml` to your repository. This will trigger the CodePipeline job to start and you can troubleshoot any build failures if there are errors.

If you are successful, changes to the GitHub repository will result in new container images being pushed to ECR and tagged with the corresponding GitHub commit SHA.

## <a id="toc-deploy-console"></a> The deployment stage

You can manually test deployments by creating a new pod with a YAML like this:

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: eks-test
  labels:
    app: web
spec:
  containers:
    - name: eks-test
      image: ${ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/test-eks:v1
      ports:
        - containerPort: 88
```

Once you apply with `kubectl apply -f test-eks-pod.yaml`, you'll have this pod running in your Kubernetes cluster. If you push a change to your source repository, wait for the build to complete and update this to reflect a new container image tag, you can `kubectl apply` again to update to the new image.

