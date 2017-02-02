#!/usr/bin/env bash
set -xe

cd /var/jenkins_home

RUNNING_MACHINES=$(docker-machine ls -q --filter "name=worker-.*" --filter "state=Running")

for MACHINE in ${RUNNING_MACHINES};do
        AGENT_PARENT_PID=$(docker-machine ssh ${MACHINE} "pgrep -f '/home/jenkins/swarm-client'")
        JOBS_COUNT=$(docker-machine ssh ${MACHINE} "pgrep -P $AGENT_PARENT_PID|wc -l")
        if [[ "${JOBS_COUNT}" -eq "0" ]]
        then
            if [[ -f ${MACHINE} ]]
            then
                COUNT_CHECKS=$(cat ${MACHINE})
                if [[ "${COUNT_CHECKS}" -ge "2" ]]
                then
                    docker-machine ssh ${MACHINE} sudo docker swarm leave
                    docker-machine stop ${MACHINE}
                    rm ${MACHINE}
                else
                    echo $(( ${COUNT_CHECKS} + 1 )) > ${MACHINE}
                fi
            else
                echo 1 > ${MACHINE}
            fi
        else
            if [[ -f ${MACHINE} ]]
            then
                rm ${MACHINE}
            fi
        fi
done
