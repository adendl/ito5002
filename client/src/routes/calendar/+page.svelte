<script lang="ts">
    export let data;
    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    import { TabGroup, Tab } from "@skeletonlabs/skeleton";
    import CalendarListingView from "../../lib/CalendarListingView.svelte";

    let tabSet = 0;
</script>

<div class="">
    <TabGroup class="mt-2">
        <Tab bind:group={tabSet} name="tab1" value={0}>
            <svelte:fragment slot="lead"></svelte:fragment>
            <span>My listings</span>
        </Tab>
        <Tab bind:group={tabSet} name="tab2" value={1}>My bookings</Tab>
        <svelte:fragment slot="panel">
            {#if tabSet === 0}
                <CalendarListingView bind:data />
            {:else if tabSet === 1}
                Wawawoowa
            {/if}
        </svelte:fragment>
    </TabGroup>
</div>
