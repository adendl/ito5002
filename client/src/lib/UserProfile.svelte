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
    let email = session.user.email;
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
            ),
            contacts (
                phone_number,
                email_address
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
            contactNumber = user.contacts.phone_number
                ? user.contacts.phone_number
                : null;
            email = user.contacts.email_address
                ? user.contacts.email_address
                : null;
            displayName = user.user_name;
            homeAddress = user.home_place ? user.home_place.address : null;
            homeAddressPoint = user.home_place ? user.home_place.point : null;
            homeAddressSuburb = user.home_place ? user.home_place.suburb : null;
            workAddress = user.work_place ? user.work_place.address : null;
            workAddressPoint = user.work_place ? user.work_place.point : null;
            workAddressSuburb = user.work_place ? user.work_place.suburb : null;
        }
    }

    async function updateUser() {
        try {
            // Create places or retrieve ids
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

            // RLS means we cannot upsert, so we attemt to select both places then insert any that are missing
            const { data: existingPlaces, error: existingPlacesError } =
                await supabase
                    .from("places")
                    .select("*")
                    .in("address", [homeAddress, workAddress]);

            if (existingPlacesError) {
                console.error("error", existingPlacesError);
                toastStore.trigger(errorToast);
                return;
            }

            const existingPlaceAddresses = existingPlaces.map(
                (place) => place.address,
            );
            places = places.filter(
                (place) => !existingPlaceAddresses.includes(place.address),
            );

            const { data: newPlaces, error: newPlacesError } = await supabase
                .from("places")
                .insert(places)
                .select("*");

            if (newPlacesError) {
                console.error("error", newPlacesError);
                toastStore.trigger(errorToast);
                return;
            }

            places = [...existingPlaces, ...newPlaces];

            const homePlaceId = places.find(
                (place) => place.address === homeAddress,
            )?.place_id;
            const workPlaceId = places.find(
                (place) => place.address === workAddress,
            )?.place_id;

            const { data: user, error: userError } = await supabase
                .from("users")
                .upsert([
                    {
                        user_id: session.user.id,
                        user_name: displayName,
                        home_place_id: homePlaceId,
                        work_place_id: workPlaceId,
                    },
                ]);

            if (userError) {
                console.error("error", userError);
                toastStore.trigger(errorToast);
                return;
            }
            const { data: contact, error: contactError } = await supabase
                .from("contacts")
                .upsert(
                    [
                        {
                            user_id: session.user.id,
                            phone_number: contactNumber,
                            email_address: session.user.email,
                        },
                    ],
                    {
                        onConflict: ["user_id"],
                    },
                );

            if (contactError) {
                console.error("error", contactError);
                toastStore.trigger(errorToast);
                return;
            }

            toastStore.trigger(successToast);
        } catch (error) {
            console.error("error", error);
            toastStore.trigger(errorToast);
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
        <span>Name</span>
        <input
            disabled
            class="input"
            type="text"
            placeholder="Input"
            bind:value={email}
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
