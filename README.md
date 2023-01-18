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

JMeter, Postman, or K6 Stress Testing
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
- ```main.tf```
- ```Demokey.pem```
- ```hosts.tpl```
- ```variables.tf```
#### Terraform Commands
Commands for Infrastructure Creation:
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
Commands for Infrastructure Destruction:
```bash
terraform destroy
```


### Kubernetes

## Conclusion

Your conclusion on enhancing the application and defining the USPs (Unique Selling Points)


NOTES:
1. Need to test generating a load to show that the application auto scales (Jmeter, etc)
2. This can be used for job application.  This project can be used to demonstrate your skills in this area.





## TODO

- Create kubernetes yaml to deploy application
- Create autoscaling of app
- figure out how to stress the application to make it scale (jmeter may be what I want to do)
- Understand Private IP and CIDR for the one command that sets things up.
- Move to Ansible Role - incorporate master-playbook.yaml and node-playbook.yaml
- Fully document project for delivery

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


