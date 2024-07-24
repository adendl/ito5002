<script lang="ts">
    export let data;
    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    import { onMount } from "svelte";
    import ListingCard from "$lib/ListingCard.svelte";
    import { ConicGradient, getToastStore } from "@skeletonlabs/skeleton";
    import type { ConicStop } from "@skeletonlabs/skeleton";
    const conicStops: ConicStop[] = [
        { color: "transparent", start: 0, end: 25 },
        { color: "rgb(var(--color-primary-500))", start: 75, end: 100 },
    ];
    let loaded = false;
    const toastStore = getToastStore();

    let listings = [];

    onMount(async () => {
        const { data, error } = await supabase.rpc("closest_listings_in_next_month", {
            input_user_id: session.user.id,
            limit_count: 100,
        });
        if (error) {
            console.error("error", error);
            toastStore.trigger({
                message: "Error fetching listings",
                background: "variant-filled-error",
            });
            return;
        }
        console.log("Listings:");
        console.log(data);
        loaded = true;
    });

    import { dummyListingCards } from "../lib/dummyData/listingCards.js";
    import dummyMap from "$lib/dummyData/dummyMap.png";
</script>

{#if !loaded}
    <div class="flex justify-center items-center h-full">
        <ConicGradient stops={conicStops} spin
            >Loading dashboard...</ConicGradient
        >
    </div>
{:else}
    <div class="grid grid-cols-2 gap-4 h-full relative">
        <div class="card p-4 h-full w-full relative overflow-auto">
            <span class="flex justify-between items-center">
                <h3 class="h4 mb-3">Charging available nearby</h3>
                <div>
                    <button type="button" class="btn m-2 variant-filled"
                        ><i class="fa-solid fa-filter"></i></button
                    >
                </div>
            </span>
            {#each dummyListingCards as listingCard}
                <ListingCard {...listingCard} />
            {/each}
        </div>
        <div class="card p-4 h-full w-full relative overflow-auto">
            <img src={dummyMap} alt="Map" class="w-full h-full rounded-lg" />
            <div
                class="absolute top-0 left-0 flex justify-center items-center w-full h-full"
            >
                <div class="flex justify-center items-center">
                    <button
                        type="button"
                        class="btn btn-icon variant-ghost"
                        style="position: absolute; top: 30%; left: 20%;"
                    >
                        <i class="fa-solid fa-location-dot"></i>
                    </button>
                    <button
                        type="button"
                        class="btn btn-icon variant-ghost"
                        style="position: absolute; top: 50%; left: 60%;"
                    >
                        <i class="fa-solid fa-location-dot"></i>
                    </button>
                    <button
                        type="button"
                        class="btn btn-icon variant-ghost"
                        style="position: absolute; top: 70%; left: 40%;"
                    >
                        <i class="fa-solid fa-location-dot"></i>
                    </button>
                    <button
                        type="button"
                        class="btn btn-icon variant-ghost"
                        style="position: absolute; top: 35%; left: 65%;"
                    >
                        <i class="fa-solid fa-location-dot"></i>
                    </button>
                </div>
            </div>
        </div>
    </div>
{/if}
