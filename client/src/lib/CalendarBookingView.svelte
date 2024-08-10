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
    import WeekTableCalendarBookings from "$lib/WeekTableCalendarBookings.svelte";
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
    let focusRequest = null;
    let focusRequestIndex = null;
    let requestBlocks = {};
    let bookingBlocks = {};
    let copartyId = null;

    // Overall refresh functions
    $: selectedDate, getBookingModeData();
    $: {
        if (
            focusElement &&
            focusElement.objects &&
            focusElement.objects.length === 1
        ) {
            focusRequest = focusElement.objects[0];
            focusRequestIndex = 0;
        } else {
            focusRequest = null;
            focusRequestIndex = null;
        }
    }
    $: focusRequest,
        (copartyId = focusRequest
            ? focusRequest.availabilities.listings.users.user_id
            : null);

    // Listing mode functionality
    async function getBookingModeData() {
        loaded = false;
        focusElement = null;
        calendarData = Array.from({ length: 7 }).map(() =>
            Array.from({ length: 6 }).map(() => ({
                state: "none",
                objects: [],
            })),
        );
        ({ startDate, endDate } = getStartEndDate(selectedDate));
        // Get bookings requests sent by current user in this window
        const { data: bookingRequests, error: bookingRequestError } =
            await supabase
                .from("booking_requests")
                .select(
                    `
        *,
        availabilities!inner(*, listings!inner(*, places!inner(*), users!inner(*, contacts(*))))
    `,
                )
                .eq("booking_user_id", session.user.id)
                .gte("availabilities.start_time", startDate)
                .lte("availabilities.start_time", endDate);

        if (bookingRequestError) {
            toastStore.trigger({
                message: "Error fetching booking requests",
                background: "variant-filled-error",
            });
            return;
        }

        // zip the booking requests into the calendarData
        if (bookingRequests.length > 0) {
            bookingRequests.forEach((object) => {
                let date = new Date(object.availabilities.start_time);
                let day = date.getDay();
                let hour = date.getHours();
                calendarData[day][hour / 4].objects.push(object);
                calendarData[day][hour / 4].objects.some((element) =>
                    element.status === "accepted"
                        ? (calendarData[day][hour / 4].state = "booked")
                        : element.status === "submitted"
                          ? (calendarData[day][hour / 4].state = "requested")
                          : element.status === "rejected"
                            ? (calendarData[day][hour / 4].state = "rejected")
                            : (calendarData[day][hour / 4].state = "none"),
                );
            });
            noData = false;
        } else {
            noData = true;
        }

        requestBlocks = getContiguousOutboundRequests(calendarData);
        loaded = true;
    }

    function getContiguousOutboundRequests(calendarData) {
        // Get groups of contiguous requests keyed by the user to whom the request was sent
        let requestBlocks = {};
        calendarData.forEach((day) => {
            day.forEach((segment) => {
                if (segment.state != "none") {
                    segment.objects.forEach((object) => {
                        const userId =
                            object.availabilities.listings.users.user_id;
                        const startTime = object.availabilities.start_time;
                        const endTime = object.availabilities.end_time;
                        const requestId = object.booking_request_id;
                        const availabilityId =
                            object.availabilities.availability_id;

                        if (!requestBlocks[userId]) {
                            requestBlocks[userId] = [];
                        }

                        const userBlocks = requestBlocks[userId];
                        const lastBlock = userBlocks[userBlocks.length - 1];

                        if (lastBlock && lastBlock.end === startTime) {
                            lastBlock.end = endTime;
                            lastBlock.requestIds.push(requestId);
                            lastBlock.availabilityIds.push(availabilityId);
                        } else {
                            userBlocks.push({
                                start: startTime,
                                end: endTime,
                                requestIds: [requestId],
                                availabilityIds: [availabilityId],
                            });
                        }
                    });
                }
            });
        });
        return requestBlocks;
    }

    async function cancelRequest(request) {
        const booking_user_id = request.availabilities.listings.user_id;
        var allRequestIds = [];
        requestBlocks[booking_user_id].forEach((block) => {
            if (block.requestIds.includes(request.booking_request_id)) {
                allRequestIds = block.requestIds;
            }
        });
        const { data: deletedRequests, error: deleteError } = await supabase
            .from("booking_requests")
            .delete()
            .in("booking_request_id", allRequestIds);
        if (deleteError) {
            toastStore.trigger({
                message: "Error cancelling booking",
                background: "variant-filled-error",
            });
            return;
        }
        toastStore.trigger({
            message: "Requests cancelled",
            background: "variant-filled-success",
        });
        getBookingModeData();
    }

    $: console.log(focusRequest);
