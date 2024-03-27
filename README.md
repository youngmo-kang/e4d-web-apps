# Einstein for Developer

This repo contains automated scripts for generating a report from a given list of input prompts. It consists of Flutter front-end web app and backend proxy for circumventing [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) restrictions.

Make sure to update the endpoint of the server in [proxy/servr.py](proxy/server.py) file.

## Deploy locally
```shell
docker build -t e4d-app .
docker run -p 80:80 --rm e4d-app

cd proxy
docker build -t proxy .
docker run -p 8000:8000 --rm proxy
```
Open up [http://127.0.0.1](http://127.0.0.1) on a web browser.

## Deploy on GCP
```shell
gcloud builds submit --tag gcr.io/salesforce-research-internal/$USER/e4d-report
cat pod.yaml | sed "s/ALIAS/$USER/g" | kubectl create -f -
cat service.yaml | sed "s/ALIAS/$USER/g" | kubectl create -f -

cd proxy
gcloud builds submit --tag gcr.io/salesforce-research-internal/$USER/proxy
cat pod.yaml | sed "s/ALIAS/$USER/g" | kubectl create -f -
cat service.yaml | sed "s/ALIAS/$USER/g" | kubectl create -f -
```