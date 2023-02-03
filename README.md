# PG DO - DevOps Capstone Project

## DESCRIPTION

Create a DevOps infrastructure for an e-commerce application to run on high-availability mode.

## Background of the problem statement:
A popular payment application, <b>EasyPay</b> where users add money to their wallet accounts, faces an issue in its payment success rate. The timeout that occurs with
the connectivity of the database has been the reason for the issue.
While troubleshooting, it is found that the database server has several downtime instances at irregular intervals. This situation compels the company to create their own infrastructure that runs in high-availability mode.
Given that online shopping experiences continue to evolve as per customer expectations, the developers are driven to make their app more reliable, fast, and secure for improving the performance of the current system.

## GitHub
>All source is located in DockerHub Capstone Project, [https://github.com/micklto/capstone](https://github.com/micklto/capstone)

## DockerHub
>Container repository for the PG DO - DevOps Capstone Project, [https://hub.docker.com/repository/docker/dockertmickler/capstone](https://hub.docker.com/repository/docker/dockertmickler/capstone)

## Assumptions and Observations

###  AWS Simplilearn and Free Tier
The cloud environment that we have to work with doesn't allow for a lot of memory usage per node.  The ```spring-boot``` application that was suggested  we use takes up a lot of memory.  When working on ```Horizontal Pod Autoscaling```, I set a 2 pod minimum and 4 pod maximum range to prevent the over taxing of the overall system.  When the system had a load applied, even with this modest range, there would be pods that could not start because those pods could not obtain the memory needed to run the container.
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
- Docker

>Installation instructions can be found for your development platform at their respective websites.
## Application Development
### Spring Boot Application
Application is called ```capstone``` and is a ```Spring Boot``` application that is deployed as a container.  It is dependant on a PostgreSQL datasource.  It will takes it\'s database connection paramaters through environment variables. Those environment varialbes will be provided through an ```env``` section in the deployment descriptor.

The spring-boot plugin for maven provides for building an OCI compliant container without using a Dockerfile. 

#### Steps for building Spring Boot Application

```bash
./mvnw install 
./mvnw spring-boot:build-image
```
### Application Testing

#### JUnit 5 testing
Maven is used to build the applicaiton and test source code.  It has a built in ```test``` lifecycle.  When we run ```./mvnw install```, the test lifecycle is run. Two test files are run:
- ```CapstoneApplicationTests.java``` - Tests to ensure the Spring context loads
- ```HelloWorldConfigurationTests.java``` - Tests to see that the web server runs and responds with appropriate error codes.

For project submission, these results will be attached as a separate document.

### DockerHub

>DockerHub will store the Spring Boot application and the PostgreSQL images used in the Kubernetes deployment.

#### Steps to push to DockerHub

The steps for building the ```capstone``` application were given under the above "Spring Boot Application" section.

```bash
docker tag capstone:0.0.1-SNAPSHOT dockertmickler/capstone:0.0.1
docker push dockertmickler/capstone:0.0.1
```

### Project and Tester Details
#### AWS

The Simplilearn AWS environment was too limiting as far as size of servers that we could create.  This project was completed in an AWS "Free Tier" environment.

#### VPC

>Your VPC ID is needed for the Terraform scripts
VPC > Your VPC > Select Your VPC and copy your VPC and modify the variable in ```main.tf```

![VPC](/img/YourVPCs.png "VPC")

#### EC2

![Key Pairs](/img/KeyPairs.png "Key Pairs")


 - Create a KeyPair. I created a key called ```mickltokey```.  You may call it something else but you will have to change the references in the Terraform files.
    - Download ```mickltokey.pem``` and place it in the ```terraform``` directory
    - Terraform ensures that the user is the only one with permissions to this key.  Issue the following command:
    ```bash
    chmod 400 mickltokey.pem
    ```

Pull details from the AWS IAM facility

> Create a user with admin privileges.  After creating user, you can download a `.csv` file that contains the ```Access key``` and ```Secret Key```

![AWS IAM](/img/IAM.png "AWS IAM")

- Access key - <YOUR_ACCESS_KEY>
- Secret Key - <YOUR_SECRET_KEY>

>Update the variables in ```terraform/provider.tf```

### Terraform

>Terraform is used for our Infrastructure as Code (IaC) implementation.  Terraform provisions all the AWS EC2 instances as well as any Software Defined Networks (SDN) needed.  Terraform extracts the host data from the infrastructure creation process and provides it to Ansible by creating variable and inventory files. It is possible to have Terraform run ansible scripts from a `local-exec` provisioner.  During the creation of this project, I decided that I would separate Ansible from Terraform.  I would let Terraform control the state of the infrastructure without being dependeant on whether the Ansible configuration was successful.  In a more real world environment, another automated process would be controlling terraform, checking for the existence of the infrastructure and then calling into Ansible.

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

Terraform creates an Ansible inventory file at ```ansible/inventory/hosts.cfg``` and varibles for the host ip\'s and CIDR at ```ansible/vars/default.yaml```.
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

#### Playbooks

>This project uses one playbook, ```playbook.yaml```.  It coordinates the usage of the 4 roles defined above.

### Kubernetes

#### Namespaces

All work will be done in the ```capstone``` namespace. The Ansible ```deployment``` role provides for creating this namespace.

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
- Horizontal Pod Autoscaling
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

### Horizontal Pod Autoscaling (HPA)

>Horizontal Pod Autoscaling allows Kubernetes to monitor a deployment for different types of resource usage.  In our project we will monitor the CPU utilizaiton of our ```capstone``` deployment.  The rules that we have in place are that there will be at least two capstone pods and we will scale up to 4 pods if the CPU utilization goes above 50%.  HPA needs the Kubernetes metric server in place to monitor the pods. The hpa specification sets the HPA rules.
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


>Run a container that constantly GET\'s the default page for our ```capstone``` application.  This will generate enough load on our application to cause it to scale.

````bash
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://<ClusterIP>:8080; done"
````

![Horizontal Pod Autoscaling](/img/HPAVerification.png "Horizontal Pod Autoscaling Verification")


#### etcd
>K3s enables snapshots by default. The snapshot directory defaults to ```${data-dir}/server/db/snapshots```. The data-dir value defaults to ```/var/lib/rancher/k3s```.
## Conclusion

Availability and reliability are key for customer facing web applications.  Customers will not want to use the application if the website is difficult, slow, or alltogether down.

Kubernetes is a perfect rememdy for <b>EasyPay\'s</b> reliability issues. Kubernetes is designed to restart applications if they are down. When Horizontal Pod Autoscaling is involved, the number of pods will grow to meet the increased demand. Kubernetes can spread its workload across worker nodes.  In AWS, those worker nodes can be in different areas of the world. Increased redundancy and speed are a result of this Kubernetes and AWS Cloud architecture.

Infrastructure as Code (IaC) and Configuration as Code(CaC) will allow for the architecture to be source controlled, peer reviewed, and automatically implemented. If more resources are needed, they can be easily added by adding items to the infrastructure scripts.