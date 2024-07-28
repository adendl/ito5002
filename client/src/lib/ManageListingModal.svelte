<script lang="ts">
    import { getModalStore, getToastStore } from "@skeletonlabs/skeleton";
    import { onMount } from "svelte";
    const modalStore = getModalStore();
    const toastStore = getToastStore();
    let data = $modalStore[0].meta.data;
    let { supabase, session } = data;
    $: ({ supabase, session } = data);
    import GeocodeSearchbar from "$lib/GeocodeSearchbar.svelte";

    let listing;
    let listingAddressString;
    let listingAddressPoint;
    let listingAddressSuburb;
    let pricePerHour;
    let chargingMode;
    let chargerType;
    let sustainable;

    // loader
    import { ConicGradient } from "@skeletonlabs/skeleton";
    import type { ConicStop } from "@skeletonlabs/skeleton";
    let loaded = false;
    const conicStops: ConicStop[] = [
        { color: "transparent", start: 0, end: 25 },
        { color: "rgb(var(--color-primary-500))", start: 75, end: 100 },
    ];

    onMount(async () => {
        getListing($modalStore[0].meta.listing_id);
    });

    async function getListing(listing_id) {
        loaded = false;
        let { data, error } = await supabase
            .from("listings")
            .select(
                `
        *,
        places!inner(*)
    `,
            )
            .eq("listing_id", listing_id);
        if (error) {
            console.error("error", error);
        } else {
            listing = data[0];
            listingAddressString = listing.places.address;
            listingAddressPoint = listing.places.point;
            listingAddressSuburb = listing.places.suburb;
            pricePerHour = listing.price_per_hour;
            chargingMode = listing.charging_mode;
            chargerType = listing.charger_type;
            sustainable = listing.sustainable;
        }
        loaded = true;
        console.log(listing);
    }

    async function updateListing() {
        let { data: placeData, error: placeError } = await supabase
            .from("places")
            .upsert(
                [
                    {
                        address: listingAddressString,
                        point: listingAddressPoint,
                        suburb: listingAddressSuburb,
                    },
                ],
                {
                    onConflict: ["address", "point"],
                },
            )
            .select("*");
        if (placeError) {
            toastStore.trigger({
                message: "Error updating listing",
                background: "variant-filled-warning",
            });
            console.error("error", placeError);
            return;
        }
        const placeId = placeData[0].place_id;
        let { data: data, error: error } = await supabase
            .from("listings")
            .upsert(
                [
                    {
                        listing_id: $modalStore[0].meta.listing_id,
                        price_per_hour: pricePerHour,
                        charging_mode: chargingMode,
                        charger_type: chargerType,
                        user_id: session.user.id,
                        place_id: placeId,
                        sustainable,
                    },
                ],
                {
                    onConflict: ["listing_id"],
                },
            )
            .select("*");
        if (error) {
            toastStore.trigger({
                message: "Error updating listing",
                background: "variant-filled-warning",
            });
            console.error("error", error);
        } else {
            toastStore.trigger({
                message: "Listing updated",
                background: "variant-filled-success",
            });
        }
    }

    // Remove availabilities for this listing where there is not a booking
    async function removeAvailabilities() {
        // Get all availabilities for this listing and their bookings
        const { data, error } = await supabase
            .from("availabilities")
            .select(
                `
        *,
        bookings(*)
    `,
            )
            .eq("listing_id", $modalStore[0].meta.listing_id);

        if (error) {
            toastStore.trigger({
                message: "Error removing availabilities",
                background: "variant-filled-warning",
            });
            console.error("error", error);
            return;
        }

        // Remove availabilities where there is no booking
        const filteredAvailabilities = data.filter((availability) => {
            return availability.bookings === null;
        });

        // Remove availabilities
        const { data: deleteData, error: deleteError } = await supabase
            .from("availabilities")
            .delete()
            .in(
                "availability_id",
                filteredAvailabilities.map(
                    (availability) => availability.availability_id,
                ),
            );
        if (deleteError) {
            toastStore.trigger({
                message: "Error removing availabilities",
                background: "variant-filled-warning",
            });
            console.error("error", deleteError);
        } else {
            toastStore.trigger({
                message: "Availabilities removed",
                background: "variant-filled-success",
            });
        }
    }

    // Remove listing and cascade deletions
    async function removeListing() {
        let { data: data, error: error } = await supabase
            .from("listings")
            .delete()
            .eq("listing_id", $modalStore[0].meta.listing_id);
        if (error) {
            toastStore.trigger({
                message: "Error removing listing",
                background: "variant-filled-warning",
            });
            console.error("error", error);
        } else {
            toastStore.trigger({
                message: "Listing removed",
                background: "variant-filled-success",
            });
        }
    }

    // Information popups
    import { popup } from "@skeletonlabs/skeleton";
    import type { PopupSettings } from "@skeletonlabs/skeleton";
    const popupHover: PopupSettings = {
        event: "hover",
        target: "popupHover",
        placement: "top",
    };
    const popupHover2: PopupSettings = {
        event: "hover",
        target: "popupHover2",
        placement: "top",
    };
