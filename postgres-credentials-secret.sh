#!/usr/bin/env bash

APP_NAME=$1

kubectl create secret generic ${APP_NAME}-credentials \
          -n postgres \
          --from-literal=username=${APP_NAME} \
          --from-literal=password=${openssl rand -base64 16}
kubectl get secret ${APP_NAME}-credentials -n postgres -o yaml \
          | sed "s/namespace: postgres/namespace: ${APP_NAME}/" \
          | kubectl apply -f -
