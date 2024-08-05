<script>
    import { getModalStore, getToastStore } from "@skeletonlabs/skeleton";
    import WeekTableBooking from "$lib/WeekTableBooking.svelte";
    import WeekTableDummy from "$lib/WeekTableDummy.svelte";
    import RateUserModal from "$lib/RateUserModal.svelte";
    import { onMount } from "svelte";
    import { loadStripe } from "@stripe/stripe-js";

    const modalStore = getModalStore();
    const toastStore = getToastStore();
    let data = $modalStore[0].meta.data;
    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    let selectedDate = new Date().toISOString().split("T")[0];
    let startDate;
    let endDate;
    let availabilities;
    let alreadyRequested;
    let bookingRequests = [];
    let loaded = false;

    // Stripe initialization
    let stripe;
    let clientSecret;
    let cardElement;
    let elements;
    let cardHolderName = "";

    onMount(async () => {
        try {
            console.log("Initializing Stripe...");
            stripe = await loadStripe('pk_test_51PkLnw2KUA1QbNc3O3b8MeCdAYzCvGXvzprWy7iU4EZ6iWIOBCYq3yATCQtltpiGNtSDxeojDgQghMEdFezs84B500tQXbl2wg');
            elements = stripe.elements();
            cardElement = elements.create('card');
            cardElement.mount('#card-element');
            console.log("Stripe initialized and card element mounted.");
            await getAvailabilityInWindow();
        } catch (error) {
            console.error("Error during Stripe initialization or availability fetching:", error);
        }
    });

    $: selectedDate, getAvailabilityInWindow();

    function getStartEndDate() {
        let dateWindow = Array.from({ length: 7 }, (_, i) => {
            let date = new Date(selectedDate);
            date.setDate(date.getDate() + i - date.getDay());
            return date;
        });
        startDate = dateWindow[0].toISOString().split("T")[0] + "T00:00:00+10";
        endDate = dateWindow[6].toISOString().split("T")[0] + "T23:59:59+10";
    }

    async function getAvailabilityInWindow() {
        try {
            loaded = false;
            getStartEndDate();
            const listing_id = $modalStore[0].meta.listing_id;
            console.log(`Fetching availabilities for listing ID: ${listing_id}`);
            const { data, error } = await supabase
                .from("availabilities")
                .select("*")
                .eq("listing_id", listing_id)
                .gte("start_time", startDate)
                .lte("start_time", endDate);

            if (error) {
                console.error("Error fetching availabilities:", error);
                return;
            }

            let rawAvailabilities = data;
            let availabilityIds = rawAvailabilities.map(
                (availability) => availability.availability_id,
            );

            if (availabilityIds) {
                const { data: bookingData, error: bookingError } = await supabase
                    .from("booking_requests")
                    .select("*")
                    .in("availability_id", availabilityIds)
                    .eq("booking_user_id", session.user.id);

                if (bookingError) {
                    console.error("Error fetching booking requests:", bookingError);
                    return;
                }

                let alreadyRequested = bookingData.map(
                    (booking) => booking.availability_id,
                );
                if (rawAvailabilities && alreadyRequested) {
                    rawAvailabilities = rawAvailabilities.filter(
                        (availability) =>
                            !alreadyRequested.includes(
                                availability.availability_id,
                            ),
                    );
                }
            }
            availabilities = objectListToDisplayArray(rawAvailabilities);
            loaded = true;
        } catch (error) {
            console.error("Error during availability fetching:", error);
        }
    }

    function objectListToDisplayArray(objectList) {
        let displayArray = Array.from({ length: 7 }).map(() =>
            Array.from({ length: 6 }).map(() => false),
        );
        if (objectList) {
            objectList.forEach((object) => {
                let date = new Date(object.start_time);
                let day = date.getDay();
                let hour = date.getHours();
                displayArray[day][hour / 4] = {
                    state: true,
                    attributes: object,
                };
            });
        }
        return displayArray;
    }

    async function requestBooking() {
        try {
            console.log("Requesting booking", bookingRequests);
            if (bookingRequests.length === 0) {
                toastStore.trigger({
                    background: "variant-filled-warning",
                    message: "Please select at least one time slot to book",
                });
                return;
            }
            bookingRequests.forEach((bookingRequest) => {
                bookingRequest.booking_user_id = session.user.id;
            });

            const amount = $modalStore[0].meta.price_per_hour * bookingRequests.length * 100; // Amount in cents
            console.log(`Creating payment intent for amount: ${amount}`);
            await createPaymentIntent(amount);

            // Trigger payment after confirming the booking
            const paymentSuccess = await handlePayment();

            if (paymentSuccess) {
                const { data, error } = await supabase
                    .from("booking_requests")
                    .insert(bookingRequests);
                if (error) {
                    toastStore.trigger({
                        background: "variant-filled-error",
                        message: error.message,
                    });
                } else {
                    toastStore.trigger({
                        background: "variant-filled-success",
                        message: "Booking request submitted",
                    });
                    modalStore.close();
                }
            } else {
                toastStore.trigger({
                    background: "variant-filled-error",
                    message: "Payment failed. Please try again.",
                });
            }
        } catch (error) {
            console.error("Error during booking request:", error);
        }
    }

    async function handlePayment() {
        try {
            console.log("Handling payment with Stripe...");
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
                return false;
            } else {
                console.log("Payment succeeded!", paymentIntent.id);
                alert("Payment succeeded!");
                return true;
            }
        } catch (error) {
            console.error("Error during payment handling:", error);
            return false;
        }
    }

    async function createPaymentIntent(amount) {
        try {
            const response = await fetch('http://localhost:5000/create-payment-intent', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ amount }),
            });

            const data = await response.json();
            console.log("Received payment intent:", data);

            if (data.clientSecret) {
                clientSecret = data.clientSecret;
                console.log("Client secret set.");
            } else {
                console.error("Error creating payment intent", data.error);
            }
        } catch (error) {
            console.error("Error creating payment intent:", error);
        }
    }

    // Elements for RateUserModal
    const userName = $modalStore[0].meta.user_name;
    const rating = $modalStore[0].meta.rating || "?";
    const rateUserModalRef = { ref: RateUserModal };
    const rateUserModal = {
        type: "component",
        component: rateUserModalRef,
        meta: {
            userName,
            rating,
        },
    };
    function triggerRateUserModal() {
        modalStore.close();
        modalStore.trigger(rateUserModal);
    }
