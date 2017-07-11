# aws-ecs-task-deployer

This script updates the ECS Service with a new Container Image version.

1. Get the running ECS Task of the ECS Service given.
2. Get the JSON from the current TASK defined.
3. Creates a new Revision modifying the version of the container defined.
4. Update the ECS service with the new Task revision.

## Dependencies:

You have to istall `jq` and `/bin/bash`.

## Use it in your pipeline

export CLUSTER="your_cluster_name" \
   && export SERVICE="your_service_name"  \
   && export AWS_DEFAULT_REGION="eu-west-1" \
   && export CONTAINER_NAMES_REGEX='web-app' \
   && export DOCKER_NEW_IMG_TAG=`git log --pretty=format:'%h' -n 1`
   && /bin/bash ./update-task.sh

## Usage example:

1. The new `$DOCKER_NEW_IMG_TAG` to replace.
2. the `$CLUSTER` name.
3. The `$SERVICE` name of the $CLUSTER.
4. The `$AWS_DEFAULT_REGION`.
5. The `$CONTAINER_NAMES_REGEX` is the Container Name in the task definition eg: `nginx`.
If you want to update two Containers' version in the same Task 
fill it with the regex style `IMAGE_REGEX=nginx|php`.

## How to update ECS TASK with AWS CodePipeline?

We are used to integrate the deploy as a single AWS Code-Build step.

In the previous step you can push to ECR the new image and create an artifact with the new TAG version like 

``` 
#buildspec.yml
...
  post_build:
    commands:
      - export $DOCKER_NEW_IMG_TAG=`git log --pretty=format:'%h' -n 1`
      - docker build -t $DOCKER_REGISTRY/$DOCKER_REPO_NAME:$DOCKER_NEW_IMG_TAG .
      - docker push $DOCKER_REGISTRY/$DOCKER_REPO_NAME:$DOCKER_NEW_IMG_TAG
      - echo $DOCKER_NEW_IMG_TAG > ARTIFACT
artifacts:
  files:
    - ARTIFACT
  discard-paths: yes
```

In the deploy step you can create an AWS Code-Build on Ubuntu, getting the new tag version already pushed to ECR via artifact:

```
apt-get update -y && apt-get install -y jq \
 && read DOCKER_NEW_IMG_TAG < ARTIFACT && echo $NEW_VERSION \
 && /bin/bash ./update-task.sh
```

## How to update ECS Service with AWS CodeBuild?

The best way is to use it with the (buildspec.yml)[./buildspec.yml] in the files.

