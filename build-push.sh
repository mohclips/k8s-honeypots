#!/bin/bash

set -e 

docker build -t honeypots:latest .

docker tag honeypots:latest localhost:5000/honeypots:latest

docker push localhost:5000/honeypots:latest

