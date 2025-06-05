# File: flask_api/app/utils/firebase_config.py
import firebase_admin
from firebase_admin import credentials, firestore
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv(dotenv_path=os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), '.env'))
# This navigates up from utils -> app -> flask_api to find .env

db = None

def initialize_firebase_admin():
    global db
    if not firebase_admin._apps: # Check if already initialized
        cred_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        if not cred_path:
            raise ValueError("GOOGLE_APPLICATION_CREDENTIALS environment variable not set.")

        # Construct absolute path to serviceAccountKey.json if relative path is used in .env
        # This assumes GOOGLE_APPLICATION_CREDENTIALS in .env is relative to flask_api root
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__))) # flask_api directory
        absolute_cred_path = os.path.join(base_dir, cred_path)

        if not os.path.exists(absolute_cred_path):
            raise FileNotFoundError(f"Service account key not found at: {absolute_cred_path}")

        try:
            cred = credentials.Certificate(absolute_cred_path)
            firebase_admin.initialize_app(cred)
            print("Firebase Admin SDK initialized successfully.")
        except Exception as e:
            print(f"Error initializing Firebase Admin SDK: {e}")
            raise

    db = firestore.client() # Get Firestore client
    print("Firestore client obtained.")