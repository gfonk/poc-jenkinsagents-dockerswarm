# poc-jenkinsagents-dockerswarm

## Story

As an engineer, I would like to have the capability to spown up a jenkins-agent (aka jenkins-slave) in order to do *Build* and *Functional* Tests.
This allows multiple benefits:

- creation of predictable environments
- offloading executors from the jenkins-master node
- maximizing cost by scaling the Jenkins Agent Nodes when necessary.


## Definitions and Tasks

- Container Technology: Docker Swarm
- Language type: Java
- Use Jenkins Pipeline
- Simple Pipeline of:
  - Build (Basic app which has an endpoint you can test)
  - Deploy
  - Functional Test (basic test)
- The Demo Application can be a container
- The Jenkins-Master Service can be a container
- The most important part of this POC is:
  - creation of an jenkins-agent
  - using the jenkins-agent for Build and Tests
- Please do not use company names on this POC
  - Use generic names

## Acceptance Criteria

- Jenkins Pipeline Java Project, using Docker Swarm for *Build* and *Funcational* Tests
- PR sent to [poc-jenkinsagents-dockerswarm](https://github.com/gfonk/poc-jenkinsagents-dockerswarm)
  - PR(s) should have everything that anyone would need to run the POC (e.g. scripts, docker files, references), please do not included Binaries.


- - -

### Appendum/Changes

- Language of the project doesn't really matter.  Feel free to use python.  However replace *Build* stage, as *Package* stage.