</script>

{#if $modalStore[0]}
    {#if loaded}
        <div class="card m-4 p-4 w-3/5">
            <div class="w-full items-center text-center">
                <h2 class="h4 mb-2">Manage listing</h2>
            </div>
            <div>
                <div class="grid grid-cols-2 gap-2">
                    <div>
                        <label class="label mt-2">
                            <span>Address</span>
                            <GeocodeSearchbar
                                bind:addressString={listingAddressString}
                                bind:addressPoint={listingAddressPoint}
                                bind:addressSuburb={listingAddressSuburb}
                                query={listingAddressString}
                                n={1}
                            />
                        </label>
                    </div>
                    <div>
                        <label class="label mt-2"
                            ><span>Price per hour</span>
                            <div
                                class="input-group input-group-divider grid-cols-[auto_1fr_auto]"
                            >
                                <div class="input-group-shim">
                                    <i class="fa-solid fa-dollar-sign"></i>
                                </div>
                                <input
                                    type="text"
                                    placeholder="Amount"
                                    bind:value={pricePerHour}
                                />
                                <select disabled>
                                    <option>AUD</option>
                                </select>
                            </div>
                        </label>
                    </div>
                    <div>
                        <label class="label">
                            <span>Charging mode</span>
                            <select class="select" bind:value={chargingMode}>
                                <option value="Mode 1">Mode 1</option>
                                <option value="Mode 2">Mode 2</option>
                                <option value="Mode 3">Mode 3</option>
                                <option value="Mode 4">Mode 4</option>
                            </select>
                        </label>
                    </div>
                    <div>
                        <label class="label">
                            <span>Charger type</span>
                            <select class="select" bind:value={chargerType}>
                                <option value="Mennekes">Mennekes</option>
                                <option value="Type 1">Type 1</option>
                                <option value="CHaDeMO">CHaDeMO</option>
                                <option value="CCS">CCS</option>
                                <option value="CCS2">CCS2</option>
                                <option value="Tesla">Tesla</option>
                                <option value="GB/T">GB/T</option>
                            </select>
                        </label>
                    </div>
                    <div
                        class="mt-1 col-span-2 flex justify-center items-center text-center"
                    >
                        <label class="flex items-center space-x-2">
                            <input
                                class="checkbox"
                                type="checkbox"
                                bind:checked={sustainable}
                            />
                            <p>Sustainably generated</p>
                        </label>
                    </div>
                </div>
            </div>
            <div class="w-full mt-4 flex justify-center m-auto">
                <button
                    class="btn mt-2 mx-4 mb-0 variant-filled-primary rounded-full"
                    on:click={updateListing}
                >
                    Update details
                </button>
                <button
                    class="btn mt-2 mx-4 mb-0 variant-filled-primary rounded-full"
                    use:popup={popupHover}
                    on:click={removeAvailabilities}
                >
                    Stop listing
                </button>
                <div
                    class="card p-4 variant-filled-tertiary"
                    data-popup="popupHover"
                >
                    <p>
                        Removes all available times associated with this listing
                    </p>
                    <div class="arrow variant-filled-secondary" />
                </div>
                <button
                    class="btn mt-2 mx-4 mb-0 variant-filled-primary rounded-full"
                    use:popup={popupHover2}
                    on:click={removeListing}
                >
                    Remove listing & cancel bookings
                </button>
                <div
                    class="card p-4 variant-filled-tertiary"
                    data-popup="popupHover2"
                >
                    <p>
                        Cancel all bookings, reject all booking requests and
                        remove available times associated with this listing
                    </p>
                    <div class="arrow variant-filled-secondary" />
                </div>
            </div>
        </div>
    {:else}
        <div class="card m-4 p-4 w-3/5">
            <div class="flex justify-center items-center h-full">
                <ConicGradient stops={conicStops} spin
                    >Loading details...</ConicGradient
                >
            </div>
        </div>
    {/if}
{/if}