</script>

{#if $modalStore[0]}
    <div class="card m-4 p-4 w-3/5">
        <div class="w-full items-center text-center">
            <h2 class="h4 mb-2">Book charging time</h2>
        </div>
        <div class="w-full text-center">
            <h3 class="h4 mb-2">
                {$modalStore[0].meta.suburb}: Mode {$modalStore[0].meta
                    .charging_mode} - {$modalStore[0].meta.charger_type} @ ${$modalStore[0]
                    .meta.price_per_hour} per hour
            </h3>
            {#if $modalStore[0].meta.address}
                <p class="pt-1">{$modalStore[0].meta.address}</p>
            {/if}
            <p>
                <u on:click={triggerRateUserModal}>{userName}</u>
                <i class="fa-solid fa-star"></i>
                {rating}
            </p>
        </div>
        {#if loaded}
            <div class="w-full flex justify-center m-auto my-2">
                <WeekTableBooking
                    bind:targetDate={selectedDate}
                    bind:availabilities
                    bind:alreadyRequested
                    bind:bookingRequests
                />
            </div>
        {:else}
            <div class="w-full flex justify-center m-auto my-2">
                <WeekTableDummy targetDate={selectedDate} />
            </div>
        {/if}
        <div class="w-full flex justify-center m-auto">
            <label>
                <span>Card Holder Name</span>
                <input type="text" bind:value={cardHolderName} placeholder="Name" />
            </label>
            <div id="card-element" class="mt-2"></div>
            <button
                class="btn mt-4 mb-0 variant-filled-primary rounded-full"
                on:click={requestBooking}
            >
                Request booking and pay
            </button>
        </div>
    </div>
{/if}

<style>
    #card-element {
        border: 1px solid #e0e0e0;
        padding: 10px;
        border-radius: 4px;
    }
</style>
