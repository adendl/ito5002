<script>
    import { TabGroup, Tab } from "@skeletonlabs/skeleton";
    import WeekTable from "$lib/WeekTable.svelte";

    let tabSet = 0;
    let selectedDate = new Date().toISOString().split("T")[0];
    $: weekDates = Array.from({ length: 7 }, (_, i) => {
        let date = new Date(selectedDate);
        date.setDate(date.getDate() + i - date.getDay());
        let formattedDate = `${date.getDate()} ${date.toLocaleString("default", { month: "short" })}`;
        return formattedDate;
    });
</script>

<div class="w-full flex justify-end mt-4">
    <button
        class="button btn-icon mx-2 variant-filled"
        on:click={() => {
            let date = new Date(selectedDate);
            date.setDate(date.getDate() - 7);
            selectedDate = date.toISOString().split("T")[0];
        }}><i class="fa-solid fa-arrow-left"></i></button
    >
    <input
        tabindex="-1"
        class="input max-w-[10rem]"
        type="date"
        bind:value={selectedDate}
    />
    <button
        class="button btn-icon mx-2 variant-filled"
        on:click={() => {
            let date = new Date(selectedDate);
            date.setDate(date.getDate() + 7);
            selectedDate = date.toISOString().split("T")[0];
        }}><i class="fa-solid fa-arrow-right"></i></button
    >
</div>

<TabGroup class="mt-2">
    <Tab bind:group={tabSet} name="tab1" value={0}>
        <svelte:fragment slot="lead"></svelte:fragment>
        <span>My listings</span>
    </Tab>
    <Tab bind:group={tabSet} name="tab2" value={1}>My bookings</Tab>
    <svelte:fragment slot="panel">
        {#if tabSet === 0}
            <WeekTable listingMode={true} displayDates={weekDates} />
        {:else if tabSet === 1}
            <WeekTable listingMode={true} displayDates={weekDates} />
        {/if}
    </svelte:fragment>
</TabGroup>
