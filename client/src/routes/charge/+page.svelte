<script lang="ts">
    import { onMount } from "svelte";
    import { loadStripe } from "@stripe/stripe-js";
    import { getToastStore } from "@skeletonlabs/skeleton";

    export let data;
    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    let stripe, cardElement, cardholderName = '';
    let clientSecret;
    let chargeAmount = 0;
    let currentBalance = 0; // This should be fetched from the database
    let loading = false;
    const toastStore = getToastStore();

    onMount(async () => {
        if (!session) {
            window.location.href = '/login';
            return;
        }
        try {
            stripe = await loadStripe("pk_test_51PkLnw2KUA1QbNc3O3b8MeCdAYzCvGXvzprWy7iU4EZ6iWIOBCYq3yATCQtltpiGNtSDxeojDgQghMEdFezs84B500tQXbl2wg");
            const elements = stripe.elements();
            cardElement = elements.create('card');
            cardElement.mount('#card-element');
            await fetchCurrentBalance();
        } catch (error) {
            console.error("Stripe setup error:", error);
            toastStore.trigger({
                background: "variant-filled-error",
                message: "Failed to initialize payment. Please try again.",
            });
        }
    });

    async function fetchCurrentBalance() {
        const { data: user, error } = await supabase
            .from("users")
            .select("balance")
            .eq("user_id", session.user.id)
            .single();

        if (error) {
            console.error("Error fetching balance:", error);
        } else {
            currentBalance = user.balance || 0;
        }
    }

    async function handlePayment() {
        loading = true;
        try {
            await createPaymentIntent();  // Create payment intent before confirming payment
            const { error, paymentIntent } = await stripe.confirmCardPayment(clientSecret, {
                payment_method: {
                    card: cardElement,
                    billing_details: { name: cardholderName }
                },
            });

            if (error) {
                console.error("Payment failed:", error.message);
                toastStore.trigger({
                    background: "variant-filled-error",
                    message: `Payment failed: ${error.message}`,
                });
            } else {
                console.log("Payment succeeded:", paymentIntent.id);
                toastStore.trigger({
                    background: "variant-filled-success",
                    message: "Payment successful and balance updated!",
                });
                await updateBalance();
            }
        } catch (error) {
            console.error("Error confirming payment:", error);
            toastStore.trigger({
                background: "variant-filled-error",
                message: "An error occurred during payment. Please try again.",
            });
        } finally {
            loading = false;
        }
    }

    async function createPaymentIntent() {
        const response = await fetch('http://localhost:5000/create-payment-intent', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ amount: chargeAmount * 100 }), // Convert to cents
        });

        const data = await response.json();
        if (data.clientSecret) {
            clientSecret = data.clientSecret;
        } else {
            throw new Error("Failed to create payment intent");
        }
    }

    async function updateBalance() {
        await supabase
            .from("users")
            .update({ balance: currentBalance + chargeAmount })
            .eq("user_id", session.user.id);
        currentBalance += chargeAmount;  // Update balance locally
    }
</script>




<style>
    .charge-container {
        background-color: #2D2F48; /* Similar deep blue background */
        color: #fff; /* White text color */
        border-radius: 16px; /* Rounded corners */
        box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2); /* Subtle shadow */
        padding: 2rem; /* Spacious padding */
        max-width: 600px; /* Limit maximum width */
        margin: 2rem auto; /* Centering the card */
    }

    label {
        font-size: 0.9rem;
        color: #ddd; /* Lighter grey for text */
    }

    input, .StripeElement {
        background-color: #404265; /* Slightly lighter blue background for inputs */
        border: none; /* No border */
        border-radius: 8px; /* Rounded corners for inputs */
        color: #fff; /* White text color */
        padding: 12px; /* Comfortable padding */
        margin-top: 0.5rem; /* Space above */
        width: 100%; /* Full width */
    }

    button {
        width: 100%; /* Full width */
        padding: 12px; /* Comfortable padding */
        margin-top: 1rem; /* Space above */
        border: none; /* No border */
        border-radius: 8px; /* Rounded corners */
        font-weight: bold; /* Bold font for buttons */
        cursor: pointer; /* Pointer cursor on hover */
        transition: background-color 0.3s; /* Smooth transition for background color */
    }

    .btn-prepare {
        background-color: #4C51BF; /* Vibrant blue for primary action */
    }

    .btn-prepare:hover {
        background-color: #5A67D8; /* Slightly lighter blue on hover */
    }

    .btn-confirm {
        background-color: #48BB78; /* Green for confirmation actions */
    }

    .btn-confirm:hover {
        background-color: #38A169; /* Slightly darker green on hover */
    }
</style>

<div class="charge-container">
    <h2 class="text-2xl font-bold mb-4 text-center">Charge Your Account</h2>
    <div class="mb-4">
        <label>Current Balance</label>
        <input
            type="text"
            value={`$${currentBalance.toFixed(2)}`}
            disabled
        />
    </div>
    <div class="mb-4">
        <label>Cardholder Name</label>
        <input
            type="text"
            bind:value={cardholderName}
            placeholder="Name on card"
        />
    </div>
    <div class="mb-4">
        <label>Amount to Charge</label>
        <input
            type="number"
            bind:value={chargeAmount}
            placeholder="Amount in $"
            min="1"
            step="0.01"
        />
    </div>
    <div class="mb-6">
        <label>Card Details</label>
        <div id="card-element"></div>
    </div>
    <button
        class="btn-confirm w-full bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
        on:click={handlePayment}
        disabled={loading}
    >
        {#if loading}
            <span>Loading...</span>
        {:else}
            Confirm Payment
        {/if}
    </button>
</div>
