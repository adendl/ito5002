<script>
    export let displayName;
    export let rating;
    export let suburb;
    export let mode;
    export let type;
    export let pricePerHour;
    export let sustainable;

    import { getModalStore } from "@skeletonlabs/skeleton";

    const modalStore = getModalStore();
    import BookModal from "$lib/BookModal.svelte";
    import RateUserModal from "./RateUserModal.svelte";
    const bookModalRef = { ref: BookModal };
    const bookModal = {
        type: "component",
        component: bookModalRef,
        meta: {
            displayName,
            rating,
            suburb,
            mode,
            type,
            pricePerHour,
            sustainable,
        },
    };

    function triggerModal(modalId) {
        console.log(modalId);
        modalStore.trigger(modalId);
    }
</script>

<div
    class="card p-4 my-4 variant-ghost-surface card-hover"
    on:click={() => {
        triggerModal(bookModal);
    }}
>
    <div class="flex">
        <div class="flex ml-2 w-1/12 flex-col justify-center items-right">
            {#if sustainable}
                <button type="button" class="btn-icon variant-ghost-success"
                    ><i class="fa-solid fa-recycle"></i></button
                >
            {:else}
                <button type="button" class="btn-icon variant-ghost-error"
                    ><i class="fa-solid fa-fire-flame-simple"></i></button
                >
            {/if}
        </div>
        <div class="flex w-11/12 flex-col">
            <h4 class="h4 mb-3">
                {suburb}: Mode {mode} - {type} @ ${pricePerHour} per hour
            </h4>
            <p>
                {displayName} <i class="fa-solid fa-star"></i>
                {rating}
            </p>
        </div>
    </div>
</div>
