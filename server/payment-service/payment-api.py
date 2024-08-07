from flask import Flask, request, jsonify
import stripe
from dotenv import load_dotenv
import os
from flask_cors import CORS

# Load environment variables from .env file
load_dotenv()

# Initialize Flask app and enable CORS
app = Flask(__name__)
CORS(app)

# Set Stripe API key
stripe.api_key = os.getenv('SECRET_API')

@app.route('/create-payment-intent', methods=['POST'])
def create_payment_intent():
    try:
        data = request.get_json()
        print("Request data:", data)  # Print the request data to the console

        amount = data['amount']  # The amount to charge in cents
        payment_intent = stripe.PaymentIntent.create(
            amount=amount,
            currency='aud',
            payment_method_types=['card']
        )
        # Correctly access the client secret
        return jsonify({'clientSecret': payment_intent['client_secret']})
    except Exception as e:
        print("Error:", str(e))  # Print any exceptions to the console
        return jsonify({'error': str(e)}), 400

if __name__ == '__main__':
    app.run(port=5000, debug=True)
