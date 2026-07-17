# Architecture
## VPC (Observability Cluster)
### Public Subnet
#### Application Load Balancer
It's used to access Kibana. This ALB will integrate with AWS Cognito to provide authentication

### Private Subnet
#### Kibana Server
#### Logstash Server

### Data Subnet
#### Elasticsearch Server
