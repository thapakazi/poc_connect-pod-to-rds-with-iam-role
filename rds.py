import psycopg2
import sys
import boto3
import os

ENDPOINT="my-server.cluster-random-hash.my-region-1.rds.amazonaws.com"
PORT="5432"
USR="myapp"
REGION="my-region-1"
DBNAME="myapp"

# env varialbes assumend
# AWS_WEB_IDENTITY_TOKEN_FILE
# AWS_ROLE_ARN
session = boto3.Session()
client = session.client('rds')

token = client.generate_db_auth_token(DBHostname=ENDPOINT, Port=PORT, DBUsername=USR, Region=REGION)

try:
    conn = psycopg2.connect(host=ENDPOINT, port=PORT, database=DBNAME, user=USR, password=token)
    cur = conn.cursor()
    cur.execute("""SELECT now()""")
    query_results = cur.fetchall()
    print(query_results)
except Exception as e:
    print("Database connection failed due to {}".format(e))                

# src: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.Connecting.Python.html
