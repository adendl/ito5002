<script>
    import { loadStripe } from "@stripe/stripe-js";
    import { onMount } from "svelte";

    let stripe;
    let cardElement;
    let clientSecret;
    let cardHolderName = "";

    onMount(async () => {
        try {
            console.log("Loading Stripe...");
            stripe = await loadStripe('pk_test_51PkLnw2KUA1QbNc3O3b8MeCdAYzCvGXvzprWy7iU4EZ6iWIOBCYq3yATCQtltpiGNtSDxeojDgQghMEdFezs84B500tQXbl2wg');
            const elements = stripe.elements();
            cardElement = elements.create('card');
            cardElement.mount('#card-element');
            console.log("Stripe loaded and card element mounted.");
        } catch (error) {
            console.error("Error loading Stripe or mounting card element:", error);
        }
    });

    async function handlePayment() {
        try {
            console.log("Confirming card payment...");
            const { error, paymentIntent } = await stripe.confirmCardPayment(clientSecret, {
                payment_method: {
                    card: cardElement,
                    billing_details: {
                        name: cardHolderName,
                    },
                },
            });

            if (error) {
                console.error("Payment failed:", error.message);
                alert("Payment failed: " + error.message);
            } else {
                console.log("Payment succeeded:", paymentIntent);
                alert("Payment succeeded!");
                // Perform any post-payment actions here, like updating booking status
            }
        } catch (error) {
            console.error("Error during payment confirmation:", error);
        }
    }

    async function initiatePayment() {
        try {
            console.log("Initiating payment...");
            const response = await fetch('http://localhost:5000/create-payment-intent', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ amount: 1000 }), // Example amount
            });

            const data = await response.json();
            console.log("Payment intent response:", data);

            if (data.clientSecret) {
                clientSecret = data.clientSecret;
                console.log("Client secret received.");
            } else {
                console.error("Failed to create payment intent.");
                alert("Failed to create payment intent");
            }
        } catch (error) {
            console.error("Error initiating payment:", error);
        }
    }
</script>

<div>
    <input type="text" bind:value={cardHolderName} placeholder="Cardholder Name" />
    <div id="card-element"></div>
    <button on:click={handlePayment}>Pay Now</button>
</div>

<style>
    #card-element {
        border: 1px solid #e0e0e0;
        padding: 10px;
        border-radius: 4px;
    }
</style>
