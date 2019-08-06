#!/bin/bash

# You need configure your AWS acccess-key and secret-key
aws configure
# ---- AWS S3 Section ----

# Create S3 Bucket 
S3=`aws s3api create-bucket --bucket nginxdatatflash8 --acl public-read --region us-east-1`

# Replace bucket name 
sed 's/\[\[YOUR-BUCKET-NAME\]\]/nginxdatatflash8/g' s3-template.json > s3.json
rm -f s3-template.json

# Apply policy to bucket
aws s3api put-bucket-policy --bucket nginxdatatflash8 --policy file://s3.json

# Upload index.html to S3 Bucket
TO_S3=`aws s3 cp index.html s3://nginxdatatflash8/index.html`

# ---- EC2 Section ----

# Created new security group
SG_ID=`aws ec2 create-security-group --group-name SoftServe-SG --description "Security-group for SoftServe TechTask" --output text`

# Create new key-pair 
aws ec2 create-key-pair --key-name ssh_id > ssh_id.pem
chmod 400 ssh_id.pem

# Allow http traffic 
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0

# Describe Image-Id 
IMAGE_ID=`aws ec2 describe-images --owners amazon --filters Name=root-device-type,Values=ebs Name=architecture,Values=x86_64 Name=name,Values='amzn2-ami-hvm-2.0.????????-x86_64-gp2' Name=virtualization-type,Values=hvm --query 'sort_by(Images, &Name)[-1].ImageId' --output text`

# Created EC2 Instance with Image-Id
RUN_EC2=`aws ec2 run-instances --image-id $IMAGE_ID --count 1 --instance-type t2.micro --key-name ssh_id --security-group-ids $SG_ID --user-data file://user-data.txt`