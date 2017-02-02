#!/usr/bin/env bash
set -xe

DOCKER_MACHINE_COMMAND="docker-machine"
DOCKER_MACHINE_HOST_NAME="$1"

if [[ "${DOCKER_MACHINE_HOST_NAME}" == "" ]]
then
    echo "Using generated hostname.."
    DOCKER_MACHINE_HOST_NAME="worker-host-$(dbus-uuidgen)"
fi

DM_SSH="${DOCKER_MACHINE_COMMAND} ssh ${DOCKER_MACHINE_HOST_NAME}"
DM_SCP="${DOCKER_MACHINE_COMMAND} scp"

WORKER_TOKEN="$(cat /var/run/secrets/worker-token)"
MASTER_IP="$(cat /var/run/secrets/master-ip)"
JENKINS_IP="$(cat /var/run/secrets/jenkins-ip)"
JENKINS_PORT="$(cat /var/run/secrets/jenkins-port)"
ACCESS_KEY_ID="$(cat /var/run/secrets/access-key-id)"
SECRET_ACCESS_KEY="$(cat /var/run/secrets/secret-access-key)"

if [[ "${JENKINS_IP}" == "" ]]
then
    echo "Create Master host first!"
    exit 1
fi

STOPPED_WORKERS=$(${DOCKER_MACHINE_COMMAND} ls -q --filter "name=worker-.*" --filter "state=Stopped")

if [[ "${STOPPED_WORKERS}" !=  "" ]]
then
    STOPPED_WORKER=$(echo ${STOPPED_WORKERS}|head -1)
    ${DOCKER_MACHINE_COMMAND} start ${STOPPED_WORKER}
    ${DOCKER_MACHINE_COMMAND} regenerate-certs -f ${STOPPED_WORKER}
    ${DOCKER_MACHINE_COMMAND} ssh ${STOPPED_WORKER} sudo docker swarm join --token ${WORKER_TOKEN} ${MASTER_IP}:2377
else
    ${DOCKER_MACHINE_COMMAND} create --driver amazonec2 \
        --amazonec2-access-key ${ACCESS_KEY_ID} \
        --amazonec2-secret-key ${SECRET_ACCESS_KEY} \
        --amazonec2-region us-east-1 \
        --amazonec2-security-group default \
        ${DOCKER_MACHINE_HOST_NAME}
    ${DM_SSH} sudo docker swarm join --token ${WORKER_TOKEN} ${MASTER_IP}:2377
    ${DM_SSH} sudo mkdir -p /workspace
    ${DM_SSH} sudo chmod 777 /workspace
fi

