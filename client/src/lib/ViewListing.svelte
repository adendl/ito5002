<script>
    let type = "none";
</script>

{#if type === "booked"}
    <div class="card m-4 p-4 w-1/2 items-center text-center">
        <div class="w-full items-center text-center">
            <h2 class="h2 mb-2">Viewing listing:</h2>
        </div>
        <h3 class="h4 mb-2 items-center text-center">
            Marrickville: Mode 4 - Type 1 @ $20 per hour
        </h3>
        <span class="chip variant-filled-success my-2">Booked</span>
        <h3 class="h4 mb-2 items-center text-center">
            Mike Smith ( <i class="fa-solid fa-star"></i> 4.5) has booked this listing.
        </h3>
        <h3 class="h4 mb-2 items-center text-center">
            Contact Mike on 0412345678.
        </h3>
    </div>
{:else if type === "requested"}
    <div class="card m-4 p-4 w-1/2 items-center text-center">
        <div class="w-full items-center text-center">
            <h2 class="h2 mb-2">Viewing listing:</h2>
        </div>
        <h3 class="h4 mb-2 items-center text-center">
            Marrickville: Mode 4 - Type 1 @ $20 per hour
        </h3>
        <span class="chip variant-filled-warning my-2">Requested</span>

        <div class="m-auto w-4/5 max-h-[200px] overflow-scroll">
            <div class="grid grid-cols-5 p-2">
                <div
                    class="col-span-4 flex items-center justify-center h-full ml-4 card variant-filled"
                >
                    <h3 class="h4 text-center">
                        Michelle Smith ( <i class="fa-solid fa-star"></i> 4.5) has
                        requested this listing.
                    </h3>
                </div>
                <div>
                    <button class="btn button-s variant-filled-primary">
                        Accept
                    </button>
                </div>
            </div>
            <div class="grid grid-cols-5 p-2">
                <div
                    class="col-span-4 flex items-center justify-center h-full ml-4 card variant-filled"
                >
                    <h3 class="h4 text-center">
                        Jacob Lambert ( <i class="fa-solid fa-star"></i> 3.5) has
                        requested this listing.
                    </h3>
                </div>
                <div>
                    <button class="btn button-s variant-filled-primary">
                        Accept
                    </button>
                </div>
            </div>
            <div class="grid grid-cols-5 p-2">
                <div
                    class="col-span-4 flex items-center justify-center h-full ml-4 card variant-filled"
                >
                    <h3 class="h4 text-center">
                        Arianne Yao ( <i class="fa-solid fa-star"></i> 4.5) has requested
                        this listing.
                    </h3>
                </div>
                <div>
                    <button class="btn button-s variant-filled-primary">
                        Accept
                    </button>
                </div>
            </div>
        </div>
    </div>
{:else}
    <div class="card m-4 p-4 w-1/2 items-center text-center">
        <div class="w-full items-center text-center">
            <h2 class="h2 mb-2">Viewing listing:</h2>
        </div>
        <h3 class="h4 mb-2 items-center text-center">
            Marrickville: Mode 4 - Type 1 @ $20 per hour
        </h3>
        <span class="chip variant-filled-warning my-2">Open</span>
        <div>
            <button class="btn button-s variant-filled-primary mx-2 my-2">
                Cancel</button
            >
            <button class="btn button-s variant-filled-primary mx-2 my-2">
                Cancel recurring</button
            >
        </div>
    </div>
{/if}
