import os
from flask import Flask, request, jsonify
import stripe
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Load environment variable directly if available, otherwise load from .env file
if 'SECRET_API' in os.environ:
    stripe.api_key = os.getenv('SECRET_API')
else:
    from dotenv import load_dotenv
    load_dotenv()  # Load environment variables from .env file
    stripe.api_key = os.getenv('SECRET_API')

@app.route('/create-payment-intent', methods=['POST'])
def create_payment_intent():
    try:
        data = request.get_json()
        amount = data['amount']
        payment_intent = stripe.PaymentIntent.create(
            amount=amount,
            currency='aud',
            payment_method_types=['card']
        )
        return jsonify({'clientSecret': payment_intent['client_secret']})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

if __name__ == '__main__':
    app.run(port=5000, debug=True)
