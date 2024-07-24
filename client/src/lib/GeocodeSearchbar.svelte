<script lang="ts">
    export let query: string = "";
    export let addressString: string = "";
    export let addressPoint: string = "";
    export let n: number;

    // Key restricted to requests from the prod service so can be public
    const mapBoxKey =
        "pk.eyJ1Ijoib2otc2VjIiwiYSI6ImNseXpjY3dyaTBvZDUya29uZDd6aGdnbjgifQ.P37-v7FO0PAZ8eKtaluTsw";

    import { Autocomplete, popup, getToastStore } from "@skeletonlabs/skeleton";
    import type {
        PopupSettings,
        AutocompleteOption,
    } from "@skeletonlabs/skeleton";

    let queryActive: boolean = false;
    let selectedLocationObject = {};

    let selectedLocationObjectExists: boolean = false;
    $: selectedLocationObjectExists =
        Object.keys(selectedLocationObject).length > 0 ||
        addressPoint !== "POINT(undefined undefined)";

    let popupSettings: PopupSettings = {
        event: "focus-click",
        target: `popupAutocomplete${n}`,
        placement: "bottom",
    };
    let popupWindow: HTMLElement;

    var locationOptions: AutocompleteOption<string>[] = [];

    async function onSelect(event: CustomEvent<AutocompleteOption<string>>) {
        const url = `https://api.mapbox.com/search/searchbox/v1/retrieve/${event.detail.data.mapbox_id}?access_token=${mapBoxKey}&session_token=communitypower`;
        try {
            const response = await fetch(url, {
                headers: {
                    "User-Agent": "CommunityPower",
                },
            });
            selectedLocationObject = await response.json();
            console.log(selectedLocationObject);
            addressPoint = `POINT(${selectedLocationObject.features[0].geometry.coordinates[0]} ${selectedLocationObject.features[0].geometry.coordinates[1]})`;
            addressString =
                selectedLocationObject.features[0].properties.full_address;
            query = addressString;
        } catch (error) {
            console.error("Error:", error);
            toastStore.trigger({
                message: "Error retrieving address",
                background: "variant-filled-error",
            });
        }
    }

    async function geocodeSearch() {
        queryActive = true;
        // TOS compliance, delaying requests by users
        await new Promise((resolve) => setTimeout(resolve, 100));
        const url = `https://api.mapbox.com/search/searchbox/v1/suggest?q=${query}&access_token=${mapBoxKey}&session_token=communitypower`;
        try {
            const response = await fetch(url, {
                headers: {
                    "User-Agent": "CommunityPower",
                },
            });
            const reponseJSON = await response.json();
            console.log(reponseJSON);
            const candidates = reponseJSON.suggestions;
            if (candidates === 0) {
                toastStore.trigger({
                    message: "No results for address",
                    background: "variant-filled-warning",
                });
                queryActive = false;
                return;
            }
            locationOptions = candidates.map((candidate) => {
                return {
                    value: candidate.full_address.replace(",", ""),
                    label: candidate.full_address.replace(",", ""),
                    keywords: query,
                    data: candidate,
                };
            });
            console.log(locationOptions);
            locationOptions = locationOptions;
            popupWindow.click();
        } catch (error) {
            console.error("Error:", error);
            toastStore.trigger({
                message: "Error searching address",
                background: "variant-filled-error",
            });
        }
        queryActive = false;
    }

    function handleKeyDown(event: KeyboardEvent) {
        if (event.key === "Enter" && !queryActive) {
            geocodeSearch();
        }
    }

    const toastStore = getToastStore();
    $: console.log(selectedLocationObjectExists);
    $: console.log(addressPoint);
    $: console.log(addressString);
</script>

<div class="input-group input-group-divider grid-cols-[auto_1fr_auto]">
    <div class="input-group-shim">
        {#if selectedLocationObjectExists}
            <i class="fa-solid fa-check"></i>
        {:else}
            <i class="fa-solid fa-earth-americas"></i>
        {/if}
    </div>
    <input
        class="input autocomplete rounded-none"
        type="search"
        name="autocomplete-search"
        bind:value={query}
        placeholder="Search for an address..."
        use:popup={popupSettings}
        on:keydown={handleKeyDown}
    />
    {#if !queryActive}
        <button on:click={geocodeSearch} class="variant-filled-secondary"
            >Search</button
        >
    {:else}
        <button disabled class="variant-filled-secondary">
            <i class="fa-solid fa-spinner fa-spin"></i>
        </button>
    {/if}
</div>
<div data-popup="popupAutocomplete{n}" bind:this={popupWindow}>
    <Autocomplete
        emptyState=""
        bind:input={query}
        options={locationOptions}
        on:selection={onSelect}
        class="card max-w-l overflow-y-scroll overflow-x-scroll max-w-[600px] max-h-[400px]"
    />
</div>
