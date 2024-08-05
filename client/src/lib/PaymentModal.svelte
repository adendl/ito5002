<script lang="ts">
    import { onMount } from "svelte";
    import { loadStripe } from "@stripe/stripe-js";

    let stripe;
    let cardElement;
    let elements;

    let clientSecret;
    let cardHolderName = "";

    onMount(async () => {
        stripe = await loadStripe('YOUR_STRIPE_PUBLIC_KEY');
        elements = stripe.elements();

        cardElement = elements.create('card');
        cardElement.mount('#card-element');
    });

    async function handlePayment() {
        const { error, paymentIntent } = await stripe.confirmCardPayment(clientSecret, {
            payment_method: {
                card: cardElement,
                billing_details: {
                    name: cardHolderName,
                },
            },
        });

        if (error) {
            console.error("Payment failed", error.message);
            alert("Payment failed: " + error.message);
        } else {
            console.log("Payment succeeded!", paymentIntent.id);
            alert("Payment succeeded!");
        }
    }

    async function createPaymentIntent(amount) {
        const response = await fetch('http://localhost:5000/create-payment-intent', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ amount }),
        });

        const data = await response.json();
        if (data.clientSecret) {
            clientSecret = data.clientSecret;
        } else {
            console.error("Error creating payment intent", data.error);
        }
    }
</script>

<div class="card m-4 p-4 w-3/5">
    <div class="w-full items-center text-center">
        <h2 class="h4 mb-2">Enter Payment Information</h2>
    </div>
    <div class="grid grid-cols-1 gap-4 items-center">
        <label>
            <span>Card Holder Name</span>
            <input type="text" bind:value={cardHolderName} placeholder="Name" />
        </label>
        <div id="card-element" class="mt-2"></div>
        <button
            class="btn mt-2 variant-filled-primary"
            on:click={handlePayment}
        >
            Pay
        </button>
    </div>
</div>

<style>
    #card-element {
        border: 1px solid #e0e0e0;
        padding: 10px;
        border-radius: 4px;
    }
</style>
