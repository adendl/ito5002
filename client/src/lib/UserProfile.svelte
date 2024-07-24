<script>
    export let data;

    import { onMount } from "svelte";
    import { getToastStore } from "@skeletonlabs/skeleton";
    import GeocodeSearchbar from "$lib/GeocodeSearchbar.svelte";

    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    async function signOut() {
        const { error } = await supabase.auth.signOut("global");
        window.location.href = "/login";
    }

    let displayName = session.user.user_metadata.full_name;
    let contactNumber = "";
    let homeAddress = "";
    let homeAddressPoint = "";
    let homeAddressSuburb = "";
    let workAddress = "";
    let workAddressPoint = "";
    let workAddressSuburb = "";
    let rating = null;
    let loaded = false;

    onMount(async () => {
        await getUser();
        loaded = true;
    });

    async function getUser() {
        const { data: user, error } = await supabase
            .from("users")
            .select(
                `
            phone_number,
            name,
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
            console.error("error", error);
            return;
        }
        console.log(user);
        if (user) {
            contactNumber = user.phone_number;
            displayName = user.name;
            homeAddress = user.home_place ? user.home_place.address : null;
            homeAddressPoint = user.home_place ? user.home_place.point : null;
            homeAddressSuburb = user.home_place ? user.home_place.suburb : null;
            workAddress = user.work_place ? user.work_place.address : null;
            workAddressPoint = user.work_place ? user.work_place.point : null;
            workAddressSuburb = user.work_place ? user.work_place.suburb : null;
        }
    }

    async function updateUser() {
        // create places or retrieve ids
        let places = [];
        if (homeAddress) {
            places.push({
                address: homeAddress,
                point: homeAddressPoint,
                suburb: homeAddressSuburb,
            });
        }
        if (workAddress) {
            places.push({
                address: workAddress,
                point: workAddressPoint,
                suburb: workAddressSuburb,
            });
        }
        const { data: placeData, error: placeError } = await supabase
            .from("places")
            .upsert(places, {
                onConflict: ["address", "point"],
            })
            .select("*");

        if (placeError) {
            console.error("error", placeError);
            toastStore.trigger(errorToast);
            return;
        }

        const homePlaceId = placeData.find(
            (place) => place.address === homeAddress,
        )?.id;
        const workPlaceId = placeData.find(
            (place) => place.address === workAddress,
        )?.id;

        const { data: user, error } = await supabase.from("users").upsert([
            {
                user_id: session.user.id,
                name: displayName,
                phone_number: contactNumber,
                home_place_id: homePlaceId,
                work_place_id: workPlaceId,
            },
        ]);
        if (error) {
            console.error("error", error);
            toastStore.trigger(errorToast);
            return;
        } else {
            toastStore.trigger(successToast);
        }
    }

    // Error toasts
    const toastStore = getToastStore();
    const errorToast = {
        message: "Error updating user",
        background: "variant-filled-warning",
    };
    const successToast = {
        message: "User updated successfully",
        background: "variant-filled-success",
    };
</script>

<div class="p-2 m-2 w-full">
    <h4 class="h4 m-2">User Profile</h4>
    <div class="flex items-center justify-center my-4">
        <div class="flex items-center justify-center">
            {#if rating}
                {#each Array.from({ length: 5 }) as _, i}
                    {#if rating >= i + 1}
                        <i class="fa-solid fa-star"></i>
                    {:else if rating > i}
                        <i class="fa-solid fa-star-half"></i>
                    {:else}
                        <i class="fa-regular fa-star"></i>
                    {/if}
                {/each}(35)
            {/if}
        </div>
    </div>

    <label class="label m-2">
        <span>Name</span>
        <input
            disabled
            class="input"
            type="text"
            placeholder="Input"
            bind:value={displayName}
        />
    </label>
    <label class="label m-2">
        <span>Contact number</span>
        <input
            class="input"
            type="text"
            placeholder="Input contact number"
            bind:value={contactNumber}
        />
    </label>
    <label class="label m-2">
        <span>Home address</span>
        <GeocodeSearchbar
            bind:addressString={homeAddress}
            bind:addressPoint={homeAddressPoint}
            bind:addressSuburb={homeAddressSuburb}
            query={homeAddress}
            n={1}
        />
    </label>
    <label class="label m-2">
        <span>Work address</span>
        <GeocodeSearchbar
            bind:addressString={workAddress}
            bind:addressPoint={workAddressPoint}
            bind:addressSuburb={workAddressSuburb}
            query={workAddress}
            n={2}
        />
    </label>
    <div class="flex items-center justify-center">
        <button on:click={updateUser} class="btn variant-filled-primary my-4"
            >Update</button
        >
    </div>
    <div class="flex items-center justify-center">
        <button class="btn variant-filled" on:click={signOut}>Sign out</button>
    </div>
</div>
