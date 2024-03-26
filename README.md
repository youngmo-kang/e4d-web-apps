# Einstein for Developer

This repo contains automated scripts for generating a report from a given list of input prompts. It consists of Flutter front-end web app and backend proxy for circumventing [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) restrictions.

## Deploy locally
```shell
docker build -t e4d-app .
docker run -p 8080:80 -p 8000:8000 --rm e4d-app
```
Open up [http://127.0.0.1:8080](http://127.0.0.1:8080) on a web browser.

## Deploy on GCP
```shell
 gcloud builds submit --tag gcr.io/salesforce-research-internal/$USER/e4d-report
 
 ```