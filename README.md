# How to Deploy
Follow this step by step guide to deploy elasticsearch system:
1. Prepare AWS account and permission to create the following resources:
   1. vpc
   2. route table
   3. subnets
   4. ec2
   5. security group
2. Install Terraform and Ansible to laptop
3. Pull this repo: `git clone https://github.com/essanpupil/elasticsearch-training.git`
4. Enter directory: `cd elasticsearch-training`
5. Authenticate to aws
6. Deploy S3 bucket for the terraform state
   1. Enter terraform state directory: `cd us-east-2/s3/terraform-state`
   2. Initiate terraform: `terraform init`
   3. Check current terraform plan: `terraform plan`
   4. If everything is OK, then apply it: `terrafrom apply`
7. Deploy VPC, subnets, and gateways:
   1. Enter VPC directory: `cd us-east-2/vpc`
   2. Initiate terraform: `terraform init`
   3. Check current terraform plan: `terraform plan`
   4. If everything is OK, then apply it: `terrafrom apply`
8. Deploy bastion instance:
   1. Enter bastion directory: `us-east-2/ec2/bastion`
   2. Initiate terraform: `terraform init`
   3. Check current terraform plan: `terraform plan`
   4. If everything is OK, apply the config: `terrafom apply`
9.  Deploy kibana instance:
   1. Enter kibana directory: `us-east-2/ec2/kibana`
   2. Initiate terraform: `terraform init`
   3. Check current terraform plan: `terraform plan`
   4. If everything is OK, apply the config: `terrafom apply`
10. Deploy elasticsearch instances:
   1. Enter elasticsearch directory: `us-east-2/ec2/elasticsearch`
   2. Initiate terraform: `terraform init`
   3. Check current terraform plan: `terraform plan`
   4. If everything is OK, apply the config: `terrafom apply`
11. Deploy ALB:
   1. Enter alb directory: `us-east-2/alb`
   2. Initiate terraform: `terraform init`
   3. Check current terraform plan: `terraform plan`
   4. If everything is OK, apply the config: `terrafom apply`
13. Start ssm connection to bastion instance.
14. Install git cli on the bastion instance
15. Pull this repository to bastion instance: `git clone https://github.com/essanpupil/elasticsearch-training.git`
16. Enter provisioning directory: `cd provisioning/`
17. Update `inventory.yaml` file with the IP address of private ip address of created kibana and elasticsearch.
18. Install elastic repository: `ansible-playbook 00-elastic-repository-debian.yaml`
19. provision elasticsearch: `ansible-playbook elasticsearch-install.yaml`
20. provision kibana: `ansible-playbook kibana-install.yaml`
21. Check created plubic dns of the alb.
22. Open kibana web page from the alb public dns.


# Final Architecture
## AWS VPC with three subnets:
### public subnet
This subnet is directly accessible from internet. This subnet is used to be the interface from public internet to our system. Inside this public subnet we deploy:
1. Application Load Balancer. It is used to interact user with kibana webserver
2. nat-instance. This a nat instance type from aws. This is to provide internet connection from private subnet to internet. So that instances inside private subnet can do updates and installations. nat-instance is choosen because it is relatively cheaper compare with other types of nat gateway in aws.

### private subnet
This subnet is not accesible directly from internet, but we still allow outbond connection to internet. This subnet is used to deploy our internal system such as kibana and logstash (not included). In current settings, instances that are deployed in private subnet are
1. kibana, we server interface to manage elasticsearch
2. bastion, used to connect and managed other service by engineer

### data subnet
This subnet is not accessible from internet, and also do not have outbond connection to intenret. The outbond internet connection is sometimes will be allowed for installation and updates. The resources deploy in this subnet are:
1. elasticsearch cluster nodes

## Following is the goals of the exercise:
1. Demonstrate your hands-on skills, you can code for building cloud hosted solution
2. Demonstrate that you can think of other cross-cutting-concerns like security
3. A nice segue to our discussion after you submit the code

## What we are expecting:
1. A link to github repo (or a zip/tarball) with code that accomplishes:
   1. Brings up an AWS instance
   2. Installs ElasticSearch configured in a way that requires credentials and provides encrypted communication
   3. Demonstrates that it is functioning
2. Instructions with:
   1. A short description of your solution describing your choices and why did you make them
   2. Resources, if any, that you consulted to arrive at the final solution
   3. How long did you spend on the exercise, and if possible, short feedback about the exercise
3. Must use AWS free tier, however, if you’re using any additional services, please mention them in the instructions
4. ElasticSearch access and communication must be secure

## Bonus if you extend your code to create a cluster of 3 ElasticSearch nodes

## Some answers we are looking:
1. What did you choose to automate the provisioning and bootstrapping of the instance? Why?
   1. *ANSWER* For aws resources, i prefer using terraform to configure it. For instance privisioning and application configuration i prefer to use ansible. The concept that use is, terraform is good for immutable infra resources handling, while ansible is better for mutable resources or application configuration. Looking at the static and strict character of elasticsearch with its config, i suggest we use hashicorp consul for easier configuration management. This is because oftentimes we need to modify existing nodes when we have new nodes join the cluster. We can also implement cicd automation for the infra automation to help managing the resources.

2. How did you choose to secure ElasticSearch? Why?
   1. *ANSWER* Elasticsearch cluster communication is secured using ssl certificates for mutual TLS connection among elasticsearch nodes. We also use tls connection from http client such as kibana to elasticsearch. Elasticsearch provide elasticsearch-certutil built in binary command line to generate token and enroll to initial master node using the token. Elasticsearch certutil also available to generate token for kibana.

3. How would you monitor this instance? What metrics would you monitor?
   1. *ANSWER* We should deploy another monitoring system such as grafana + prometheus + loki to monitor the current ELK stack. But we will carefully select core system metric and logging that affect the ELK stack performance. This is to cover when something happen to the elk stack, and we totally can open the kibana web, we still have way to monitor and detect for suspicious log event. ELK stack will be focusing on serving search service.

4. Could you extend your solution to launch a secure cluster of ElasticSearch nodes? What would need to change to support this use case?
   1. *ANSWER* We need external credentials storage such as hashicorp vault or AWS Secret manager. We will keep all sensitive information inside the vault, then modify ansible and terraform to read or write to the vault if needed. For user access, we can apply AWS cognito or other similar service to avoid direct auth handling by kibana. This is also for easier user management to integrate kibana access with company roles and policy. 

5. Could you extend your solution to replace a running ElasticSearch instance with little or no downtime? How?
   1. *ANSWER* For maintenance, if we want to replace existing instance the procedures are:
      1. Deploy the new instance, configure and register to the cluster.
      2. Wait few minutes to make sure all data, shards, and indices are synchronized to the new nodes.
      3. Configure elasticsearch to empty the problematic node.
      4. Check does the problematic node is 100% sure do not store data anymore.
      5. Unregister the problematic node from elasticsearch cluster.

6. Was it a priority to make your code well structured, extensible, and reusable?
   1. *ANSWER* We need to create dedicated ansible playbook for various operational task such as cluster initiation, new join node to existing cluster, simple config change, user management such as password reset, etc. This is my take away from working on this test. We can not risk changing something unrelated to our intention. For eample when we want to reconfigure elasticsearch node name, we might change cluster join certificate if the playbook is not separated.

7. What sacrifices did you make due to time?
   1. I do not deploy CICD to automatically check plan and run terraform or ansible changes
   2. I do not deploy logstash for data ingestion
   3. I do not deploy queue system to handle big traffic data ingestion to elasticsearch
   4. I do not use aws secret manager or hashicorp vault to store sensitive data.
