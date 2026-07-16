1. Create AWS S3 bucket for terraform state storage
2. Create AWS IAM user with superadmin role
3. Deploy aws vpc
   1. public subnet for public load balancer to Kibana
   2. private subnet to deploy Kibana and logstash
   3. data subnet to deploy elasticsearch cluster nodes
4. Configure nat instance in private to data subnet for OS updates of elasticsearch nodes
5. Configure nat instance in public to private subnet for OS updates and installation Kibana
6. Configure routing in private and data subnet
