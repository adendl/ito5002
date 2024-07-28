<script lang="ts">
    export let data;
    export let selectedDate = new Date().toISOString().split("T")[0];
    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    // Loader
    import { ConicGradient } from "@skeletonlabs/skeleton";
    import type { ConicStop } from "@skeletonlabs/skeleton";
    let loaded = false;
    const conicStops: ConicStop[] = [
        { color: "transparent", start: 0, end: 25 },
        { color: "rgb(var(--color-primary-500))", start: 75, end: 100 },
    ];

    // Modals & toasts
    import { getModalStore, getToastStore } from "@skeletonlabs/skeleton";
    import ManageListingModal from "$lib/ManageListingModal.svelte";
    const modalStore = getModalStore();
    const toastStore = getToastStore();
    const manageListingModalRef = { ref: ManageListingModal };
    var manageListingModal = {
        type: "component",
        component: manageListingModalRef,
        meta: {
            data,
        },
    };
    // Custom functions
    import WeekTableCalendarListings from "$lib/WeekTableCalendarListings.svelte";
    import {
        getStartEndDate,
        prettifyDate,
        isWithinWindow,
        getContiguousRequests,
        getContiguousBookings,
    } from "$lib/calendarHelperFunctions.js";

    let tabSet = 0; // 0 is listing mode, 1 is booking mode
    let startDate;
    let endDate;
    let calendarData;
    let focusElement;
    let noData;
    let focusListing = null;
    let focusListingIndex = null;
    let requestBlocks = {};
    let bookingBlocks = {};

    // Overall refresh functions
    $: selectedDate, getListingModeData();
    $: {
        if (
            focusElement &&
            focusElement.objects &&
            focusElement.objects.length === 1
        ) {
            focusListing = focusElement.objects[0];
            focusListingIndex = 0;
        } else {
            focusListing = null;
            focusListingIndex = null;
        }
    }

    // Listing mode functionality
    async function getListingModeData() {
        loaded = false;
        focusElement = null;
        calendarData = Array.from({ length: 7 }).map(() =>
            Array.from({ length: 6 }).map(() => ({
                state: "none",
                objects: [],
            })),
        );
        ({ startDate, endDate } = getStartEndDate(selectedDate));
        // Get availabilities in window and related entities
        const { data, error } = await supabase
            .from("availabilities")
            .select(
                `
        *,
        listings!inner(*, places!inner(*)),
        booking_requests(*, users!inner(*)),
        bookings(*, users!inner(*, contacts(*)))
    `,
            )
            .eq("listings.user_id", session.user.id)
            .gte("start_time", startDate)
            .lte("start_time", endDate);

        if (error) {
            console.error(error);
            return;
        }
        let availabilities = data;

        // Filter rejected requests
        availabilities = data.map((availability) => {
            const filteredRequests = availability.booking_requests.filter(
                (request) => request.status !== "rejected",
            );
            return { ...availability, booking_requests: filteredRequests };
        });

        // zip the availabilities into the calendarData
        if (availabilities.length > 0) {
            availabilities.forEach((object) => {
                let date = new Date(object.start_time);
                let day = date.getDay();
                let hour = date.getHours();
                calendarData[day][hour / 4].objects.push(object);
                calendarData[day][hour / 4].objects.some((element) =>
                    element.bookings
                        ? ((calendarData[day][hour / 4].state = "booked"),
                          (element.state = "booked"))
                        : element.booking_requests.length > 0
                          ? ((calendarData[day][hour / 4].state = "requested"),
                            (element.state = "requested"))
                          : ((calendarData[day][hour / 4].state = "available"),
                            (element.state = "available")),
                );
            });
            noData = false;
        } else {
            noData = true;
        }
        requestBlocks = getContiguousRequests(calendarData);
        bookingBlocks = getContiguousBookings(calendarData);
        loaded = true;
    }

    function manageListing(event, listing) {
        event.stopPropagation();
        console.log(listing);

        new Promise<boolean>((resolve) => {
            const manageListingModal = {
                type: "component",
                component: manageListingModalRef,
                meta: {
                    data,
                    listing_id: listing.listing_id,
                },
                response: (r: boolean) => {
                    resolve(r);
                },
            };
            modalStore.trigger(manageListingModal);
        }).then((r: any) => {
            //window.location.href = "/calendar?date=" + selectedDate;
            getListingModeData();
        });
    }

    async function acceptRequest(booking_user_id, booking_request_id) {
        var allRequestIds = [];
        var allAvailabilityIds = [];
        requestBlocks[booking_user_id].forEach((block) => {
            if (block.requestIds.includes(booking_request_id)) {
                allRequestIds = block.requestIds;
                allAvailabilityIds = block.availabilityIds;
            }
        });
        const { data: updatedRequests, error: updateError } = await supabase
            .from("booking_requests")
            .update({ status: "accepted" })
            .in("booking_request_id", allRequestIds);
        if (updateError) {
            toastStore.trigger({
                message: "Error creating booking",
                background: "variant-filled-error",
            });
            return;
        }
        const bookingsData = allAvailabilityIds.map((availability_id) => ({
            availability_id,
            booking_user_id,
        }));
        const { data: newBookings, error: insertError } = await supabase
            .from("bookings")
            .insert(bookingsData);
        if (insertError) {
            toastStore.trigger({
                message: "Error creating booking",
                background: "variant-filled-error",
            });
            return;
        }
        toastStore.trigger({
            message: "Booking created",
            background: "variant-filled-success",
        });
        getListingModeData();
    }

    async function rejectRequest(booking_user_id, booking_request_id) {
        var allRequestIds = [];
        var allAvailabilityIds = [];
        requestBlocks[booking_user_id].forEach((block) => {
            if (block.requestIds.includes(booking_request_id)) {
                allRequestIds = block.requestIds;
                allAvailabilityIds = block.availabilityIds;
            }
        });
        const { data: updatedRequests, error: updateError } = await supabase
            .from("booking_requests")
            .update({ status: "rejected" })
            .in("booking_request_id", allRequestIds);
        if (updateError) {
            toastStore.trigger({
                message: "Error rejecting request",
                background: "variant-filled-error",
            });
            return;
        }
        toastStore.trigger({
            message: "Request rejected",
            background: "variant-filled-success",
        });
        getListingModeData();
    }

    async function cancelBooking(booking_user_id, booking_id) {
        var allBookingIds = [];
        var allAvailabilityIds = [];
        console.log(bookingBlocks[booking_user_id]);
        bookingBlocks[booking_user_id].forEach((block) => {
            if (block.bookingIds.includes(booking_id)) {
                allBookingIds = block.bookingIds;
                allAvailabilityIds = block.availabilityIds;
            }
        });
        console.log(allBookingIds);
        const { data: deletedBookings, error: deleteError } = await supabase
            .from("bookings")
            .delete()
            .in("booking_id", allBookingIds);
        if (deleteError) {
            toastStore.trigger({
                message: "Error cancelling booking",
                background: "variant-filled-error",
            });
            return;
        }
        toastStore.trigger({
            message: "Booking cancelled",
            background: "variant-filled-success",
        });
        getListingModeData();
    }
