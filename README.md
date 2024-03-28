# Einstein for Developer

This repo contains a web app for generating a report from a given list of input prompts. It consists of Flutter front-end web app run on Nginx server with [reverse proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/) for bypassing [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS).

## Deploy
Make sure to update the endpoint of the server in nginx [config](./default.conf) file.

### Deploy locally
```shell
docker build -t e4d-app .
docker run -p 80:80 --rm e4d-app
```
Open up [http://127.0.0.1](http://127.0.0.1) on a web browser.

### Deploy on GCP
```shell
gcloud builds submit --tag gcr.io/salesforce-research-internal/$USER/e4d-report
cat pod.yaml | sed "s/ALIAS/$USER/g" | kubectl create -f -
cat service.yaml | sed "s/ALIAS/$USER/g" | kubectl create -f -
```

By default, only those on Cisco Anyconnect VPN can access the web. In order for Zscaler users to access the web, consult help on [#research-gcp](https://salesforce.enterprise.slack.com/archives/C02P4NG66PN) channel.