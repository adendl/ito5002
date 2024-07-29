<script lang="ts">
    export let data;
    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    import { onMount } from "svelte";
    import ListingCard from "$lib/ListingCard.svelte";
    import ListingMarker from "$lib/ListingMarker.svelte";
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
        // Get user's home or default to central Sydney
        const { data: user, error: userError } = await supabase
            .from("users")
            .select(`home_place:home_place_id (point)`)
            .eq("user_id", session.user.id)
            .single();

        const homePlacePoint =
            user?.home_place?.point ||
            "0101000020E610000041BCAE5FB0E66240C87C40A033EF40C0";

        const { data, error } = await supabase.rpc("get_listings_near", {
            query_location: homePlacePoint,
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
        listings = data;
        averageCoordinate = getAverageCoordinate(listings);
        zoomLevel = getZoomLevel(listings);
        listings = fuzzClusteredListings(listings);
        listings = listings;
        loaded = true;
    });

    // Map component
    import { Map, Marker } from "@beyonk/svelte-mapbox";
    import {
        getAverageCoordinate,
        getZoomLevel,
        fuzzClusteredListings,
    } from "$lib/mappingFunctions.js";
    let mapComponent;
    let averageCoordinate;
    let zoomLevel;
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
                    <button
                        type="button"
                        class="btn m-2 variant-filled"
                        disabled><i class="fa-solid fa-filter"></i></button
                    >
                </div>
            </span>
            {#each listings as listingCard}
                <ListingCard {...listingCard} {data} />
            {:else}
                <div class="flex justify-center items-center h-[90%]">
                    <h4 class="h4">No listings found</h4>
                </div>
            {/each}
        </div>
        <div class="card p-4 h-full w-full relative overflow-auto">
            <Map
                accessToken="pk.eyJ1Ijoib2otc2VjIiwiYSI6ImNseXpjY3dyaTBvZDUya29uZDd6aGdnbjgifQ.P37-v7FO0PAZ8eKtaluTsw"
                bind:this={mapComponent}
                on:recentre={(e) =>
                    console.log(e.detail.center.lat, e.detail.center.lng)}
                options={{
                    scrollZoom: true,
                    zoomControl: true,
                    zoom: zoomLevel,
                    center: averageCoordinate,
                }}
            >
                {#each listings as listing}
                    <Marker lat={listing.latitude} lng={listing.longitude}>
                        <div slot="popup">
                            <ListingMarker {...listing} {data} />
                        </div>
                    </Marker>
                {/each}
            </Map>
        </div>
    </div>
{/if}
