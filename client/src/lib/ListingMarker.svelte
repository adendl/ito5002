<script>
    export let listing_id;
    export let user_id;
    export let user_name;
    export let rating;
    export let place_id;
    export let suburb;
    export let address;
    export let price_per_hour;
    export let charging_mode;
    export let charger_type;
    export let sustainable;
    export let distance;
    export let data;

    import { getModalStore } from "@skeletonlabs/skeleton";

    const modalStore = getModalStore();
    import BookModal from "$lib/BookModal.svelte";
    const bookModalRef = { ref: BookModal };
    const bookModal = {
        type: "component",
        component: bookModalRef,
        meta: {
            listing_id,
            user_id,
            user_name,
            rating,
            place_id,
            suburb,
            address,
            price_per_hour,
            charging_mode,
            charger_type,
            sustainable,
            distance,
            data,
        },
    };

    function triggerModal(modalId) {
        console.log(modalId);
        modalStore.trigger(modalId);
    }
</script>

<div
    class="card p-4"
    on:click={() => {
        triggerModal(bookModal);
    }}
>
    <h4 class="h4 mb-3">
        {suburb}: {charging_mode} - {charger_type}
        @ ${price_per_hour}
        per hour
    </h4>
    <p>
        {user_name}
        {#if rating}
            <i class="fa-solid fa-star"></i>
            {rating}
        {/if}
    </p>
</div>
