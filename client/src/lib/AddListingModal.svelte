<script lang="ts">
    import WeekTableListing from "$lib/WeekTableListing.svelte";
    import GeocodeSearchbar from "$lib/GeocodeSearchbar.svelte";
    import {
        getModalStore,
        getModeUserPrefers,
        getToastStore,
    } from "@skeletonlabs/skeleton";
    const modalStore = getModalStore();
    const toastStore = getToastStore();
    let data = $modalStore[0].meta.data;
    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    let selectedDate = new Date().toISOString().split("T")[0];
    let listingAddressString = "";
    let listingAddressPoint;
    let listingAddressSuburb;
    let pricePerHour: number;
    let chargingMode: string;
    let chargerType: string;
    let sustainable: boolean = false;
    let availabilities = [];
    let userHomePlace;
    let userWorkPlace;

    // Loader
    import { onMount } from "svelte";
    import { ConicGradient } from "@skeletonlabs/skeleton";
    import type { ConicStop } from "@skeletonlabs/skeleton";
    const conicStops: ConicStop[] = [
        { color: "transparent", start: 0, end: 25 },
        { color: "rgb(var(--color-primary-500))", start: 75, end: 100 },
    ];
    let loaded = false;

    async function publishListing() {
        if (
            isNaN(pricePerHour) ||
            !listingAddressString ||
            !listingAddressPoint ||
            !chargingMode ||
            !chargerType ||
            !availabilities.length
        ) {
            toastStore.trigger({
                message: "Invalid input - check fields",
                background: "variant-filled-warning",
            });
            return;
        }
        let formattedAvailabilities = [];

        // create place or retrieve id
        const { data: placeData, error: placeError } = await supabase
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
        const placeId = placeData[0].place_id;

        // create listing or retrieve id
        const { data: listingData, error: listingError } = await supabase
            .from("listings")
            .upsert(
                [
                    {
                        user_id: session.user.id,
                        place_id: placeId,
                        price_per_hour: pricePerHour,
                        charging_mode: chargingMode,
                        charger_type: chargerType,
                        sustainable,
                    },
                ],
                {
                    onConflict: [
                        "user_id",
                        "place_id",
                        "price_per_hour",
                        "charging_mode",
                        "charger_type",
                        "sustainable",
                    ],
                },
            )
            .select("*");
        const listingId = listingData[0].listing_id;

        // format and insert availabilities
        for (const availability of availabilities) {
            const { startTime, endTime } = availability;
            formattedAvailabilities.push({
                listing_id: listingId,
                start_time: startTime,
                end_time: endTime,
            });
        }
        try {
            console.log(formattedAvailabilities);
            const { data, error } = await supabase
                .from("availabilities")
                .upsert(formattedAvailabilities, {
                    onConflict: ["listing_id", "start_time"],
                });
            if (error) {
                console.error("error", error);
                toastStore.trigger({
                    message: "Error creating listing",
                    background: "variant-filled-warning",
                });
                return;
            }
            toastStore.trigger({
                message: "Listing published successfully",
                background: "variant-filled-success",
            });
            modalStore.close();
        } catch (error) {
            console.error("error", error);
            toastStore.trigger({
                message: "Error publishing listing",
                background: "variant-filled-warning",
            });
        }
    }

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
</script>

<div class="card m-4 p-4 w-3/5">
    <div class="w-full items-center text-center">
        <h2 class="h4 mb-2">List charging availability</h2>
    </div>
    <div class="grid grid-cols-2 gap-2 items-end">
        <div>
            <label class="label mt-2">
                <div class="flex justify-between items-end">
                    <span class="text-left">Address</span>
                    <div class="flex justify-end">
                        <button
                            class="btn-icon btn-icon-sm variant-filled mx-1"
                            disabled={!userHomePlace}
                            on:click={() => {
                                listingAddressString = userHomePlace.address;
                                listingAddressPoint = userHomePlace.point;
                                listingAddressSuburb = userHomePlace.suburb;
                            }}><i class="fa-solid fa-house"></i></button
                        >
                        <button
                            class="btn-icon btn-icon-sm variant-filled mx-1"
                            disabled={!userWorkPlace}
                            on:click={() => {
                                listingAddressString = userWorkPlace.address;
                                listingAddressPoint = userWorkPlace.point;
                                listingAddressSuburb = userWorkPlace.suburb;
                            }}><i class="fa-solid fa-briefcase"></i></button
                        >
                    </div>
                </div>
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
        <div class="mt-1 flex justify-center items-center text-center">
            <label class="flex items-center space-x-2">
                <input
                    class="checkbox"
                    type="checkbox"
                    bind:checked={sustainable}
                />
                <p>Sustainably generated</p>
            </label>
        </div>
        <div class="mt-1 flex justify-center items-center text-center">
            <label class="flex items-center space-x-2">
                <input class="checkbox" type="checkbox" disabled />
                <p class="text-gray-400">Recur for 3 months</p>
            </label>
        </div>
    </div>
    <div class="mt-4">
        <WeekTableListing bind:targetDate={selectedDate} bind:availabilities />
    </div>
    <div class="w-full flex justify-center m-auto">
        <button
            class="btn mt-2 mb-0 variant-filled-primary rounded-full"
            on:click={publishListing}
        >
            Publish
        </button>
    </div>
</div>
