<script lang="ts">
    export let data;
    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    import { onMount } from "svelte";
    import ListingMarker from "$lib/ListingMarker.svelte";
    import GeocodeSearchbar from "$lib/GeocodeSearchbar.svelte";
    import { ConicGradient, getToastStore } from "@skeletonlabs/skeleton";
    import type { ConicStop } from "@skeletonlabs/skeleton";
    const conicStops: ConicStop[] = [
        { color: "transparent", start: 0, end: 25 },
        { color: "rgb(var(--color-primary-500))", start: 75, end: 100 },
    ];
    let loaded = true;
    const toastStore = getToastStore();
    let listings = [];
    let addressString = "";
    let addressPoint = "";
    let addressSuburb = "";
    let selectedChargerType = 'all'; // Add charger type selection
    let userHomePlace;
    let userWorkPlace;
    $: addressPoint, getNearbyListings();

    onMount(async () => {
        getUser();
    });

    async function getUser() {
        const { data: userData, error } = await supabase
            .from("users")
            .select(
                `
            user_name,
            home_place:home_place_id (
                address,
                point,
                suburb
            ),
            work_place:work_place_id (
                address,
                point,
                suburb
            )
        `,
            )
            .eq("user_id", session.user.id)
            .single();

        if (error) {
            return;
        }
        userHomePlace = userData.home_place ? userData.home_place : null;
        userWorkPlace = userData.work_place ? userData.work_place : null;
    }

    async function getNearbyListings() {
        console.log("getNearbyListings", addressPoint);
        if (!addressPoint || addressPoint === "") return;
        loaded = false;
        const { data, error } = await supabase.rpc("get_listings_near", {
            query_location: addressPoint,
            limit_count: 100,
        });
        if (error) {
            console.error("error", error);
            toastStore.trigger({
                message: "Error fetching listings",
                background: "variant-filled-error",
            });
            return;
        } else {
            listings = data;
            if (selectedChargerType !== 'all') {
                listings = listings.filter(listing => listing.charger_type === selectedChargerType); // Apply charger type filter
            }
            averageCoordinate = getAverageCoordinate(listings);
            zoomLevel = getZoomLevel(listings);
            listings = fuzzClusteredListings(listings);
        }
        loaded = true;
    }

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

<style>
  .filter {
    display: flex;
    gap: 10px;
    margin-bottom: 1rem;
  }
</style>

<label class="label flex mb-2">
    <GeocodeSearchbar
        bind:addressString
        bind:addressPoint
        bind:addressSuburb
        query={addressString}
        n={1}
    />
    <button type="button" class="btn m-2 variant-filled" disabled>
        <i class="fa-solid fa-filter"></i>
    </button>
    <select bind:value={selectedChargerType} class="btn m-2 variant-filled">
        <option value="all">All Chargers</option>
        <option value="Mennekes">Mennekes</option>
        <option value="Type 1">Type 1</option>
        <option value="CHAdeMO">CHAdeMO</option>
        <option value="CCS">CCS</option>
        <option value="CCS2">CCS2</option>
        <option value="Tesla">Tesla</option>
        <option value="GB/T">GB/T</option>
    </select>
    <button
        class="btn variant-filled m-2"
        disabled={!userHomePlace}
        on:click={() => {
            addressString = userHomePlace.address;
            addressPoint = userHomePlace.point;
            addressSuburb = userHomePlace.suburb;
        }}><i class="fa-solid fa-house"></i></button
    >
    <button
        class="btn variant-filled m-2"
        disabled={!userWorkPlace}
        on:click={() => {
            addressString = userWorkPlace.address;
            addressPoint = userWorkPlace.point;
            addressSuburb = userWorkPlace.suburb;
        }}><i class="fa-solid fa-briefcase"></i></button
    >
</label>
{#if !loaded}
    <div class="flex justify-center items-center h-full">
        <ConicGradient stops={conicStops} spin>Loading results...</ConicGradient
        >
    </div>
{:else if averageCoordinate && zoomLevel}
    <div class="card p-4 h-[75vh] overflow-auto z-0">
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
{:else}
    <div class="card p-4 h-[75vh] overflow-auto">
        <div class="flex justify-center items-center h-[90%]">
            <h4 class="h4">Enter an address to get started</h4>
        </div>
    </div>
{/if}
