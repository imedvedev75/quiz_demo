# Quiz Demo

## Overview

This is a demonstration of the Quiz application which consists of a server-side component and a client-side component.

## Server

Code is written in Python/Flask.

### Deployment

To publish the server, for instance, to Google Cloud, use the following sample commands:

```
cd server
gcloud config set project quiz-49abd
gcloud builds submit --tag gcr.io/quiz-49abd/quiz_app
gcloud run deploy quiz-service --image gcr.io/quiz-49abd/quiz_app --platform managed --region us-central1 --allow-unauthenticated
```

### Deployed GCR Cloud Instance:

You can access the running GCR server instance at:

https://quiz-service-2fcpeakuua-uc.a.run.app/


## Client Application

Code: Flutter Web.

### Deployment

* update assets/config.json with the backend URL, if necessary.
* Build the app:
```
 flutter build web --release 
```
* upload the content of build/web to the preferred hosting.

### Live demo:

https://imedvedev75.github.io/quiz/