</script>

{#if loaded}
    <WeekTableCalendarBookings
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
                    <h3 class="ml-4">Requests sent for this timeslot</h3>
                    {#each focusElement.objects as request, i}
                        <div
                            class="card p-4 m-2 break-normal variant-{focusRequestIndex ===
                            i
                                ? 'filled-secondary'
                                : 'ghost-secondary'}"
                            on:click={() => {
                                focusRequest = request;
                                focusRequestIndex = i;
                            }}
                        >
                            <div class="grid grid-cols-4 gap-2">
                                <div
                                    class="col-span-3 flex justify-start items-center text-left"
                                >
                                    {#each Array.from( { length: requestBlocks[request.availabilities.listings.user_id].length }, ) as _, i}
                                        {#if isWithinWindow(requestBlocks[request.availabilities.listings.user_id][i].start, requestBlocks[request.availabilities.listings.user_id][i].end, request.availabilities.start_time)}
                                            Requested to use {request
                                                .availabilities.listings.users
                                                .user_name}'s {request
                                                .availabilities.listings
                                                .charging_mode}
                                            {request.availabilities.listings
                                                .charger_type} charger in {request
                                                .availabilities.listings.places
                                                .suburb}
                                            between {prettifyDate(
                                                requestBlocks[
                                                    request.availabilities
                                                        .listings.user_id
                                                ][i].start,
                                            )} and {prettifyDate(
                                                requestBlocks[
                                                    request.availabilities
                                                        .listings.user_id
                                                ][i].end,
                                            )}.
                                        {/if}
                                    {/each}
                                </div>
                                <div class="flex flex-col items-end">
                                    <span
                                        class="chip my-2 mr-1 variant-{request.status ===
                                        'accepted'
                                            ? 'filled-success'
                                            : request.status === 'submitted'
                                              ? 'filled-warning'
                                              : request.status === 'rejected'
                                                ? 'filled-error'
                                                : 'ghost'}"
                                    >
                                        {request.status ? request.status : "?"}
                                    </span>
                                    <button
                                        type="button"
                                        class="btn btn-sm variant-filled m-1"
                                        on:click={(event) =>
                                            cancelRequest(request)}
                                    >
                                        Cancel
                                    </button>
                                </div>
                            </div>
                        </div>
                    {/each}
                </div>
                {#if !focusRequest}
                    <div class="flex justify-center items-center h-full">
                        <i class="h5 mt-6">
                            Select a listing to view details.
                        </i>
                    </div>
                {:else if focusRequest.status === "submitted"}
                    <div class="flex justify-center items-center h-full">
                        <i class="h5 mt-6"> Awaiting a response from lister </i>
                    </div>
                {:else if focusRequest.status === "rejected"}
                    <div class="flex justify-center items-center h-full">
                        <i class="h5 mt-6">
                            Lister has rejected this request
                        </i>
                    </div>
                {:else if focusRequest.status === "accepted"}
                    <div
                        class="p-4 overflow-y-scroll h-[21vh] overflow-y-scroll"
                    >
                        <h3 class="ml-4">Booking for this request</h3>
                        <div
                            class="card p-4 m-2 break-normal variant-ghost-secondary"
                        >
                            {focusRequest.availabilities.listings.users
                                .user_name} accepted this booking. The booking address
                            is
                            {focusRequest.availabilities.listings.places
                                .address}.
                            {#if focusRequest.availabilities.listings.users.contacts}
                                You can contact the lister at {focusRequest
                                    .availabilities.listings.users.contacts
                                    .email_address}
                                {focusRequest.availabilities.listings.users
                                    .contacts.phone_number
                                    ? "or on " +
                                      focusRequest.availabilities.listings.users
                                          .contacts.phone_number
                                    : ""}.
                            {:else}
                                They don't have contact info saved yet, but
                                we've shared yours.
                            {/if}
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
