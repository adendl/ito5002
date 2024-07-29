<script>
    import { getModalStore, getToastStore } from "@skeletonlabs/skeleton";
    import WeekTableBooking from "$lib/WeekTableBooking.svelte";
    import WeekTableDummy from "$lib/WeekTableDummy.svelte";
    import RateUserModal from "$lib/RateUserModal.svelte";
    import { onMount, onDestroy } from "svelte";
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

    onMount(async () => {
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
        const listing_id = $modalStore[0].meta.listing_id;
        const { data, error } = await supabase
            .from("availabilities")
            .select("*")
            .eq("listing_id", listing_id)
            .gte("start_time", startDate)
            .lte("start_time", endDate);
        let rawAvailabilities = data;
        let availabilityIds = rawAvailabilities.map(
            (availability) => availability.availability_id,
        );

        // Get already requested availabilities to exclude
        if (availabilityIds) {
            const { data: bookingData, error: bookingError } = await supabase
                .from("booking_requests")
                .select("*")
                .in("availability_id", availabilityIds)
                .eq("booking_user_id", session.user.id);
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
    }

    function objectListToDisplayArray(objectList) {
        // Convert object list to display array
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

    // Submit booking request
    async function requestBooking() {
        console.log("Requesting booking");
        console.log(bookingRequests);
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
        console.log(bookingRequests);
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
            <p class="pt-1">{$modalStore[0].meta.address}</p>
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
            <button
                class="btn mt-4 mb-0 variant-filled-primary rounded-full"
                on:click={requestBooking}
            >
                Request booking
            </button>
        </div>
    </div>
{/if}
