<script lang="ts">
    import { onMount } from "svelte";
    import { getModalStore, getToastStore } from "@skeletonlabs/skeleton";

    // Props passed to the component
    export let listingId: string;
    export let supabase;
    export let session;

    // Modal and Toast stores for UI feedback
    const modalStore = getModalStore();
    const toastStore = getToastStore();

    // Data for booking
    let bookingDate: string = new Date().toISOString().split("T")[0];
    let startTime: string = "";
    let endTime: string = "";

    // Function to submit a booking request
    async function makeBooking() {
        if (!bookingDate || !startTime || !endTime) {
            toastStore.trigger({
                message: "Please provide all booking details",
                background: "variant-filled-warning",
            });
            return;
        }

        try {
            // Submit booking to the database
            const { data, error } = await supabase
                .from("booking_requests")
                .insert([
                    {
                        listing_id: listingId,
                        booking_user_id: session.user.id,
                        start_time: new Date(`${bookingDate}T${startTime}`),
                        end_time: new Date(`${bookingDate}T${endTime}`),
                    },
                ]);

            if (error) {
                console.error("error", error);
                toastStore.trigger({
                    message: "Error making booking",
                    background: "variant-filled-warning",
                });
                return;
            }

            toastStore.trigger({
                message: "Booking requested successfully",
                background: "variant-filled-success",
            });

            modalStore.close();
        } catch (error) {
            console.error("error", error);
            toastStore.trigger({
                message: "Error making booking",
                background: "variant-filled-warning",
            });
        }
    }
</script>

<div class="card m-4 p-4 w-3/5">
    <div class="w-full items-center text-center">
        <h2 class="h4 mb-2">Book Charging Time</h2>
    </div>
    <div class="grid grid-cols-2 gap-2 items-end">
        <div>
            <label class="label mt-2">
                <span class="text-left">Booking Date</span>
                <input type="date" bind:value={bookingDate} />
            </label>
        </div>
        <div>
            <label class="label mt-2">
                <span>Start Time</span>
                <input type="time" bind:value={startTime} />
            </label>
        </div>
        <div>
            <label class="label mt-2">
                <span>End Time</span>
                <input type="time" bind:value={endTime} />
            </label>
        </div>
    </div>
    <div class="w-full flex justify-center m-auto">
        <button
            class="btn mt-2 mb-0 variant-filled-primary rounded-full"
            on:click={makeBooking}
        >
            Request Booking
        </button>
    </div>
</div>