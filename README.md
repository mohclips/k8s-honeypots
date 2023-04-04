# kubernetes honeypots

Based on:  https://github.com/qeeqbox/honeypots

How i set up a private repo, minikube and minikube ingest to test the qeeqbox honeypots.


# set up a local private docker registry

## install docker

eg. https://r2schools.com/how-to-install-docker-on-ubuntu/


## set up local registry

```
# vi /etc/docker/daemon.json 
{ 
	"insecure-registries": ["private-repo:5000"] 
}

# systemctl restart docker

$ docker run -d -p 5000:5000 --restart always --name registry registry:2
```

### add a private-repo IP address as localhost
```
# vi /etc/hosts
127.0.0.1       localhost private-repo

```

### list repos
```
$ curl http://private-repo:5000/v2/_catalog
{"repositories":["honeypots"]}

$ curl http://private-repo:5000/v2/honeypots/tags/list
{"name":"honeypots","tags":["latest"]}

```

# k8s

## install minikube

https://minikube.sigs.k8s.io/docs/start/

### minikube kubectl alias

```
$ alias mk='minikube kubectl --'
```

## install skaffold

https://skaffold.dev/docs/install/

## install honeypots

```
$ skaffold run 
```

At this point you can only access the honeypots from inside the cluster.

```
$ mk -n honeypots get deployment honeypots -ojson | jq '.spec.template.spec.containers[0].ports'

[
  {
    "containerPort": 3306,
    "name": "mysql",
    "protocol": "TCP"
  },
  {
    "containerPort": 445,
    "name": "smb",
    "protocol": "TCP"
  },
  {
    "containerPort": 21,
    "name": "ftp",
    "protocol": "TCP"
  },
  {
    "containerPort": 5432,
    "name": "postgres",
    "protocol": "TCP"
  },
  {
    "containerPort": 6379,
    "name": "redis",
    "protocol": "TCP"
  },
  {
    "containerPort": 22,
    "name": "ssh",
    "protocol": "TCP"
  },
  {
    "containerPort": 9200,
    "name": "elastic",
    "protocol": "TCP"
  },
  {
    "containerPort": 3389,
    "name": "rdp",
    "protocol": "TCP"
  },
  {
    "containerPort": 23,
    "name": "telnet",
    "protocol": "TCP"
  },
  {
    "containerPort": 5900,
    "name": "vnc",
    "protocol": "TCP"
  }
]
```

```
$ mk -n honeypots get po -ojson | jq '.items[0].status | .podIP'
"10.244.0.7"

```


## setup minikube ingest

```
$ minikube addons enable ingress

$ mk -n ingress-nginx apply -f minikube-ingress-configmap.yaml

$ mk patch deployment ingress-nginx-controller --patch "$(cat minikube-ingress-nginx-controller-patch.yaml)" -n ingress-nginx
```

# Test

## get miniube ip

```
$ minikube ip
192.168.49.2
```

```
$ ssh 192.168.49.2
The authenticity of host '192.168.49.2 (192.168.49.2)' can't be established.
RSA key fingerprint is SHA256:g3pWPMKAYWBEqAt9WC19xk+V0gujPJ1QNo//s3qMopg.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.49.2' (RSA) to the list of known hosts.
Connection to 192.168.49.2 closed.

```

```
$ mk -n honeypots logs deployment/honeypots --follow
[!] For updates, check https://github.com/qeeqbox/honeypots
[x] config.json file overrides --ip, --port, --username and --password
[x] Parsing honeypot [normal]
[x] Parsing honeypot [normal]
[x] Parsing honeypot [normal]
[x] Parsing honeypot [normal]
[x] Parsing honeypot [normal]
[x] Parsing honeypot [normal]
[x] Parsing honeypot [normal]
[x] Parsing honeypot [normal]
[x] Parsing honeypot [normal]
[x] Parsing honeypot [normal]
{"action": "connection", "dest_ip": "0.0.0.0", "dest_port": "22", "protocol": "ssh", "src_ip": "10.244.0.6", "src_port": "57242", "timestamp": "2023-04-04T20:31:15.871860"}
{"action": "login", "dest_ip": "0.0.0.0", "dest_port": "22", "key_fingerprint": "9838df3bfb8c7875ef7a1898e6f01069", "protocol": "ssh", "src_ip": "10.244.0.6", "src_port": "57242", "timestamp": "2023-04-04T20:31:17.751536", "username": "nick"}
{"action": "login", "dest_ip": "0.0.0.0", "dest_port": "22", "key_fingerprint": "9838df3bfb8c7875ef7a1898e6f01069", "protocol": "ssh", "src_ip": "10.244.0.6", "src_port": "57242", "timestamp": "2023-04-04T20:31:17.756128", "username": "nick"}
```
