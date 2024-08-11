<script lang="ts">
    export let data;
    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    import { onMount } from "svelte";
    import { page } from "$app/stores";

    let selectedDate = new Date().toISOString().split("T")[0];
    let tabSet = 0;
    let loaded = false;

    onMount(() => {
        if ($page.url.searchParams.has("calendarType")) {
            tabSet =
                $page.url.searchParams.get("calendarType") === "bookings"
                    ? 1
                    : 0;
            selectedDate = $page.url.searchParams.get("date");

            console.log("tabSet", tabSet);
            console.log("selectedDate", selectedDate);
        }
        loaded = true;
    });

    import { TabGroup, Tab } from "@skeletonlabs/skeleton";
    import CalendarListingView from "$lib/CalendarListingView.svelte";
    import CalendarBookingView from "$lib/CalendarBookingView.svelte";
</script>

{#if loaded}
    <div class="">
        <div class="w-full flex justify-end relative">
            <input
                tabindex="-1"
                class="input max-w-[10rem] absolute right-0 z-10"
                type="date"
                bind:value={selectedDate}
            />
        </div>
        <TabGroup class="mt-2">
            <Tab bind:group={tabSet} name="tab1" value={0}>
                <svelte:fragment slot="lead"></svelte:fragment>
                <span class="text-primary-300">My listings</span>
            </Tab>
            <Tab bind:group={tabSet} name="tab2" value={1}><span class="text-secondary-300">My bookings</span></Tab>
            <svelte:fragment slot="panel">
                {#if tabSet === 0}
                    <CalendarListingView bind:data bind:selectedDate />
                {:else if tabSet === 1}
                    <CalendarBookingView bind:data bind:selectedDate />
                {/if}
            </svelte:fragment>
        </TabGroup>
    </div>
{/if}
