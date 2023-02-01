# PG DO - DevOps Capstone Project

## DESCRIPTION

Create a DevOps infrastructure for an e-commerce application to run on high-availability mode.

## Background of the problem statement:
A popular payment application, EasyPay where users add money to their wallet accounts, faces an issue in its payment success rate. The timeout that occurs with
the connectivity of the database has been the reason for the issue.
While troubleshooting, it is found that the database server has several downtime instances at irregular intervals. This situation compels the company to create their own infrastructure that runs in high-availability mode.
Given that online shopping experiences continue to evolve as per customer expectations, the developers are driven to make their app more reliable, fast, and secure for improving the performance of the current system.

## GitHub
>All source is located in DockerHub Capstone Project, [https://github.com/micklto/capstone](https://github.com/micklto/capstone)

## DockerHub
>Repository repository for the PG DO - DevOps Capstone Project, [https://hub.docker.com/repository/docker/dockertmickler/capstone](https://hub.docker.com/repository/docker/dockertmickler/capstone)

## Assumptions

#### Installed Tools
- Git
- Ansible
- Terraform
- JDK
## Application Development
### Spring Boot Application
Application is called ```capstone``` and is a Spring Boot application that is deployed as a container.  It is dependant on a PostgreSQL datasource.  It will takes its paramaters through environment variables.

Steps for building Spring Boot Application

```bash
./mvnw install 
./mvnw spring-boot:build-image
```
### Application Testing

#### JUnit 5 testing
Maven is used to build the applicaiton and test source code.  It has a built in ```test``` lifecycle.  When we run ```./mvnw install```, the test lifecycle is run. Two test files are run:
- ```CapstoneApplicationTests.java``` - Tests to ensure the Spring context loads
- ```HelloWorldConfigurationTests.java``` - Tests to see that the web server runs and responds with appropriate error codes.

#### K6 Stress Testing
>On MacOS, use command ````bash brew install k6````

````bash
k6 run script.js
````

### DockerHub

>DockerHub will store the Spring Boot application and the PostgreSQL images used in the Kubernetes deployment.

Steps to push to DockerHub
```bash
docker tag capstone:0.0.1-SNAPSHOT dockertmickler/capstone:0.0.1
docker push dockertmickler/capstone:0.0.1
```

### Project and Tester Details
### AWS

Log into AWS Web Console
![AWS Web Console](/img/AWSWebConsole.png "AWS Web Console")

 from Simplilearn and get the following items
 - VPC ID
 - Create KeyPair called ```Demokey```
    - Download ```Demokey.pem``` and place it in the ```terraform``` directory
    - Terraform ensures that the user is the only one with permissions to this key.  Issue the following command:
    ```bash
    chmod 400 Demokey.pem
    ```

Pull details from the AWS API Access page

![AWS API Access](/img/AWSApiAccess.png "AWS API Access")
- Access key - <YOUR_ACCESS_KEY>
- Secret Key - <YOUR_SECRET_KEY>
- Security Token - <YOUR_SECURITY_TOKEN>

>Update the variables in ```terraform/main.tf```



### Terraform

#### Files and Algorithms
- ```main.tf``` - Entrypoint IaC script for terraform. Sections listed below
    - ```locals``` - local variable definition
    - ```provider``` - aws provider
    - ```resource``` - aws security group. Multiple ingress and an egress defined
    - ```resource``` - aws instance. Control node defined with ssh connection
    - ```resource``` - aws instance. worker nodes defined with ssh connection
    - ```data``` - aws vpc. Allows for query of CIDR
    - ```resource``` - local file. Creates Ansible variable file
    - ```resource``` - local file. Creates Ansible hosts file
    - ```provisioner``` - local exec. Runs ansible after infrastructure is created
- ```Demokey.pem``` - Downloaded Key Pair from AWS
- ```hosts.tpl``` - template file for generating an Ansible configuration
- ```ansiblevars.tpl``` - template file for generating an Ansible variables
- ```variables.tf``` - main file for Terraform variable definition
#### Terraform Commands
Commands for Infrastructure Creation:
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
Commands for Infrastructure Destruction:
```bash
terraform destroy -auto-approve
````
#### Ansible
>Install prerequisites for [kubernetes.core.k8s module](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/k8s_module.html#ansible-collections-kubernetes-core-k8s-module-requirements)

````bash
brew install json-c
brew install pyyaml
ansible-galaxy collection install kubernetes.core
````
##### Roles
###### common
###### master
###### worker
******* TODO ************
Currently have to run the worker nodes ansible once the control node is finished.  Need to hook that up.

### Kubernetes

#### Files in ```deploy``` directory
- ```postgres-config.yaml``` - Congiguration for PostgreSQL deployment
- ```postgres-pvc-pv.yaml``` - Persistent Volume Claims for PostgreSQL deployment
- ```postgres-deployment.yaml``` - PostgreSQL deployment
- ```postgres-service.yaml``` - Service creation for PostgreSQL deployment
- ```deployment.yaml``` - Deploy ```capstone``` project
- ```capstone-service.yaml``` - Expose ```capstone``` project as a service

>Install Postgres server with the following commands
```bash
kubectl apply -f postgres-config.yaml
kubectl apply -f postgres-pvc-pv.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml
````
>Deploy ```capstone``` application

````bash
kubectl apply -f deployment.yaml
kubectl apply -f capstone-service.yaml
````


#### Expose ```capstone``` application as a public service
````bash
kubectl expose deployment capstone --type=LoadBalancer
````

#### Horizontal autoscale ```capstone``` deployment
````bash
kubectl autoscale deployment capstone --cpu-percent=50 --min=2 --max=10
````
#### Metrics server

>Verify ```capstone``` application in web browser

- http://localhost:8080 - Basic web appliccation
- http://localhost:8080/demo/all - View all users
## Conclusion

Your conclusion on enhancing the application and defining the USPs (Unique Selling Points)


NOTES:
1. Need to test generating a load to show that the application auto scales (Jmeter, etc)
2. This can be used for job application.  This project can be used to demonstrate your skills in this area.





## TODO
- master runs through fine.  Running nodes works.  Can run kubectl get nodes but they aren't in a good state. 
>Kubernetes check on the pods. 
````bash
ssh 
kubectl get nodes -o wide
kubectl describe pod <podname>
shows cni not installed
````
- install prerequisites for kubernetes ansible module on master nodes
- copy of deployment goes to /home/ubuntu/deploy/deploy/*.yaml.  It should go under root I think
- backup etcd
- Do we need to install the metrics server ??????????
- Create autoscaling of app
- figure out how to stress the application to make it scale (jmeter may be what I want to do)
- Move to Ansible Role - incorporate master-playbook.yaml and node-playbook.yaml
- Describe main sections of Terraform main.tf
- Describe tasks in ansible playbooks.  Give them descriptive names.  Describe them in this doc
- Fully document project for delivery
- REMOVE ALL TODO Tags in project

```bash
<project>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <image>
                        <name>example.com/library/${project.artifactId}</name>
                    </image>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

or

```bash
mvn spring-boot:build-image -Dspring-boot.build-image.imageName=example.com/library/my-app:v1
```


