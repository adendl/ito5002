<script lang="ts">
    export let data;
    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    import { TabGroup, Tab } from "@skeletonlabs/skeleton";
    import WeekTable from "$lib/WeekTable.svelte";
    import { ConicGradient } from "@skeletonlabs/skeleton";
    import type { ConicStop } from "@skeletonlabs/skeleton";
    import WeekTableCalendarListings from "$lib/WeekTableCalendarListings.svelte";
    let loaded = false;
    const conicStops: ConicStop[] = [
        { color: "transparent", start: 0, end: 25 },
        { color: "rgb(var(--color-primary-500))", start: 75, end: 100 },
    ];

    let tabSet = 0; // 0 is listing mode, 1 is booking mode
    let selectedDate = new Date().toISOString().split("T")[0];
    let startDate;
    let endDate;
    let calendarData;
    let focusElement;
    let noData;

    function getStartEndDate() {
        let dateWindow = Array.from({ length: 7 }, (_, i) => {
            let date = new Date(selectedDate);
            date.setDate(date.getDate() + i - date.getDay());
            return date;
        });
        startDate = dateWindow[0].toISOString().split("T")[0] + "T00:00:00+10";
        endDate = dateWindow[6].toISOString().split("T")[0] + "T23:59:59+10";
    }

    // Overall refresh function
    $: selectedDate, refreshData();
    function refreshData() {
        if (tabSet === 0) {
            getListingModeData();
        } else if (tabSet === 1) {
            getBookingModeData();
        }
    }

    // Get all availabilities for this user in the window
    // Get all requests and bookings assoicated with these availabilities
    async function getListingModeData() {
        loaded = false;
        focusElement = null;
        calendarData = Array.from({ length: 7 }).map(() =>
            Array.from({ length: 6 }).map(() => ({
                state: "none",
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
        booking_requests(*),
        bookings(*)
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
        // zip the availabilities into the calendarData
        // NEED TO APPEND to data instead of set, there could be multiple availabilities in the same slot
        if (availabilities.length > 0) {
            availabilities.forEach((object) => {
                let date = new Date(object.start_time);
                let day = date.getDay();
                let hour = date.getHours();
                calendarData[day][hour / 4] = {
                    state: object.booked
                        ? "booked"
                        : object.booking_requests.length > 0
                          ? "requested"
                          : "available",
                    data: object,
                };
            });
            noData = false;
        } else {
            noData = true;
        }
        console.log("calendarData end:");
        console.log(calendarData);
        loaded = true;
    }

    // Booking mode
    async function getBookingModeData() {
        getStartEndDate();
    }
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

    <div class="card mt-2 w-full h-[23vh]">
        {#if !focusElement || focusElement.state === "none"}
            <div class="flex justify-center items-center h-full">
                {#if noData}
                    <i class="h4">
                        No listings for this window. List charging availability
                        to start making a difference.
                    </i>
                {:else}
                    <i class="h4">Select an active item to view details.</i>
                {/if}
            </div>
        {:else}
            {JSON.stringify(focusElement)}
        {/if}
    </div>
{:else}
    <div class="flex justify-center items-center h-full">
        <ConicGradient stops={conicStops} spin
            >Loading calendar...</ConicGradient
        >
    </div>
{/if}
