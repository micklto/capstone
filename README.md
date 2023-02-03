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
>Container repository for the PG DO - DevOps Capstone Project, [https://hub.docker.com/repository/docker/dockertmickler/capstone](https://hub.docker.com/repository/docker/dockertmickler/capstone)

## Assumptions
### K3s

[K3s](https://k3s.io) was chosen for the Kubernetes installation.  
- The AWS environment of the Simplilearn AWS environment did not provide for enough resources to host a full Kubernetes installation.
- K3s provided for a metrics server that is needed to measuer CPU utilization in our Horizontal Pod Autoscaling
- etcd enables snapshots out of the box.
### Installed Tools
- Git
- Ansible
- Terraform
- JDK
## Application Development
### Spring Boot Application
Application is called ```capstone``` and is a Spring Boot application that is deployed as a container.  It is dependant on a PostgreSQL datasource.  It will takes its database connection paramaters through environment variables. Those environment varialbes will be provided through ```env``` in the deployment descriptor.

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


#### Stress Testing
>Run a container that constantly GET's the default page for our ```capstone``` application.  This will generate enough load on our application to cause it to scale.

````bash
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://<ClusterIP>:8080; done"
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

The Simplilearn AWS environment was too limiting as far as size of servers that we could create.  This project was completed in an AWS "Free Tier" environment.

#### VPC

>Your VPC ID is needed for the Terraform scripts
VPC > Your VPC > Select Your VPC and copy your VPC and modify the variable

![VPC](/img/YourVPCs.png "VPC")

#### EC2

![Key Pairs](/img/KeyPairs.png "Key Pairs")


 - Create a KeyPair. I created a key called ```mickltokey```.  You may call it something else but you will have to change the references in the Terraform files.
    - Download ```mickltokey.pem``` and place it in the ```terraform``` directory
    - Terraform ensures that the user is the only one with permissions to this key.  Issue the following command:
    ```bash
    chmod 400 mickltokey.pem
    ```

Pull details from the AWS API Access page

![AWS API Access](/img/AWSApiAccess.png "AWS API Access")
- Access key - <YOUR_ACCESS_KEY>
- Secret Key - <YOUR_SECRET_KEY>

>Update the variables in ```terraform/provider.tf```



### Terraform

>Terraform is used for our Infrastructure as Code (IaC) implementation.  Terraform provisions all the AWS EC2 instances as well as any Software Defined Networks needed.  Terraform extracts the host data from the infrastructure creation process and provides it to Ansible by creating variable and inventory files.
#### Files and Algorithms
- ```main.tf``` - Entrypoint IaC script for terraform. Sections listed below
    - ```locals``` - local variable definition
    - ```resource``` - aws security group. Multiple ingress and an egress defined
    - ```resource``` - aws instance. Control node defined with ssh connection
    - ```resource``` - aws instance. worker nodes defined with ssh connection
    - ```data``` - aws vpc. Allows for query of CIDR
    - ```resource``` - local file. Creates Ansible variable file
    - ```resource``` - local file. Creates Ansible hosts file
    - ```provisioner``` - local exec. Runs ansible after infrastructure is created
- ```provider.tf``` - Contains AWS provider
- ```mickltokey.pem``` - Downloaded Key Pair from AWS. Will <b>NOT</b> be included in source control for security reasons
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
When the Terraform scripts complete successfuly, you can check your EC2 Console to make sure you have three compute nodes running.
![Terraform Success](/img/TerraformSuccess.png "Terraform created nodes")
### Ansible

>Ansible provides Configuration as Code (CaC). Once the infrastructure is built by Terraform, Ansible is used to install and configure the system to run our application in Kubernetes. 

From the ```terraform``` directory, issue the command:
````bash
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ../ansible/inventory/hosts.cfg --user ubuntu --private-key /Users/toshmickler/projects/capstone/terraform/mickltokey.pem ../ansible/playbook.yaml
````
#### Modules
>The [kubernetes.core.k8s module](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/k8s_module.html#ansible-collections-kubernetes-core-k8s-module-requirements) is leveraged in the ```deployments``` role and the prerequisties will be installed during the execution of the ```common``` role.
#### Roles
>Ansible Roles were developed for a Highly Available Kubernetes installation.  The individual README files for the roles will contain a list of the tasks.
- [common](./ansible/roles/common/README.md) - Installs prerequisites such as Docker
- [deployments](./ansible/roles/deployments/README.md) - Contains Kubernetes deployment descriptors or specifications
- [master](./ansible/roles/master/README.md) - Tasks for installing Kubernetes on a master or controller node
- [worker](./ansible/roles/worker/README.md) - Tasks for install Kubernetes worker nodes and joining them to the controller


### Kubernetes

#### Namespaces

All work will be done in the ```capstone``` namespace. It gets created in the Ansible ```deployment``` role.

#### Deployments
>The ```deployment``` Ansible role is used to deploy the ```capstone``` application and a ```postgresql``` service for persisting data.  In addition, ```Role``` and ```RoleBinding``` creation is performed by this Ansible role.  The specification files are listed below with their desriptions.

- Postgresql
    - ```postgres-config.yaml``` - Congiguration for PostgreSQL deployment
    - ```postgres-pvc-pv.yaml``` - Persistent Volume Claims for PostgreSQL deployment
    - ```postgres-deployment.yaml``` - PostgreSQL deployment
    - ```postgres-service.yaml``` - Service creation for PostgreSQL deployment
- capstone
    - ```deployment.yaml``` - Deploy ```capstone``` project
    - ```capstone-service.yaml``` - Expose ```capstone``` project as a ClusterIP service
    - ```capstone-hpa.yaml``` - Enable Horizontal Pod Autoscalling for ```capstone``` project

#### RBAC
- Role
    - ```capstone-dev-role.yaml``` - Creates developer role for ```capstone``` namespace
- Role Binding
    - ```micklto-role-binding.yaml``` - Creates developer role for ```capstone``` namespace

>Run the RBAC commands manually on the control server. The "apply" commands create the Role  and RoleBinding in the capstone namespace.  The "auth can-i" commands show that the micklto user can list pods but that the foo user cannot perform the same action.

````bash
kubectl apply -f capstone-dev-role.yaml
kubectl apply -f micklto-role-binding.yaml
kubectl auth can-i list pods --as micklto -n capstone
kubectl auth can-i list pods --as foo -n capstone
````
![RBAC Role and RoleBinding Successful](/img/RBAC.png "RBAC Role and RoleBinding Successful")

### Verification

>Verification can be done on the ```control``` node of our infrastructure.  Access the AWS control panel, and go to EC2.  Select instances and then click on the instance with the control node tag.

![Instance Summary](/img/InstanceSummaryWithConnectButton.png "Instance Summary")

![Connect To Instance](/img/ConnectToInstance.png "Connect To Instance")

SSH to control node 

```bash
ssh -i "mickltokey.pem" ubuntu@ec2-44-192-85-87.compute-1.amazonaws.com
````
Switch user to ```root``` as root will have kubectl configured. This will have been done in the ```master``` role.

````bash
sudo su -
````

List all Kubernetes objects in capstaone namespace

````bash
kubectl get all -n capstone
````
![capsone namespace](/img/CapstoneNamespace.png "All objects in capstone namespace")

>Verify ```capstone``` application with cUrl.  Use capstone ClusterIP found above for the IP below.

    curl http://<ClusterIP>:8080 - Basic web appliccation
    curl http://>ClusterIP>:8080/demo/all - View all users

![capsone web verification](/img/WebVerification.png "capstone web verification")

Verification of Horizontal Pod Autoscaling

![Horizontal Pod Autoscaling](/img/HPAVerification.png "Horizontal Pod Autoscaling Verification")


#### etcd
>K3s snapshots are enabled by default.

The snapshot directory defaults to ```${data-dir}/server/db/snapshots```. The data-dir value defaults to ```/var/lib/rancher/k3s```.
## Conclusion

Your conclusion on enhancing the application and defining the USPs (Unique Selling Points)


TODO

- Document autoscaling of app
- Document AWS Free Tier screens to get the data.

- Describe tasks in ansible playbooks.  Give them descriptive names.  Describe them in this doc
- Fully document project for delivery
- Investigate GraalVM for better memory utilization
- REMOVE ALL TODO Tags in project
- REMOVE ALL UNUSED FILES

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


