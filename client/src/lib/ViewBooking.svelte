<script>
    let type = "requested";
</script>

{#if type === "booked"}
    <div class="card m-4 p-4 w-1/2 items-center text-center">
        <div class="w-full items-center text-center">
            <h2 class="h2 mb-2">Viewing Booking:</h2>
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
            <h2 class="h2 mb-2">Viewing Booking:</h2>
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
                        Waiting for Michelle Smith ( <i class="fa-solid fa-star"
                        ></i> 4.5) to respond.
                    </h3>
                </div>
                <div>
                    <button class="btn button-s variant-filled-primary">
                        Cancel
                    </button>
                </div>
            </div>
        </div>
    </div>
{/if}
