<script>
    export let data;

    import { onMount } from "svelte";
    import { getToastStore } from "@skeletonlabs/skeleton";

    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    async function signOut() {
        const { error } = await supabase.auth.signOut("global");
        window.location.href = "/login";
    }

    let displayName = session.user.user_metadata.full_name;
    let contactNumber = "";
    let address = "";
    let workAddress = "";
    let rating = null;

    onMount(async () => {
        const { data: user, error } = await supabase
            .from("users")
            .select("phone_number, home_address, work_address")
            .eq("user_id", session.user.id)
            .single();
        if (error) console.error("error", error);
        if (user) {
            contactNumber = user.phone_number;
            address = user.home_address;
            workAddress = user.work_address;
        }
    });

    async function updateUser() {
        const { data: user, error } = await supabase.from("users").upsert([
            {
                user_id: session.user.id,
                phone_number: contactNumber,
                home_address: address,
                work_address: workAddress,
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
        <span>Address</span>
        <input
            class="input"
            type="text"
            placeholder="Input home address"
            bind:value={address}
        />
    </label>
    <label class="label m-2">
        <span>Work address</span>
        <input
            class="input"
            type="text"
            placeholder="Input work address"
            bind:value={workAddress}
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
