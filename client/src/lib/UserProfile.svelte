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
    let workAddress = "";
    let workAddressPoint = "";
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
                "phone_number, home_address, home_address_point, work_address, work_address_point",
            )
            .eq("user_id", session.user.id)
            .single();
        if (error) console.error("error", error);
        if (user) {
            contactNumber = user.phone_number;
            homeAddress = user.home_address;
            homeAddressPoint = user.home_address_point;
            workAddress = user.work_address;
            workAddressPoint = user.work_address_point;
        }
    }

    async function updateUser() {
        const { data: user, error } = await supabase.from("users").upsert([
            {
                user_id: session.user.id,
                phone_number: contactNumber,
                home_address: homeAddress,
                home_address_point: homeAddressPoint,
                work_address: workAddress,
                work_address_point: workAddressPoint,
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
            query={homeAddress}
            n={1}
        />
    </label>
    <label class="label m-2">
        <span>Work address</span>
        <GeocodeSearchbar
            bind:addressString={workAddress}
            bind:addressPoint={workAddressPoint}
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
