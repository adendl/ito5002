<script lang="ts">
    export let data;
    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    import { onMount } from "svelte";
    import ListingMarker from "$lib/ListingMarker.svelte";
    import GeocodeSearchbar from "$lib/GeocodeSearchbar.svelte";
    import {
        ConicGradient,
        getToastStore,
        ListBox,
        ListBoxItem,
        popup,
    } from "@skeletonlabs/skeleton";
    import type { ConicStop, PopupSettings } from "@skeletonlabs/skeleton";
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
    let userHomePlace;
    let userWorkPlace;
    let filteredChargerType;
    let blankMessage = "Enter a address to get started";
    $: addressPoint, getNearbyListings();
    $: filteredChargerType, getNearbyListings();

    const popupCombobox: PopupSettings = {
        event: "click",
        target: "popupCombobox",
        placement: "bottom",
        closeQuery: ".listbox-item",
    };

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
        blankMessage = "No results found"; 
        mapComponent = null;
        averageCoordinate = null;
        zoomLevel = null;
        const { data, error } = await supabase.rpc("get_listings_near", {
            query_location: addressPoint,
            limit_count: 100,
            charger_type_param: filteredChargerType
                ? filteredChargerType
                : null,
        });
        if (error) {
            console.error("error", error);
            toastStore.trigger({
                message: "Error fetching listings",
                background: "variant-filled-error",
            });
            loaded = true;
            return;
        } else {
            if (data.length === 0) {
                toastStore.trigger({
                    message: "No results found",
                    background: "variant-filled-error",
                });
                loaded = true;
                return;
            }
            listings = data;
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

<label class="label flex mb-2">
    <GeocodeSearchbar
        bind:addressString
        bind:addressPoint
        bind:addressSuburb
        query={addressString}
        n={1}
    />
    <button
        type="button"
        class="btn m-2 variant-filled"
        use:popup={popupCombobox}
    >
        <i class="fa-solid fa-filter"></i>
    </button>
    <div class="card w-48 shadow-xl py-2 z-50" data-popup="popupCombobox">
        <ListBox rounded="rounded-none">
            <ListBoxItem bind:group={filteredChargerType} value=""
                >All</ListBoxItem
            >
            <ListBoxItem bind:group={filteredChargerType} value="Mennekes"
                >Mennekes</ListBoxItem
            >
            <ListBoxItem bind:group={filteredChargerType} value="Type 1"
                >Type 1</ListBoxItem
            >
            <ListBoxItem bind:group={filteredChargerType} value="CHaDeMO"
                >CHaDeMO</ListBoxItem
            >
            <ListBoxItem bind:group={filteredChargerType} value="CCS"
                >CCS</ListBoxItem
            >
            <ListBoxItem bind:group={filteredChargerType} value="CCS2"
                >CCS2</ListBoxItem
            >
            <ListBoxItem bind:group={filteredChargerType} value="Tesla"
                >Tesla</ListBoxItem
            >
            <ListBoxItem bind:group={filteredChargerType} value="GB/T"
                >GB/T</ListBoxItem
            >
        </ListBox>
        <div class="arrow bg-surface-100-800-token" />
    </div>
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
            <h4 class="h4">{blankMessage}</h4>
        </div>
    </div>
{/if}
