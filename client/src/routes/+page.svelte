<script lang="ts">
    export let data;
    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    import { onMount } from "svelte";
    import ListingCard from "$lib/ListingCard.svelte";
    import ListingMarker from "$lib/ListingMarker.svelte";
    import {
        ConicGradient,
        getToastStore,
        getDrawerStore,
        ListBox,
        ListBoxItem,
        popup,
    } from "@skeletonlabs/skeleton";
    import type { ConicStop } from "@skeletonlabs/skeleton";
    const conicStops: ConicStop[] = [
        { color: "transparent", start: 0, end: 25 },
        { color: "rgb(var(--color-primary-500))", start: 75, end: 100 },
    ];
    let loaded = false;
    const toastStore = getToastStore();
    const drawerStore = getDrawerStore();
    let filteredChargerType = "";
    let listings = [];
    let addressPoint;
    $: filteredChargerType, getNearbyListings();

    function openProfile() {
        drawerStore.open({
            id: "profile",
            bgDrawer: "bg-purple-900 text-white",
            bgBackdrop:
                "bg-gradient-to-tr from-indigo-500/50 via-purple-500/50 to-pink-500/50",
            width: "w-[280px] md:w-[480px]",
            padding: "p-4",
            rounded: "rounded-xl",
            position: "right",
        });
    }

    const popupCombobox: PopupSettings = {
        event: "click",
        target: "popupCombobox",
        placement: "bottom",
        closeQuery: ".listbox-item",
    };

    onMount(async () => {
        // Get user's home or default to central Sydney
        const { data: user, error: userError } = await supabase
            .from("users")
            .select(`home_place:home_place_id (point)`)
            .eq("user_id", session.user.id)
            .single();

        if (!user) {
            openProfile();
            toastStore.trigger({
                message: "Please populate profile information",
                background: "variant-filled-warning",
            });
        }

        addressPoint =
            user?.home_place?.point ||
            "0101000020E610000041BCAE5FB0E66240C87C40A033EF40C0";

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
        }
        listings = data;
        if (listings.length === 0) {
            toastStore.trigger({
                message: "No listings found",
                background: "variant-filled-error",
            });
            loaded = true;
            return;
        }
        averageCoordinate = getAverageCoordinate(listings);
        zoomLevel = getZoomLevel(listings);
        listings = fuzzClusteredListings(listings);
        listings = listings;
        loaded = true;
    });

    async function getNearbyListings() {
        console.log("getNearbyListings", addressPoint);
        if (!addressPoint || addressPoint === "") return;
        loaded = false;
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
                listings = [];
                return;
            }
            listings = data;
            listings = listings;
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
                        use:popup={popupCombobox}
                    >
                        <i class="fa-solid fa-filter"></i>
                    </button>
                    <div
                        class="card w-48 shadow-xl py-2 z-50"
                        data-popup="popupCombobox"
                    >
                        <ListBox rounded="rounded-none">
                            <ListBoxItem
                                bind:group={filteredChargerType}
                                value="">All</ListBoxItem
                            >
                            <ListBoxItem
                                bind:group={filteredChargerType}
                                value="Mennekes">Mennekes</ListBoxItem
                            >
                            <ListBoxItem
                                bind:group={filteredChargerType}
                                value="Type 1">Type 1</ListBoxItem
                            >
                            <ListBoxItem
                                bind:group={filteredChargerType}
                                value="CHaDeMO">CHaDeMO</ListBoxItem
                            >
                            <ListBoxItem
                                bind:group={filteredChargerType}
                                value="CCS">CCS</ListBoxItem
                            >
                            <ListBoxItem
                                bind:group={filteredChargerType}
                                value="CCS2">CCS2</ListBoxItem
                            >
                            <ListBoxItem
                                bind:group={filteredChargerType}
                                value="Tesla">Tesla</ListBoxItem
                            >
                            <ListBoxItem
                                bind:group={filteredChargerType}
                                value="GB/T">GB/T</ListBoxItem
                            >
                        </ListBox>
                    </div>
                </div></span
            >
            {#each listings as listingCard}
                <ListingCard {...listingCard} {data} />
            {:else}
                <div class="flex justify-center items-center h-[90%]">
                    <h4 class="h4">No listings found</h4>
                </div>
            {/each}
        </div>
        <div class="card p-4 h-full w-full relative overflow-auto">
            {#if listings.length > 0}
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
            {:else}
                <div class="flex justify-center items-center h-full">
                    <ConicGradient stops={conicStops} spin
                        >Waiting for listings...</ConicGradient
                    >
                </div>
            {/if}
        </div>
    </div>
{/if}
