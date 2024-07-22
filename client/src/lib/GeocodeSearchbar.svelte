<script lang="ts">
    export let query: string = "";
    export let addressString: string = "";
    export let addressPoint: string = "";
    export let n: number;

    import { Autocomplete, popup, getToastStore } from "@skeletonlabs/skeleton";
    import type {
        PopupSettings,
        AutocompleteOption,
    } from "@skeletonlabs/skeleton";

    let queryActive: boolean = false;
    let selectedLocationObject = {};
    $: if (selectedLocationObject) {
        addressString = selectedLocationObject.display_name;
        addressPoint = `POINT(${selectedLocationObject.lon} ${selectedLocationObject.lat})`;
    }
    let selectedLocationObjectExists: boolean = false;
    $: selectedLocationObjectExists =
        Object.keys(selectedLocationObject).length > 0 || addressPoint !== "POINT(undefined undefined)";

    let popupSettings: PopupSettings = {
        event: "focus-click",
        target: `popupAutocomplete${n}`,
        placement: "bottom",
    };
    let popupWindow: HTMLElement;

    var locationOptions: AutocompleteOption<string>[] = [];

    function onSelect(event: CustomEvent<AutocompleteOption<string>>) {
        query = event.detail.value;
        selectedLocationObject = event.detail.data;
        selectedLocationObject = selectedLocationObject;
    }

    async function geocodeSearch() {
        queryActive = true;
        // TOS compliance, delaying requests by users
        await new Promise((resolve) => setTimeout(resolve, 500));
        const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query)}&layer=address&format=json`;
        try {
            const response = await fetch(url, {
                headers: {
                    "User-Agent": "CommunityPower", // TOS requires a user agent
                },
            });
            const candidates = await response.json();
            if (candidates.length === 0) {
                toastStore.trigger(errorToast);
                queryActive = false;
                return;
            }
            locationOptions = candidates.map((candidate) => {
                return {
                    value: candidate.display_name.replace(",", ""),
                    label: candidate.display_name.replace(",", ""),
                    keywords: query,
                    data: candidate,
                };
            });
            console.log(locationOptions);
            locationOptions = locationOptions;
            popupWindow.click();
        } catch (error) {
            console.error("Error:", error);
        }
        queryActive = false;
    }

    function handleKeyDown(event: KeyboardEvent) {
        if (event.key === "Enter" && !queryActive) {
            geocodeSearch();
        }
    }

    const toastStore = getToastStore();
    const errorToast = {
        message: "No results for address",
        background: "variant-filled-warning",
    };

    $:console.log(selectedLocationObjectExists);
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
