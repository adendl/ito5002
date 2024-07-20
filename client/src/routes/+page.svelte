<script>
    import { dummyListingCards } from "../lib/dummyData/listingCards.js";
    import ListingCard from "$lib/ListingCard.svelte";
    import dummyMap from "$lib/dummyData/dummyMap.png";

</script>

<div class="grid grid-cols-2 gap-4 h-full relative">
    <div class="card p-4 h-full w-full relative overflow-auto">
        <span class="flex justify-between items-center">
            <h3 class="h4 mb-3">Charging available nearby</h3>
            <div>
                <button type="button" class="btn m-2 variant-filled"
                    ><i class="fa-solid fa-filter"></i></button
                >
            </div>
        </span>
        {#each dummyListingCards as listingCard}
            <ListingCard {...listingCard} />
        {/each}
    </div>
    <div class="card p-4 h-full w-full relative overflow-auto">
        <img src={dummyMap} alt="Map" class="w-full h-full rounded-lg" />
        <div
            class="absolute top-0 left-0 flex justify-center items-center w-full h-full"
        >
            <div class="flex justify-center items-center">
                <button
                    type="button"
                    class="btn btn-icon variant-ghost"
                    style="position: absolute; top: 30%; left: 20%;"
                >
                    <i class="fa-solid fa-location-dot"></i>
                </button>
                <button
                    type="button"
                    class="btn btn-icon variant-ghost"
                    style="position: absolute; top: 50%; left: 60%;"
                >
                    <i class="fa-solid fa-location-dot"></i>
                </button>
                <button
                    type="button"
                    class="btn btn-icon variant-ghost"
                    style="position: absolute; top: 70%; left: 40%;"
                >
                    <i class="fa-solid fa-location-dot"></i>
                </button>
                <button
                    type="button"
                    class="btn btn-icon variant-ghost"
                    style="position: absolute; top: 35%; left: 65%;"
                >
                    <i class="fa-solid fa-location-dot"></i>
                </button>
            </div>
        </div>
    </div>
</div>
