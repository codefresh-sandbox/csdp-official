#!/bin/bash
COMPONENTS="argo-events,app-proxy,argo-cd,events-reporter,argo-rollouts,rollout-reporter,argo-workflows,workflow-reporter,sealed-secrets"
CSDP_RUNTIME_CLUSTER="https://kubernetes.default.svc"

COMPONENT_NAMES=`echo ${COMPONENTS} | tr ',' ' '`
COMPONENTS=""

for COMPONENT in $COMPONENT_NAMES; do
    CUR_COMPONENT=`echo -n "\"csdp-${COMPONENT}\""`
    COMPONENTS="${CUR_COMPONENT} ${COMPONENTS}"
    echo $COMPONENTS
done

COMPONENTS=`echo $COMPONENTS | tr ' ' ','`
COMPONENTS="[${COMPONENTS}]"

echo "Checking secret $CODEFRESH_SECRET_NAME..."
if kubectl -n "$NAMESPACE" get secret "$CODEFRESH_SECRET_NAME"; then
    echo "  --> Secret $CODEFRESH_SECRET_NAME exists"
else
    echo "  --> Secret $CODEFRESH_SECRET_NAME doesn't exists."
    echo ""
    
    RUNTIME_CREATE_ARGS="{
    \"repo\": \"${CSDP_RUNTIME_REPO}\",
    \"runtimeName\":\"${CSDP_RUNTIME_NAME}\",
    \"cluster\":\"${CSDP_RUNTIME_CLUSTER}\",
    \"ingressHost\":\"${CSDP_RUNTIME_INGRESS_URL}\",
    \"ingressClass\":\"${CSDP_INGRESS_CLASS_NAME}\",
    \"ingressController\":\"${CSDP_INGRESS_CONTROLLER}\",
    \"componentNames\":${COMPONENTS},
    \"runtimeVersion\":\"v0.0.0\",
    \"managed\": false
    }"

    RUNTIME_CREATE_DATA="{\"operationName\":\"CreateRuntime\",\"variables\":{\"args\":$RUNTIME_CREATE_ARGS}"
    RUNTIME_CREATE_DATA+=$',"query":"mutation CreateRuntime($args: RuntimeInstallationArgs\u0021) {\\n  createRuntime(installationArgs: $args) {\\n    name\\n    newAccessToken\\n  }\\n}\\n"}'
    echo "  --> Creating runtime with args:"
    echo "$RUNTIME_CREATE_ARGS"

    RUNTIME_CREATE_RESPONSE=`curl "${PLATFORM_URL}/2.0/api/graphql" \
    -SsfL \
    -H "Authorization: ${CODEFRESH_USER_TOKEN}" \
    -H 'content-type: application/json' \
    --compressed \
    --insecure \
    --data-raw "$RUNTIME_CREATE_DATA"`

    if `echo "$RUNTIME_CREATE_RESPONSE" | jq -e 'has("errors")'`; then
        echo "Failed to create runtime"
        echo ${RUNTIME_CREATE_RESPONSE}
        exit 1
    fi

    CSDP_RUNTIME_TOKEN=`echo $RUNTIME_CREATE_RESPONSE | jq '.data.createRuntime.newAccessToken'`
fi