# EKS cluster management

This document provides an overview of our CI/CD pipeline and an example to help you setup your first deployment pipeline to your new EKS cluster.

See the [README](/README.md) for related documents.

# Table of Contents

- [Introduction](#toc-introduction)
- [Overview](#toc-overview)
  - [CloudFormation](#toc-cloudformation)
  - [Build and deployment steps](#toc-build-and-deploy)
- [Creating a deployment pipeline](#toc-first-pipeline)
  - [Create the pipeline](#toc-codepipeline-resources)
  - [The build stage](#toc-build)
  - [The deployment stage](#toc-deploy)

# <a id="toc-introduction"></a>Introduction

Today, this document will provide manual steps required to setup a new CodePipeline and CodeBuild project through the AWS console. Future iterations will move toward programmatic creation of these resources.

# <a id="toc-overview"></a>Overview

## <a id="toc-cloudformation"></a>CloudFormation

I have not completed the CloudFormation required for this work. In the future, the project will be found [here](https://github.com/mozilla-iam/aws-codepipeline-cloudformation).

## <a id="toc-build-and-deploy"></a>Build and deployment steps

A complete build and deployment process will provide us with:

- A `buildspec.yml` like [this](https://github.com/mozilla/mozmoderator/blob/helm-example/buildspec.yml) which builds the Docker image for the application, logs into ECR, tags and pushes the image to ECR
- An [addition build step](https://github.com/mozilla-iam/aws-codepipeline-cloudformation/issues/3#issuecomment-395279934) in a `buildspec.yml` which scans the Docker image with Clair before allowing CodeBuild to push the new image to ECR
- Once the new container image is available in ECR, we can manually update the container image that the pod uses with `kubectl`

In the future, the manual deployment phase can be replaced by a CodeBuild job, a Lambda function or a Kubernetes operator like [weaveworks/flux](https://github.com/weaveworks/flux) to poll for changes to the GitHub repository and update the cluster.

# <a id="toc-first-pipeline"></a>Creating a deployment pipeline

## <a id="toc-codepipeline-resources"></a>Create the pipeline

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

## <a id="toc-build"></a>The build stage

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

## <a id="toc-deploy"></a> The deployment stage

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

Once you apply with `kubectl apply -f test-eks-pod.yaml`, you'll have this pod running in your Kubernetes cluster. If you push a change to your source repository, wait for the build to complete and update this to reflect a new container image tag, you can `kubectl apply` again to update to the new iamge.