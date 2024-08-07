<script>
    import { onMount } from "svelte";
    import { loadStripe } from "@stripe/stripe-js";
    import { getModalStore, getToastStore } from "@skeletonlabs/skeleton";

    let stripe, cardElement;
    let clientSecret;
    const modalStore = getModalStore();
    let totalAmount = 50; // Assume this is passed in or correctly set before use

    onMount(async () => {
        try {
            stripe = await loadStripe("pk_test_51PkLnw2KUA1QbNc3O3b8MeCdAYzCvGXvzprWy7iU4EZ6iWIOBCYq3yATCQtltpiGNtSDxeojDgQghMEdFezs84B500tQXbl2wg");
            const elements = stripe.elements();
            cardElement = elements.create('card');
            // Mount card element in the next tick to ensure the DOM is ready
            setTimeout(() => cardElement.mount('#card-element'), 0);

            const response = await fetch('http://localhost:5000/create-payment-intent', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ amount: totalAmount * 100 }) // Convert dollars to cents
            });
            const data = await response.json();
            if (data.clientSecret) {
                clientSecret = data.clientSecret;
            } else {
                console.error("Failed to retrieve client secret:", data.error);
            }
        } catch (error) {
            console.error("Error setting up Stripe:", error);
        }
    });

    async function handlePayment() {
        if (!stripe || !clientSecret) {
            console.error("Stripe not initialized or client secret not retrieved.");
            return;
        }

        try {
            const { error, paymentIntent } = await stripe.confirmCardPayment(clientSecret, {
                payment_method: {
                    card: cardElement,
                    billing_details: { name: "Cardholder Name" } // Placeholder for actual cardholder name input
                },
            });

            if (error) {
                console.error("Payment failed:", error.message);
            } else {
                console.log("Payment successful:", paymentIntent.id);
                // Handle successful payment here
            }
        } catch (error) {
            console.error("Error confirming payment:", error);
        }
    }
</script>

<div class="payment-container">
    <div id="card-element"></div>
    <button on:click={handlePayment}>Pay $${(totalAmount / 100).toFixed(2)}</button>
</div>
