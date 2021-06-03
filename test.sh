#!/bin/bash

# note: this script it just created to test if i could
# pull temporary iam service account token from pod
# to localhost and try connect to rds with it
# luck me it works :D

WD=/tmp/.aws && mkdir -p $WD
export AWS_ROLE_ARN=arn:aws:iam::${ACCOUNT_ID}:role/-eks-web-identity-role
export AWS_WEB_IDENTITY_TOKEN_FILE=$WD/token

# sealing temporary token from pods upstream :D
kubectl exec  deploy/myapp-with-iam-role-attached -- cat /var/run/secrets/eks.amazonaws.com/serviceaccount/token > $WD/token 

# assuming role and fethcing the temp creds
# ref: https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts
aws sts assume-role-with-web-identity \
  --role-arn $AWS_ROLE_ARN \
  --role-session-name mh9test \
  --web-identity-token file://$AWS_WEB_IDENTITY_TOKEN_FILE \
  --duration-seconds 1000 > /tmp/irp-cred.txt

# exporting context to those credentials
export AWS_ACCESS_KEY_ID="$(cat /tmp/irp-cred.txt | jq -r ".Credentials.AccessKeyId")"
export AWS_SECRET_ACCESS_KEY="$(cat /tmp/irp-cred.txt | jq -r ".Credentials.SecretAccessKey")"
export AWS_SESSION_TOKEN="$(cat /tmp/irp-cred.txt | jq -r ".Credentials.SessionToken")"

# ask awsk, who i am now ?
aws sts get-caller-identity

# ok, this is just optional thing 
wget https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem -O /tmp/rds-combined-ca-bundle.pem

# this is fancy, 
export RDSHOST=my-server.cluster-random-hash.my-region-1.rds.amazonaws.com
export RDSUSER=rdsuser
PGPASSWORD="$(aws rds generate-db-auth-token --hostname $RDSHOST --port 5432 --region my-region-1 --username $RDSUSER)"
psql "host=$RDSHOST port=5432 sslmode=verify-full sslrootcert=/tmp/rds-combined-ca-bundle.pem dbname=myapp user=$RDSUSER password=$PGPASSWORD"
