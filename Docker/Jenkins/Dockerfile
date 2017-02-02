FROM jenkins

USER root

#RUN apt-get update && apt-get install -y \
#        python-pip \
#        && rm -rf /var/lib/apt/lists/*

#RUN pip install \
#        awscli

RUN curl -L https://github.com/docker/machine/releases/download/v0.9.0/docker-machine-`uname -s`-`uname -m` >/tmp/docker-machine && \
        chmod +x /tmp/docker-machine && \
        cp /tmp/docker-machine /usr/local/bin/docker-machine

USER jenkins