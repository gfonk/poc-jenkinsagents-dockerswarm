#!/usr/bin/env bash
set -xe

DOCKER_MACHINE_COMMAND="docker-machine"
DOCKER_MACHINE_MASTER_HOST="master-host"
JENKINS_PORT="8080"
VISUALIZER_PORT="8083"
REGISTRY_PORT="5000"
REGISTRY_ADDRESS="localhost:${REGISTRY_PORT}"

DM_SSH="${DOCKER_MACHINE_COMMAND} ssh ${DOCKER_MACHINE_MASTER_HOST}"
DM_SCP="${DOCKER_MACHINE_COMMAND} scp"

${DOCKER_MACHINE_COMMAND} create \
    --driver amazonec2 \
    --amazonec2-region us-east-1 \
    --amazonec2-security-group default \
    ${DOCKER_MACHINE_MASTER_HOST}

${DM_SSH} sudo docker swarm init
${DM_SSH} sudo docker node update --label-add type=jenkins ${DOCKER_MACHINE_MASTER_HOST}
#${DM_SSH} sudo docker swarm manage --strategy binpack
${DM_SSH} sudo mkdir -p /jenkins_home
${DM_SSH} sudo chmod 777 /jenkins_home
${DM_SSH} sudo mkdir -p /registry
${DM_SSH} sudo chmod 777 /registry
${DM_SSH} sudo mkdir -p /home/ubuntu/poc/
${DM_SSH} sudo chmod 777 /home/ubuntu/poc/

WORKER_TOKEN=$(${DM_SSH} sudo docker swarm join-token worker|grep token|sed -r 's/^.*--token (.*) \\$/\1/')
#MANAGER_TOKEN=$(${DM_SSH} sudo docker swarm join-token manager|grep token|sed -r 's/^.*--token (.*) \\$/\1/')
MASTER_IP=$(${DM_SSH} sudo docker swarm join-token worker|tail -2|head -1|sed -r 's/^.*\s+(.*):.*$/\1/')
JENKINS_IP=$(${DM_SSH} sudo docker swarm join-token worker|tail -2|head -1|sed -r 's/^.*\s+(.*):.*$/\1/')

ACCESS_KEY_ID=$(cat ../credentials|grep key_id|sed -r 's/^.*= (.*)$/\1/')
SECRET_ACCESS_KEY=$(cat ../credentials|grep secret_access|sed -r 's/^.*= (.*)$/\1/')

${DM_SSH} "echo ${WORKER_TOKEN}|sudo docker secret create worker-token -"
${DM_SSH} "echo ${MASTER_IP}|sudo docker secret create master-ip -"
${DM_SSH} "echo ${JENKINS_IP}|sudo docker secret create jenkins-ip -"
${DM_SSH} "echo ${JENKINS_PORT}|sudo docker secret create jenkins-port -"
${DM_SSH} "echo ${ACCESS_KEY_ID}|sudo docker secret create access-key-id -"
${DM_SSH} "echo ${SECRET_ACCESS_KEY}|sudo docker secret create secret-access-key -"

${DM_SSH} sudo docker service create \
    --name=registry \
    --publish=${REGISTRY_PORT}:5000 \
    --constraint=node.role==manager \
    --mount=type=bind,src=/registry,dst=/var/lib/registry \
    registry

${DM_SSH} sudo docker service create \
  --name=vizualizer \
  --publish=${VISUALIZER_PORT}:8080/tcp \
  --constraint=node.role==manager \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  manomarks/visualizer

${DM_SSH} sudo docker pull vfarcic/jenkins-swarm-agent
${DM_SSH} sudo docker tag vfarcic/jenkins-swarm-agent localhost:5000/jenkins-swarm-agent
${DM_SSH} sudo docker push ${REGISTRY_ADDRESS}/jenkins-swarm-agent

${DM_SCP} ../Docker ${DOCKER_MACHINE_MASTER_HOST}:/home/ubuntu/poc/ -r
${DM_SSH} sudo docker build /home/ubuntu/poc/Docker/Jenkins -t ${REGISTRY_ADDRESS}/jenkins_custom
${DM_SSH} sudo docker push ${REGISTRY_ADDRESS}/jenkins_custom

${DM_SSH} sudo docker service create \
    --name=jenkins \
    --publish=${JENKINS_PORT}:8080 \
    --publish=50000:50000 \
    --constraint=node.role==manager \
    --mount=type=bind,src=/jenkins_home,dst=/var/jenkins_home \
    --secret worker-token \
    --secret master-ip \
    --secret jenkins-ip \
    --secret jenkins-port \
    --secret access-key-id \
    --secret secret-access-key \
    ${REGISTRY_ADDRESS}/jenkins_custom

${DM_SCP} slave-host-start.sh ${DOCKER_MACHINE_MASTER_HOST}:/jenkins_home/
${DM_SCP} slave-stop-cron.sh ${DOCKER_MACHINE_MASTER_HOST}:/jenkins_home/
${DM_SSH} sudo chmod +x /jenkins_home/slave-host-start.sh
${DM_SSH} sudo chmod +x /jenkins_home/slave-stop-cron.sh

${DM_SSH} "sudo docker service create --name jenkins-agent \
    --mount=type=bind,src=/workspace,dst=/workspace \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    --constraint=node.role!=manager \
    --mode=global \
    -e COMMAND_OPTIONS=\"-master http://${JENKINS_IP}:${JENKINS_PORT}/ -username admin -password admin -labels 'swarm' -executors 5\" \
    ${REGISTRY_ADDRESS}/jenkins-swarm-agent"

sleep 60
JENKINS_SECRET=$(${DM_SSH} cat /jenkins_home/secrets/initialAdminPassword)
JENKINS_URL="$(${DM_SSH} curl http://169.254.169.254/latest/meta-data/public-hostname):${JENKINS_PORT}"
VISUALIZER_URL="$(${DM_SSH} curl http://169.254.169.254/latest/meta-data/public-hostname):${VISUALIZER_PORT}"
echo "Jenkins secret: ${JENKINS_SECRET}"
echo "Jenkins URL: http://${JENKINS_URL}/"
echo "Visualiser URL: http://${VISUALIZER_URL}/"