<script>
    import { getModalStore, getToastStore } from "@skeletonlabs/skeleton";
    import WeekTableBooking from "$lib/WeekTableBooking.svelte";
    import WeekTableDummy from "$lib/WeekTableDummy.svelte";
    import PaymentModal from "$lib/PaymentModal.svelte";
    import RateUserModal from "$lib/RateUserModal.svelte";
    import { onMount } from "svelte";
    const modalStore = getModalStore();
    const toastStore = getToastStore();

    let data = $modalStore[0]?.meta?.data || {}; // Safely access data
    let { supabase, session } = data;

    let selectedDate = new Date().toISOString().split("T")[0]; // Ensures selectedDate is always defined
    let startDate, endDate;
    let availabilities = [];
    let alreadyRequested = [];
    let bookingRequests = [];
    let loaded = false;


    onMount(async () => {
        console.log("Selected Date:", selectedDate);  // Debug selectedDate
        await getAvailabilityInWindow();
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
        loaded = false;
        getStartEndDate();
        // Get availabilities in window
        const listing_id = $modalStore[0]?.meta?.listing_id;
        if (!listing_id) return; // Check if listing_id is available

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
            (availability) => availability.availability_id
        );

        // Get already requested availabilities to exclude
        if (availabilityIds.length > 0) {
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
                (booking) => booking.availability_id
            );
            if (rawAvailabilities && alreadyRequested) {
                rawAvailabilities = rawAvailabilities.filter(
                    (availability) =>
                        !alreadyRequested.includes(
                            availability.availability_id
                        )
                );
            }
        }
        availabilities = objectListToDisplayArray(rawAvailabilities);
        loaded = true;
    }

    function objectListToDisplayArray(objectList) {
        // Convert object list to display array
        let displayArray = Array.from({ length: 7 }).map(() =>
            Array.from({ length: 6 }).map(() => false)
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

    const paymentModalRef = { ref: PaymentModal };

    async function requestBooking() {
        console.log("Requesting booking");
        console.log("Booking Requests:", bookingRequests);

        if (bookingRequests.length === 0) {
            toastStore.trigger({
                background: "variant-filled-warning",
                message: "Please select at least one time slot to book",
            });
            return;
        }

        bookingRequests.forEach(bookingRequest => {
            bookingRequest.booking_user_id = session.user.id;
        });


        console.log("Triggering Payment Modal");
        console.log(calculateTotalAmount());
        modalStore.close();
        modalStore.trigger({
            type: 'component',
            component: paymentModalRef,
            props: {
                totalAmount: 50,
                onPaymentSuccess: handlePaymentSuccess,
                onPaymentFailure: handlePaymentFailure
            }
        });
    }

    function calculateTotalAmount() {
        return bookingRequests.length * ($modalStore[0]?.meta?.price_per_hour || 0) * 100; // Assuming duration of each booking request is 1 hour
    }

    function handlePaymentSuccess() {
        toastStore.trigger({
            background: "variant-filled-success",
            message: "Payment successful and booking confirmed!",
        });
        modalStore.close();
    }

    function handlePaymentFailure(message) {
        toastStore.trigger({
            background: "variant-filled-error",
            message: `Payment failed: ${message}`,
        });
    }

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
                    bind:availabilities={availabilities} 
                    bind:alreadyRequested={alreadyRequested} 
                    bind:bookingRequests={bookingRequests} 
                />
            </div>
        {:else}
            <div class="w-full flex justify-center m-auto my-2">
                <WeekTableDummy targetDate={selectedDate} />
            </div>
        {/if}
        <div class="w-full flex justify-center m-auto">
            <button
                class="btn mt-4 mb-0 variant-filled-primary rounded-full"
                on:click={requestBooking}
            >
                Request booking
            </button>
        </div>
    </div>
{/if}
