gcloud config set project quiz-49abd
gcloud builds submit --tag gcr.io/quiz-49abd/quiz_app
gcloud run deploy quiz-service --image gcr.io/quiz-49abd/quiz_app --platform managed --region us-central1 --allow-unauthenticated
