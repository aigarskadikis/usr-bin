#!/bin/env python
# Copyright 2010-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# This file is licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the
# License is located at
#
# http://aws.amazon.com/apache2.0/
#
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
# OF ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.
 
# AWS Version 4 signing example
 
# See: http://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html
# This version makes a POST request and passes request parameters
# in the body (payload) of the request. Auth information is passed in
# an Authorization header.
import sys, os, base64, datetime, hashlib, hmac, time
import requests # pip install requests
import logging
import ConfigParser, os

config = ConfigParser.ConfigParser()
config.readfp(open(os.path.expanduser('~/.aws/config')))

region = config.get('default', 'region')

config.readfp(open(os.path.expanduser('~/.aws/credentials')))
access_key = config.get('default', 'aws_access_key_id')
secret_key = config.get('default', 'aws_secret_access_key')
# Read AWS access key and secreate from external file which is coming from the tool 'aws configure'
# by default 'aws configure' will create '/root/.aws/config' and '/root/.aws/credentials'
# do not continue if the credentials file was empty
if access_key is None or secret_key is None:
    print('No access key is available.')
    sys.exit()

 
# ************* REQUEST VALUES *************
method = 'POST'
service = 'monitoring'
host = 'monitoring.'+region+'.amazonaws.com'
endpoint = 'https://monitoring.'+region+'.amazonaws.com/'
time_from = str(int(time.time())-600)
time_till = str(int(time.time())-300)
print (time_from)
print (time_till)
# POST requests use a content type header. For DynamoDB,
# the content is JSON.
content_type = 'application/x-amz-json-1.0'
 
amz_target = 'GraniteServiceVersion20100801.GetMetricData'
 
request_parameters = '{"StartTime":'+time_from+',"EndTime":'+time_till+',"MetricDataQueries":[{"Id":"m1","MetricStat":{"Metric":{"MetricName":"CPUUtilization","Namespace":"AWS/EC2","Dimensions":[{"Name":"InstanceId","Value":"i-0ad4b6cfaf8da800f"}]},"Period":300,"Stat":"Average"}}]}'
 
# Key derivation functions. See:
# http://docs.aws.amazon.com/general/latest/gr/signature-v4-examples.html#signature-v4-examples-python
def sign(key, msg):
    return hmac.new(key, msg.encode("utf-8"), hashlib.sha256).digest()

def getSignatureKey(key, dateStamp, regionName, serviceName):
    kDate = sign(("AWS4" + key).encode("utf-8"), dateStamp)
    kRegion = sign(kDate, regionName)
    kService = sign(kRegion, serviceName)
    kSigning = sign(kService, "aws4_request")
    return kSigning
 
 
# Create a date for headers and the credential string
t = datetime.datetime.utcnow()
amz_date = t.strftime('%Y%m%dT%H%M%SZ')
date_stamp = t.strftime('%Y%m%d') # Date w/o time, used in credential scope
 
 
# ************* TASK 1: CREATE A CANONICAL REQUEST *************
# http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
 
# Step 1 is to define the verb (GET, POST, etc.)--already done.
 
# Step 2: Create canonical URI--the part of the URI from domain to query
# string (use '/' if no path)
canonical_uri = '/'
 
## Step 3: Create the canonical query string. In this example, request
# parameters are passed in the body of the request and the query string
# is blank.
canonical_querystring = ''
 
# Step 4: Create the canonical headers. Header names must be trimmed
# and lowercase, and sorted in code point order from low to high.
# Note that there is a trailing \n.
canonical_headers = 'content-type:' + content_type + '\n' + 'host:' + host + '\n' + 'x-amz-date:' + amz_date + '\n' + 'x-amz-target:' + amz_target + '\n'

print ("canonical_headers")
print (canonical_headers)
# Step 5: Create the list of signed headers. This lists the headers
# in the canonical_headers list, delimited with ";" and in alpha order.
# Note: The request can include any headers; canonical_headers and
# signed_headers include those that you want to be included in the
# hash of the request. "Host" and "x-amz-date" are always required.
# For DynamoDB, content-type and x-amz-target are also required.
signed_headers = 'content-type;host;x-amz-date;x-amz-target'
 
# Step 6: Create payload hash. In this example, the payload (body of
# the request) contains the request parameters.
print ("request parameters")
print ("###################################")
print (request_parameters)
print ("###################################")
 
payload_hash = hashlib.sha256(request_parameters.encode('utf-8')).hexdigest()
print (payload_hash)
# Step 7: Combine elements to create canonical request
canonical_request = method + '\n' + canonical_uri + '\n' + canonical_querystring + '\n' + canonical_headers + '\n' + signed_headers + '\n' + payload_hash
print ("Canonical request")
print ("###############################")
print (canonical_request)
print ('#################################')
 
# ************* TASK 2: CREATE THE STRING TO SIGN*************
# Match the algorithm to the hashing algorithm you use, either SHA-1 or
# SHA-256 (recommended)
algorithm = 'AWS4-HMAC-SHA256'
credential_scope = date_stamp + '/' + region + '/' + service + '/' + 'aws4_request'
string_to_sign = algorithm + '\n' +  amz_date + '\n' +  credential_scope + '\n' +  hashlib.sha256(canonical_request.encode('utf-8')).hexdigest()
print ("String to sign")
print ("##################################")
print (string_to_sign)
print ("##################################")
 
# ************* TASK 3: CALCULATE THE SIGNATURE *************
# Create the signing key using the function defined above.
signing_key = getSignatureKey(secret_key, date_stamp, region, service)
print ("signing key")
print ("##################################")
print (date_stamp)
#print (signing_key)
print (hmac.new(signing_key))
print ("##################################")
 
# Sign the string_to_sign using the signing_key
signature = hmac.new(signing_key, (string_to_sign).encode('utf-8'), hashlib.sha256).hexdigest()
print ("Signature")
print ("##################################")
print (signature)
print ("##################################")
 
 
# ************* TASK 4: ADD SIGNING INFORMATION TO THE REQUEST *************
# Put the signature information in a header named Authorization.
authorization_header = algorithm + ' ' + 'Credential=' + access_key + '/' + credential_scope + ', ' +  'SignedHeaders=' + signed_headers + ', ' + 'Signature=' + signature
 
# For Cloudwatch, the request can include any headers, but MUST include "host", "x-amz-date",
# "x-amz-target", "content-type", and "Authorization". Except for the authorization
# header, the headers must be included in the canonical_headers and signed_headers values, as
# noted earlier. Order here is not significant.
# # Python note: The 'host' header is added automatically by the Python 'requests' library.
headers = {'Content-Type':content_type,
           'X-Amz-Date':amz_date,
           'X-Amz-Target':amz_target,
           'Authorization':authorization_header}
print ("headers")
print ("#########################################################")
print (headers)
print ("#########################################################")
print ("request_parameters")
print ("#########################################################")
print (request_parameters)
print ("#########################################################")
# ************* SEND THE REQUEST *************
print('\nBEGIN REQUEST++++++++++++++++++++++++++++++++++++')
print('Request URL = ' + endpoint)
 
r = requests.post(endpoint, data=request_parameters, headers=headers)
 
print('\nRESPONSE++++++++++++++++++++++++++++++++++++')
print('Response code: %d\n' % r.status_code)
print(r.text)

