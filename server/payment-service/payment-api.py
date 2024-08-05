import stripe
from flask import Flask, request, jsonify
from dotenv import load_dotenv
import os

load_dotenv()

app = Flask(__name__)
stripe.api_key = os.getenv('SECRET_API')

@app.route('/create-payment-intent', methods=['POST'])
def create_payment():
    data = request.get_json()
    try:
        # Calculate the order amount and create a PaymentIntent
        payment_intent = stripe.PaymentIntent.create(
            amount=calculate_order_amount(data),  # Amount in cents
            currency='usd',
            payment_method=data['paymentMethodId'],
            confirmation_method='manual',
            confirm=True
        )
        return jsonify({'clientSecret': payment_intent['client_secret']})
    except stripe.error.StripeError as e:
        return jsonify({'error': str(e)}), 400

def calculate_order_amount(data):
    return 1099