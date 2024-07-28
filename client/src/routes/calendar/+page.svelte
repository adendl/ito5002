<script lang="ts">
    export let data;
    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    import { TabGroup, Tab } from "@skeletonlabs/skeleton";
    import WeekTable from "$lib/WeekTable.svelte";
    import WeekTableCalendarListings from "$lib/WeekTableCalendarListings.svelte";

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

    let selectedDate = new Date().toISOString().split("T")[0];
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
    $: selectedDate, refreshData();
    function refreshData() {
        if (tabSet === 0) {
            getListingModeData();
        } else if (tabSet === 1) {
            getBookingModeData();
        }
    }

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

    function getStartEndDate() {
        let dateWindow = Array.from({ length: 7 }, (_, i) => {
            let date = new Date(selectedDate);
            date.setDate(date.getDate() + i - date.getDay());
            return date;
        });
        startDate = dateWindow[0].toISOString().split("T")[0] + "T00:00:00+10";
        endDate = dateWindow[6].toISOString().split("T")[0] + "T23:59:59+10";
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
        console.log("calendarData start:");
        console.log(calendarData);
        getStartEndDate();
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
        console.log("availabilities:");
        console.log(availabilities);

        // Filter rejected requests
        availabilities.forEach((object) => {
            object.booking_requests = object.booking_requests.filter(
                (request) => request.status !== "rejected",
            );
        });

        console.log("availabilities after filtering:");
        console.log(availabilities);

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
        getContiguousRequests();
        getContiguousBookings();
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
            refreshData();
        });
    }

    // Get blocks of contiguous requests by a single user
    // Generates a dict keyed by user id containing a list of
    // rolled up windows where the requests butt up against
    // each other
    function getContiguousRequests() {
        requestBlocks = {};
        calendarData.forEach((day) => {
            day.forEach((segment) => {
                if (segment.state === "requested") {
                    segment.objects.forEach((object) => {
                        if (object.booking_requests.length > 0) {
                            object.booking_requests.forEach((request) => {
                                const userId = request.booking_user_id;
                                const startTime = object.start_time;
                                const endTime = object.end_time;
                                const requestId = request.booking_request_id;
                                const availabilityId = object.availability_id;
                                if (!requestBlocks[userId]) {
                                    requestBlocks[userId] = [];
                                }

                                const userBlocks = requestBlocks[userId];
                                const lastBlock =
                                    userBlocks[userBlocks.length - 1];

                                if (lastBlock && lastBlock.end === startTime) {
                                    lastBlock.end = endTime;
                                    lastBlock.requestIds.push(requestId);
                                    lastBlock.availabilityIds.push(
                                        availabilityId,
                                    );
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
                }
            });
        });
    }

    function getContiguousBookings() {
        bookingBlocks = {};
        calendarData.forEach((day) => {
            day.forEach((segment) => {
                if (segment.state === "booked") {
                    segment.objects.forEach((object) => {
                        if (object.bookings) {
                            const userId = object.bookings.booking_user_id;
                            const startTime = object.start_time;
                            const endTime = object.end_time;
                            const bookingId = object.booking_id;
                            const availabilityId = object.availability_id;
                            if (!bookingBlocks[userId]) {
                                bookingBlocks[userId] = [];
                            }

                            const userBlocks = bookingBlocks[userId];
                            const lastBlock = userBlocks[userBlocks.length - 1];

                            if (lastBlock && lastBlock.end === startTime) {
                                lastBlock.end = endTime;
                                lastBlock.bookingIds.push(bookingId);
                                lastBlock.availabilityIds.push(availabilityId);
                            } else {
                                userBlocks.push({
                                    start: startTime,
                                    end: endTime,
                                    bookingIds: [bookingId],
                                    availabilityIds: [availabilityId],
                                });
                            }
                        }
                    });
                }
            });
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
        refreshData();
    }

    async function rejectRequest(booking_user_id, booking_request_id) {
        var allRequestIds = [];
        var allAvailabilityIds = [];
        console.log(requestBlocks);
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
        refreshData();
    }

    // Booking mode
    async function getBookingModeData() {
        getStartEndDate();
    }

    // Utility functions
    function isWithinWindow(startTime, endTime, checkTime) {
        const start = new Date(startTime).getTime();
        const end = new Date(endTime).getTime();
        const check = new Date(checkTime).getTime();
        return check >= start && check < end;
    }

    function prettifyDate(date) {
        return new Date(date).toLocaleString();
    }

    $: console.log(focusListing);
</script>

{#if loaded}
    <div class="w-full flex justify-end relative">
        <input
            tabindex="-1"
            class="input max-w-[10rem] absolute right-0 z-10"
            type="date"
            bind:value={selectedDate}
        />
    </div>

    <div class="">
        <TabGroup class="mt-2">
            <Tab bind:group={tabSet} name="tab1" value={0}>
                <svelte:fragment slot="lead"></svelte:fragment>
                <span>My listings</span>
            </Tab>
            <Tab bind:group={tabSet} name="tab2" value={1}>My bookings</Tab>
            <svelte:fragment slot="panel">
                {#if tabSet === 0}
                    <WeekTableCalendarListings
                        bind:targetDate={selectedDate}
                        bind:calendarData
                        bind:focusElement
                    />
                {:else if tabSet === 1}
                    <WeekTable bind:targetDate={selectedDate} />
                {/if}
            </svelte:fragment>
        </TabGroup>
    </div>

    <div class="card mt-2 w-full min-h-[23vh]">
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
                <div class="p-4 overflow-y-scroll h-[23vh] overflow-y-scroll">
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
                        class="p-4 overflow-y-scroll h-[23vh] overflow-y-scroll"
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
                        class="p-4 overflow-y-scroll h-[23vh] overflow-y-scroll"
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
                                                .user_name} has booked this listing
                                            from {prettifyDate(
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
                                            {#if focusListing.bookings.users.contacts.phone_number || focusListing.bookings.users.contacts.email_address}
                                                Get in touch on {focusListing
                                                    .bookings.users.contacts
                                                    .phone_number} or {focusListing
                                                    .bookings.users.contacts
                                                    .email_address}
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
                                                on:click={rejectRequest}
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
    <div class="flex justify-center items-center h-full">
        <ConicGradient stops={conicStops} spin
            >Loading calendar...</ConicGradient
        >
    </div>
{/if}
