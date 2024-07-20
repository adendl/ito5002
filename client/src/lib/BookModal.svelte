<script>
    import { getModalStore } from "@skeletonlabs/skeleton";
    import WeekTable from "$lib/WeekTable.svelte";
    import RateUserModal from "$lib/RateUserModal.svelte";

    let modalStore = getModalStore();
    let selectedDate = new Date().toISOString().split("T")[0];
    $: weekDates = Array.from({ length: 7 }, (_, i) => {
        let date = new Date(selectedDate);
        date.setDate(date.getDate() + i - date.getDay());
        let formattedDate = `${date.getDate()} ${date.toLocaleString("default", { month: "short" })}`;
        return formattedDate;
    });

    const displayName = $modalStore[0].meta.displayName;
    const rating = $modalStore[0].meta.rating;

    const rateUserModalRef = { ref: RateUserModal };
    const rateUserModal = {
        type: "component",
        component: rateUserModalRef,
        meta: {
            displayName,
            rating,
        },
    };

    function triggerRateUserModal() {
        modalStore.close();
        modalStore.trigger(rateUserModal);
    }
</script>

<div class="card m-4 p-4 w-1/2">
    <div class="w-full items-center text-center">
        <h2 class="h4 mb-2">Book charging time</h2>
    </div>
    <div class="w-full text-center">
        <h3 class="h4 mb-2">
            {$modalStore[0].meta.suburb}: Mode {$modalStore[0].meta.mode} - {$modalStore[0]
                .meta.type} @ ${$modalStore[0].meta.pricePerHour} per hour
        </h3>
        <p on:click={triggerRateUserModal}>
            <u>{$modalStore[0].meta.displayName}</u>
            <i class="fa-solid fa-star"></i>
            {$modalStore[0].meta.rating}
        </p>
    </div>
    <div class="grid grid-cols-3 mt-2">
        <div class="col-span-2 flex items-center justify-center">
            <i>Precise locations are revealed when bookings are accepted.</i>
        </div>
        <input
            tabindex="-1"
            class="input"
            type="date"
            bind:value={selectedDate}
        />
    </div>
    <div class="w-full flex justify-center m-auto my-2">
        <WeekTable bookingMode={true} displayDates={weekDates} />
    </div>
    <div class="w-full flex justify-center m-auto">
        <button class="btn mt-4 mb-0 variant-filled-primary rounded-full">
            Request booking
        </button>
    </div>
</div>
