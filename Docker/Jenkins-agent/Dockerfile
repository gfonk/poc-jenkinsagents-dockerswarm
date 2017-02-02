FROM java

RUN


java -jar swarm-client-2.0-jar-with-dependencies.jar \
    -name MacMini-compiling-server \
    -username xxx \
    -password xxxxxxx \
    -master http://localhost:8080/

JENKINS_IP=$(docker-machine ls --filter name="^master-host.*" --format="{{.URL}}"|sed -r 's/^tcp:\/\/(.*):.*/\1/')

docker service create --name jenkins-agent \
  -e COMMAND_OPTIONS="-master http://$JENKINS_IP/jenkins -username admin -password admin -labels 'swarm' -executors 5" \
  --mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" \
  --mount "type=bind,source=/workspace,target=/workspace" \
  --const
  --mode global localhost:5000/jenkins-swarm-agent