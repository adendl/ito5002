from flask import Flask, request, jsonify
import stripe
from dotenv import load_dotenv
import os

load_dotenv()
app = Flask(__name__)

stripe.api_key = os.getenv('STRIPE_API')

@app.route('/create-payment-intent', methods=['POST'])
def create_payment_intent():
    try:
        data = request.get_json()
        amount = data['amount']  # The amount to charge
        payment_intent = stripe.PaymentIntent.create(
            amount=amount,
            currency='usd',
            payment_method_types=['card']
        )
        return jsonify({'clientSecret': payment_intent['client_secret']})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

if __name__ == '__main__':
    app.run(port=5000, debug=True)
