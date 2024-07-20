<script>
    import { getModalStore } from "@skeletonlabs/skeleton";
    let modalStore = getModalStore();
    let rating = 3;

    function setRating(value) {
        rating = value;
        console.log(rating);
    }

    function handleMouseOver(value) {
        console.log(value);
        tempRating = value;
    }

    function handleMouseOut() {
        tempRating = rating;
    }

    let tempRating = rating;
</script>

<div class="card m-4 p-4 max-w-2/5">
    <div class="w-full items-center text-center">
        <h2 class="h4 mb-2">Rate user</h2>
    </div>
    <div class="w-full text-center">
        <h3 class="h4 mb-2">
            {$modalStore[0].meta.displayName} <i class="fa-solid fa-star"></i>
            {$modalStore[0].meta.rating}
        </h3>
    </div>
    <div class="flex items-center justify-center">
        <i>Rate the user out of 5 stars.</i>
    </div>
    <div class="flex items-center justify-center my-2">
        <div class="flex items-center justify-center">
            {#if rating}
                {#each Array.from({ length: 5 }) as _, i}
                    {#if tempRating >= i + 1}
                        <i
                            class="fa-solid fa-star"
                            on:click={() => setRating(i + 1)}
                            on:mouseover={() => handleMouseOver(i + 1)}
                            on:mouseout={handleMouseOut}
                        ></i>
                    {:else if tempRating > i}
                        <i
                            class="fa-solid fa-star-half"
                            on:click={() => setRating(i + 0.5)}
                            on:mouseover={() => handleMouseOver(i + 0.5)}
                            on:mouseout={handleMouseOut}
                        ></i>
                    {:else}
                        <i
                            class="fa-regular fa-star"
                            on:click={() => setRating(i + 1)}
                            on:mouseover={() => handleMouseOver(i + 1)}
                            on:mouseout={handleMouseOut}
                        ></i>
                    {/if}
                {/each}
            {/if}
        </div>
    </div>
</div>
