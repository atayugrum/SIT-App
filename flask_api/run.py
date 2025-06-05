# File: flask_api/run.py
from app import create_app
import os

app = create_app()

if __name__ == '__main__':
    # Debug mode can be set via FLASK_DEBUG in .env or here
    debug_mode = os.getenv('FLASK_DEBUG', '0') == '1' 
    print(f"Starting Flask app in debug_mode: {debug_mode}")
    app.run(host='0.0.0.0', port=5000, debug=debug_mode)