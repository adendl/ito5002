import stripe
from flask import Flask, request, jsonify
from dotenv import load_dotenv
import os

load_dotenv()

app = Flask(__name__)
stripe.api_key = os.getenv('SECRET_API')
expected_api_key = os.getenv('API_KEY')

print("application booting")


# Retrieve the API key from environment variables
expected_api_key = os.getenv('API_KEY')

def require_api_key(func):
    def wrapper(*args, **kwargs):
        # Get the API key from the request headers
        api_key = request.headers.get('X-API-KEY')

        # Check if the API key is valid
        if api_key != expected_api_key:
            return jsonify({'status': 'failure', 'error': 'Invalid API Key'}), 401

        # Proceed if the API key is valid
        return func(*args, **kwargs)

    # Preserve function name and docstring
    wrapper.__name__ = func.__name__
    wrapper.__doc__ = func.__doc__

    return wrapper

@app.route('/charge', methods=['POST'])
@require_api_key
def charge():
    try:
        # Parse the JSON request
        data = request.json
        amount = data['amount']  # Amount in cents
        currency = data['currency']
        description = data['description']
        payment_method_id = data['paymentMethodId']

        # Create a payment
        payment_intent = stripe.PaymentIntent.create(
            amount=amount,
            currency=currency,
            payment_method=payment_method_id,
            description=description,
            confirm=True,
            automatic_payment_methods={
                'enabled': True,
                'allow_redirects': 'never'
            }
        )

        return jsonify({'status': 'success', 'client_secret': payment_intent['client_secret']}), 200

    except stripe.error.StripeError as e:
        # Handle Stripe API errors
        return jsonify({'status': 'failure', 'error': str(e)}), 400
    except Exception as e:
        # Handle general errors
        return jsonify({'status': 'failure', 'error': str(e)}), 500

if __name__ == '__main__':
    app.run(port=5000, debug=True)