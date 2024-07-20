<script>
    let displayName = "Jamie Smith";
    let rating = 4.5;
    let contactNumber = "0412345678";
    let address = "122 Grays St, Marrickville";
    let workAddress = "1 King St, Newtown";
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
            placeholder="Input"
            bind:value={contactNumber}
        />
    </label>
    <label class="label m-2">
        <span>Address</span>
        <input
            class="input"
            type="text"
            placeholder="Input"
            bind:value={address}
        />
    </label>
    <label class="label m-2">
        <span>Work address</span>
        <input
            class="input"
            type="text"
            placeholder="Input"
            bind:value={workAddress}
        />
    </label>
    <div class="flex items-center justify-center">
        <button class="btn variant-filled-primary mt-4">Save</button>
    </div>
</div>
