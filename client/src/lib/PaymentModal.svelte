<script>
    import { onMount } from "svelte";
    import { loadStripe } from "@stripe/stripe-js";
    import { getModalStore, getToastStore } from "@skeletonlabs/skeleton";

  
    let stripe, cardElement, cardholderName = '';
    let clientSecret;
    const modalStore = getModalStore();
    let totalAmount = 50;
    console.log(totalAmount);


    async function stripeInit() {
        console.log("Payment modal loaded");
        console.log("Total amount received in payment modal:", totalAmount);
        try {
            stripe = await loadStripe("pk_test_51PkLnw2KUA1QbNc3O3b8MeCdAYzCvGXvzprWy7iU4EZ6iWIOBCYq3yATCQtltpiGNtSDxeojDgQghMEdFezs84B500tQXbl2wg");
            console.log("Stripe initialized:", stripe); // Check if Stripe is initialized correctly
            const elements = stripe.elements();
            cardElement = elements.create('card', { style: { base: { iconColor: '#c4f0ff', color: '#fff', fontWeight: '500', fontFamily: 'Roboto, Open Sans, Segoe UI, sans-serif', fontSize: '16px', fontSmoothing: 'antialiased', ':-webkit-autofill': { color: '#fce883' }, '::placeholder': { color: '#87bbfd' } }, invalid: { iconColor: '#ffc7ee', color: '#ffc7ee' } } });
            cardElement.mount('#card-element');

            const response = await fetch('http://localhost:5000/create-payment-intent', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ amount: totalAmount }),
            });
            console.log(data);
            const data = await response.json();
            if (data.clientSecret) {
                clientSecret = data.clientSecret;
                console.log("Client secret retrieved:", clientSecret);
            } else {
                console.error("Error fetching client secret:", data.error);
                onPaymentFailure("Failed to initialize payment. Please try again.");
            }
        } catch (error) {
            console.error("Error during Stripe setup:", error);
            onPaymentFailure("Payment initialization failed. Please try again.");
        }
    }

    function onPaymentSuccess() {
        toastStore.trigger({
            background: "variant-filled-success",
            message: "Payment successful and booking confirmed!",
        });
        modalStore.close();
    }

    function onPaymentFailure(message) {
        toastStore.trigger({
            background: "variant-filled-error",
            message: `Payment failed: ${message}`,
        });
    }


    async function handlePayment() {
    if (!stripe) {
        console.error("Stripe is not initialized.");
        return;
    }

    try {
        if (!clientSecret) {
                console.error("Client secret is not set.");
                return;
            }
        const { error, paymentIntent } = await stripe.confirmCardPayment(clientSecret, {
            payment_method: {
                card: cardElement,
                billing_details: { name: cardholderName }
            },
        });

        if (error) {
            console.error("Payment failed:", error.message);
            onPaymentFailure(error.message);
        } else {
            console.log("Payment succeeded:", paymentIntent.id);
            onPaymentSuccess();
        }
    } catch (error) {
        console.error("Error confirming payment:", error);
        onPaymentFailure("An error occurred during payment. Please try again.");
    }
}


</script>

<div class="payment-container bg-white shadow-lg rounded-lg p-8 max-w-md mx-auto">
    <h2 class="text-lg font-semibold text-center mb-6">Complete your payment</h2>
    <button class="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline" on:click={stripeInit}>
        Load
    </button>
    <button class="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline" on:click={handlePayment}>
        Pay ${(totalAmount / 100).toFixed(2)}
    </button>
</div>

<style>
    .payment-container {
        background-color: #f7f9fc;
        border-radius: 8px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }
    #card-element {
        --tw-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
        box-shadow: var(--tw-shadow, 0 1px 2px 0 rgba(0, 0, 0, 0.05));
    }
</style>