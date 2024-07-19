<script>
    import { TabGroup, Tab, TabAnchor } from "@skeletonlabs/skeleton";
    import WeekTable from "$lib/WeekTable.svelte";
    let tabSet = 0;
</script>

<div class="card m-4 p-4 w-1/2">
    <div class="w-full items-center text-center">
        <h2 class="h4 mb-2">Add charging availability</h2>
    </div>
    <label class="label my-2">
        <span>Address</span>
        <input class="input" type="text" placeholder="Enter address..." />
    </label>
    <div class="grid grid-cols-2 gap-4">
        <div>
            <label class="label">
                <span>Charging mode</span>
                <select class="select">
                    <option value="1">Mode 1</option>
                    <option value="2">Mode 2</option>
                    <option value="3">Mode 3</option>
                    <option value="4">Mode 4</option>
                </select>
            </label>
        </div>
        <div>
            <label class="label">
                <span>Charger type</span>
                <select class="select">
                    <option value="1">Mennekes</option>
                    <option value="2">Type 1</option>
                    <option value="3">CHaDeMO</option>
                    <option value="4">CCS</option>
                    <option value="5">CCS2</option>
                    <option value="6">Tesla</option>
                    <option value="7">GB/T</option>
                </select>
            </label>
        </div>
        <div>
            <label class="label">Price per hour</label>
            <div
                class="input-group input-group-divider grid-cols-[auto_1fr_auto]"
            >
                <div class="input-group-shim">
                    <i class="fa-solid fa-dollar-sign"></i>
                </div>
                <input type="text" placeholder="Amount" />
                <select disabled>
                    <option>AUD</option>
                </select>
            </div>
        </div>
        <div>
            <label class="ml-2 mt-8 flex items-center space-x-2">
                <input class="checkbox" type="checkbox" />
                <p>Sustainably generated</p>
            </label>
        </div>
    </div>
    <TabGroup class="mt-2">
        <Tab bind:group={tabSet} name="tab1" value={0}>
            <svelte:fragment slot="lead"></svelte:fragment>
            <span>One-off</span>
        </Tab>
        <Tab bind:group={tabSet} name="tab2" value={1}>Recurring</Tab>
        <svelte:fragment slot="panel">
            {#if tabSet === 0}
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="label">
                            <span>Window start</span>
                            <input
                                class="input"
                                type="datetime-local"
                                placeholder=""
                            />
                        </label>
                    </div>
                    <div>
                        <label class="label">
                            <span>Window end</span>
                            <input
                                class="input"
                                type="datetime-local"
                                placeholder=""
                            />
                        </label>
                    </div>
                </div>
            {:else if tabSet === 1}
                <WeekTable />
            {/if}
        </svelte:fragment>
    </TabGroup>
    <div class="w-full flex justify-center m-auto">
        <button class="btn mt-4 mb-0 variant-filled-primary rounded-full">
            Publish
        </button>
    </div>
</div>
