#!/bin/bash
set -e;

if [ -z "$DOCKER_NEW_IMG_TAG" ]; then
    echo "DOCKER_NEW_IMG_TAG not set";
    exit 1;
fi

if [ -z "$SERVICE" ]; then
    echo "Service not set";
    exit 1;
fi
if [ -z "$CLUSTER" ]; then
    echo "CLUSTER not set";
    exit 2;
fi

if [ -z "$AWS_DEFAULT_REGION" ]; then
    echo "AWS_DEFAULT_REGION not set";
    exit 3;
fi
if [ -z "$CONTAINER_NAMES_REGEX" ]; then
    echo "CONTAINER_NAMES_REGEX not set, usage: \'nginx|php\' or \'web\'";
    exit 4;
fi

TASK_DEFINITION_NAME=$(aws ecs describe-services --services $SERVICE --cluster $CLUSTER --region $AWS_DEFAULT_REGION | jq ".services[0].taskDefinition" -r)
TASK_DEFINITION=$(aws ecs describe-task-definition --task-def "$TASK_DEFINITION_NAME" --region $AWS_DEFAULT_REGION  | jq '.taskDefinition')

echo "# Current definition tags" ;
echo $TASK_DEFINITION |  jq "." | grep "image" | sed 's/"image":/#/g' ;

NEW_CONTAINER_DEFINITIONS=$(echo "$TASK_DEFINITION" | jq "." | sed -E 's@\"image\": \"(.*)\/('${CONTAINER_NAMES_REGEX}'):.*\",@\"image\": \"\1\/\2:'${DOCKER_NEW_IMG_TAG}'",@g')

echo "# New definition tags" ;
echo $NEW_CONTAINER_DEFINITIONS | jq "." | grep "image" | sed 's/"image":/#/g' ;

NEW_DEF_JQ_FILTER="family: .family, volumes: .volumes, containerDefinitions: .containerDefinitions, networkMode: .networkMode"
NEW_DEF=$(echo $NEW_CONTAINER_DEFINITIONS | jq "{${NEW_DEF_JQ_FILTER}}")
echo $NEW_DEF;
NEWDEF=`aws ecs register-task-definition --region $AWS_DEFAULT_REGION  --cli-input-json "$NEW_DEF"`
NEW_TASKDEF=$(echo $NEWDEF | jq -r ".taskDefinition.taskDefinitionArn")
aws ecs update-service --cluster $CLUSTER --service $SERVICE --region $AWS_DEFAULT_REGION  --task-definition "$NEW_TASKDEF"

echo "#OK - Service updated " ;
echo '{"task-definition": "'${NEW_TASKDEF}'"}'