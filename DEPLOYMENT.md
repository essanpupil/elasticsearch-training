# Deployment Procedure
1. Create AWS S3 bucket to store terraform state.
2. Deploy VPC with
   1. public subnet
   2. private subnet
   3. data subnet
   4. nat instance from private to public subnet
   5. nat instance from data to private subnet
3. Deploy bastion instance with the following requirements:
   1. Target subnet: private subnet
   2. Security group with rules:
      1. outbond allow all ports to all destination
   3. Deploy bastion-role
   4. Deploy bastion-profile allowed to assumed role to bastion-role above
   5. Attach policy AmazonSSMManagedInstanceCore to bastion-role above so we can open AWS SSM access to bastion server
4. SSM to bastion server, then do the following steps
   1. Install gh cli
   2. Install python3
   3. Install python3-pip
   4. Install ansible
   5. change user from ssm-user to `ec2-user`
   6. generate ssh keypair
   7. Copy generate ssh public key to note text.
5. Deploy Elasticsearch nodes
   1. Add ssh pub key of bastion in previous note text to all elasticsearch instance
