#!/usr/bin/env bash

set -e

isAlive=0

health_check() {
    # Check if health check endpoint is alive
    if curl --output /dev/null --silent --fail -k "$1"
    then
        status_code=$(curl --write-out %{http_code} --silent --output /dev/null -k ${1})

        # Check if requests to the health check endpoint produces the expected response
        if [[ "$status_code" -ne ${2} ]] ; then
            >&2 echo "Endpoint $1 produces an invalid response: $status_code"
            exit 1
        else
            echo "Endpoint $1 is alive!"
            isAlive=1
        fi
    else
        >&2 echo "Endpoint $1 is not alive. Retrying in 10s..."
        sleep 10s
        isAlive=0
    fi
}

# Perform health checks for endpoints expecting an HTTP 200 response code
declare -a healthcheckEndpoints200=(
    "https://wso2is-pattern-1-service.wso2is-staging.svc.cluster.local:9443/carbon/admin/login.jsp"
#    "Endpoint 2"
#    "Endpoint 3"
)

for endpoint in "${healthcheckEndpoints200[@]}"
do
    COUNTER=0
    while [ ${isAlive} -eq 0 ]&&[ ${COUNTER} -lt 18 ]; do
        health_check ${endpoint} 200
        let COUNTER=COUNTER+1
    done

    if [ ${isAlive} -eq 0 ]; then
        >&2 echo "Could not connect to $endpoint. Exiting..."
        exit 1
    fi
    isAlive=0
done

# Perform health checks for endpoints expecting an HTTP 302 response code
declare -a healthcheckEndpoints302=(
    "https://wso2is-pattern-1-service.wso2is-staging.svc.cluster.local:9443/"
    "https://wso2is-pattern-1-service.wso2is-staging.svc.cluster.local:9443/dashboard"
#    "Endpoint 3"
#    "Endpoint 4"
)

for endpoint in "${healthcheckEndpoints302[@]}"
do
    COUNTER=0
    while [ ${isAlive} -eq 0 ]&&[ ${COUNTER} -lt 18 ]; do
        health_check ${endpoint} 302
        let COUNTER=COUNTER+1
    done

    if [ ${isAlive} -eq 0 ]; then
        >&2 echo "Could not connect to $endpoint. Exiting..."
        exit 1
    fi
    isAlive=0
done

exit 0