</script>

{#if loaded}
    <WeekTableCalendarListings
        bind:targetDate={selectedDate}
        bind:calendarData
        bind:focusElement
    />
    <div class="card mt-2 w-full min-h-[21vh]">
        {#if !focusElement || focusElement.state === "none"}
            <div class="flex justify-center items-center h-full">
                {#if noData}
                    <i class="h4 mt-20">
                        No listings for this window. List charging availability
                        to start making a difference.
                    </i>
                {:else}
                    <i class="h4 mt-20"
                        >Select an active item to view details.</i
                    >
                {/if}
            </div>
        {:else}
            <div class="grid grid-cols-2 gap-2">
                <div class="p-4 overflow-y-scroll h-[21vh] overflow-y-scroll">
                    <h3 class="ml-4">Listings for this timeslot</h3>
                    {#each focusElement.objects as listing, i}
                        <div
                            class="card p-4 m-2 break-normal variant-{focusListingIndex ===
                            i
                                ? 'filled-secondary'
                                : 'ghost-secondary'}"
                            on:click={() => {
                                focusListing = listing;
                                focusListingIndex = i;
                            }}
                        >
                            <div class="grid grid-cols-4 gap-2">
                                <div
                                    class="col-span-3 flex justify-start items-center text-left"
                                >
                                    {listing.listings.places.suburb}: {listing
                                        .listings.charging_mode} - {listing
                                        .listings.charger_type} @ ${listing
                                        .listings.price_per_hour} per hour
                                    <br />
                                    {listing.listings.places.address}
                                </div>
                                <div class="flex flex-col items-end">
                                    <span
                                        class="chip my-2 mr-1 variant-{listing.state ===
                                        'booked'
                                            ? 'filled-success'
                                            : listing.state === 'requested'
                                              ? 'filled-warning'
                                              : 'ghost-success'}"
                                    >
                                        {listing.state
                                            ? listing.state
                                            : "available"}
                                    </span>

                                    <button
                                        type="button"
                                        class="btn btn-sm variant-filled m-1"
                                        on:click={(event) =>
                                            manageListing(event, listing)}
                                    >
                                        Manage
                                    </button>
                                </div>
                            </div>
                        </div>
                    {/each}
                </div>
                {#if !focusListing}
                    <div class="flex justify-center items-center h-full">
                        <i class="h5 mt-6">
                            Select a listing to view details.
                        </i>
                    </div>
                {:else if focusListing.state === "available"}
                    <div class="flex justify-center items-center h-full">
                        <i class="h5 mt-6">
                            Listing is available. Press manage to make changes.
                        </i>
                    </div>
                {:else if focusListing.state === "requested"}
                    <div
                        class="p-4 overflow-y-scroll h-[21vh] overflow-y-scroll"
                    >
                        <h3 class="ml-4">Requests for this listing</h3>
                        {#each focusListing.booking_requests as request, i}
                            <div
                                class="card p-4 m-2 break-normal variant-ghost-secondary"
                            >
                                {#each Array.from( { length: requestBlocks[request.booking_user_id].length }, ) as _, i}
                                    {#if isWithinWindow(requestBlocks[request.booking_user_id][i].start, requestBlocks[request.booking_user_id][i].end, focusListing.start_time)}
                                        <div class="grid grid-cols-4 gap-2">
                                            <div
                                                class="col-span-3 flex justify-center items-center"
                                            >
                                                {request.users.user_name} requested
                                                this booking from {prettifyDate(
                                                    requestBlocks[
                                                        request.booking_user_id
                                                    ][i].start,
                                                )} to {prettifyDate(
                                                    requestBlocks[
                                                        request.booking_user_id
                                                    ][i].end,
                                                )}
                                            </div>
                                            <div
                                                class="flex flex-col items-end"
                                            >
                                                <button
                                                    type="button"
                                                    class="btn btn-sm variant-filled-success m-1"
                                                    on:click={() =>
                                                        acceptRequest(
                                                            request.booking_user_id,
                                                            request.booking_request_id,
                                                        )}
                                                >
                                                    Accept
                                                </button>
                                                <button
                                                    type="button"
                                                    class="btn btn-sm variant-filled-error m-1"
                                                    on:click={() =>
                                                        rejectRequest(
                                                            request.booking_user_id,
                                                            request.booking_request_id,
                                                        )}
                                                >
                                                    Reject
                                                </button>
                                            </div>
                                        </div>
                                    {/if}
                                {/each}
                            </div>
                        {/each}
                    </div>
                {:else if focusListing.state === "booked"}
                    <div
                        class="p-4 overflow-y-scroll h-[21vh] overflow-y-scroll"
                    >
                        <h3 class="ml-4">Booking for this listing</h3>
                        <div
                            class="card p-4 m-2 break-normal variant-ghost-secondary"
                        >
                            {#each Array.from( { length: bookingBlocks[focusListing.bookings.booking_user_id].length }, ) as _, i}
                                {#if isWithinWindow(bookingBlocks[focusListing.bookings.booking_user_id][i].start, bookingBlocks[focusListing.bookings.booking_user_id][i].end, focusListing.start_time)}
                                    <div class="grid grid-cols-4 gap-2">
                                        <div
                                            class="col-span-3 flex justify-center items-center"
                                        >
                                            {focusListing.bookings.users
                                                .user_name} has booked from {prettifyDate(
                                                bookingBlocks[
                                                    focusListing.bookings
                                                        .booking_user_id
                                                ][i].start,
                                            )} to {prettifyDate(
                                                bookingBlocks[
                                                    focusListing.bookings
                                                        .booking_user_id
                                                ][i].end,
                                            )}.
                                            {#if focusListing.bookings.users.contacts}
                                                {#if focusListing.bookings.users.contacts.phone_number || focusListing.bookings.users.contacts.email_address}
                                                    Get in touch on {focusListing
                                                        .bookings.users.contacts
                                                        .phone_number} or {focusListing
                                                        .bookings.users.contacts
                                                        .email_address}
                                                {/if}
                                            {:else}
                                                They don't have contact info
                                                saved yet, but we've shared
                                                yours.
                                            {/if}
                                        </div>
                                        <div class="flex flex-col items-end">
                                            <button
                                                type="button"
                                                class="btn btn-sm variant-filled-success m-1 invisible"
                                            >
                                                Show <i
                                                    class="ml-1 fa-solid fa-phone"
                                                ></i>
                                            </button>
                                            <button
                                                type="button"
                                                class="btn btn-sm variant-filled-error m-1"
                                                on:click={() =>
                                                    cancelBooking(
                                                        focusListing.bookings
                                                            .booking_user_id,
                                                        focusListing.bookings
                                                            .booking_id,
                                                    )}
                                            >
                                                Cancel
                                            </button>
                                        </div>
                                    </div>
                                {/if}
                            {/each}
                        </div>
                    </div>
                {/if}
            </div>
        {/if}
    </div>
{:else}
    <div class="flex justify-center items-center h-[70vh]">
        <ConicGradient stops={conicStops} spin
            >Loading calendar...</ConicGradient
        >
    </div>
{/if}
