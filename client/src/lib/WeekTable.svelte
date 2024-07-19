<script>
    export let bookingMode = false;
    export let listingMode = false;
    export let displayDates = [];
    const days = [
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
    ];
    const hourBrackets = [
        { start: 12, end: 4 },
        { start: 4, end: 8 },
        { start: 8, end: 12 },
        { start: 12, end: 4 },
        { start: 4, end: 8 },
        { start: 8, end: 12 },
    ];

    let selections = Array.from({ length: 7 }).map(() =>
        Array.from({ length: 6 }).map(() => false),
    );

    function populateRandomArray(arrayName) {
        for (let i = 0; i < 7; i++) {
            for (let j = 0; j < 6; j++) {
                arrayName[i][j] = Math.random() > 0.5;
            }
        }
    }

    let availability = [];
    if (bookingMode || listingMode) {
        availability = Array.from({ length: 7 }).map(() =>
            Array.from({ length: 6 }).map(() => false),
        );
        populateRandomArray(availability);
    }

    let provisional = [];
    let accepted = [];
    if (listingMode) {
        provisional = Array.from({ length: 7 }).map(() =>
            Array.from({ length: 6 }).map(() => false),
        );
        populateRandomArray(provisional);
        accepted = Array.from({ length: 7 }).map(() =>
            Array.from({ length: 6 }).map(() => false),
        );
        populateRandomArray(accepted);
    }

    function clickHandler(i, j) {
        selections[i][j] = !selections[i][j];
        console.log("clicked");
        selections = selections;
        //trigger drawer
        
    }
</script>

{#if bookingMode}
    <div class="table-container">
        <table class="table table-hover">
            <thead>
                <tr class="text-center">
                    <th></th>
                    {#each days as day, i}
                        <th class="text-center" style="width: calc(100% / 7)"
                            >{day}{#if displayDates}<br />{displayDates[
                                    i
                                ]}{/if}</th
                        >
                    {/each}
                </tr>
            </thead>
            <tbody>
                {#each hourBrackets as { start, end }, i}
                    <tr class="text-center">
                        {#if i === 0}
                            <td rowspan="3">AM</td>
                        {:else if i === 3}
                            <td rowspan="3">PM</td>
                        {/if}
                        {#each Array.from({ length: 7 }) as _, j}
                            <td
                                class="m-0 p-0"
                                on:click={() => {
                                    selections[j][i] = !selections[j][i];
                                }}
                            >
                                <span
                                    class="chip m-0 w-full h-full variant-{availability[
                                        j
                                    ][i] && selections[j][i]
                                        ? 'filled-success'
                                        : availability[j][i]
                                          ? 'ghost-success'
                                          : 'ghost-error'}"
                                    >{start} - {end}</span
                                >
                            </td>
                        {/each}
                    </tr>
                {/each}
            </tbody>
        </table>
    </div>
{:else if listingMode}
    <div class="table-container">
        <table class="table table-hover">
            <thead>
                <tr class="text-center">
                    <th></th>
                    {#each days as day, i}
                        <th class="text-center" style="width: calc(100% / 7)"
                            >{day}{#if displayDates}<br />{displayDates[
                                    i
                                ]}{/if}</th
                        >
                    {/each}
                </tr>
            </thead>
            <tbody>
                {#each hourBrackets as { start, end }, i}
                    <tr class="text-center">
                        {#if i === 0}
                            <td rowspan="3">AM</td>
                        {:else if i === 3}
                            <td rowspan="3">PM</td>
                        {/if}
                        {#each Array.from({ length: 7 }) as _, j}
                            <td
                                class="m-0 p-0"
                                on:click={() => {
                                    clickHandler(j, i);
                                }}
                            >
                                <span
                                    class="chip m-0 w-full h-full variant-{accepted[
                                        j
                                    ][i]
                                        ? 'filled-success'
                                        : provisional[j][i]
                                          ? 'filled-warning'
                                          : 'ghost-error'}"
                                    >{start} - {end}</span
                                >
                            </td>
                        {/each}
                    </tr>
                {/each}
            </tbody>
        </table>
    </div>
{:else}
    <div class="table-container">
        <table class="table table-hover">
            <thead>
                <tr class="text-center">
                    <th></th>
                    {#each days as day, i}
                        <th class="text-center" style="width: calc(100% / 7)"
                            >{day}</th
                        >
                    {/each}
                </tr>
            </thead>
            <tbody>
                {#each hourBrackets as { start, end }, i}
                    <tr class="text-center">
                        {#if i === 0}
                            <td rowspan="3">AM</td>
                        {:else if i === 3}
                            <td rowspan="3">PM</td>
                        {/if}
                        {#each Array.from({ length: 7 }) as _, j}
                            <td
                                class="m-0 p-0"
                                on:click={() => {
                                    selections[j][i] = !selections[j][i];
                                }}
                            >
                                <span
                                    class="chip m-0 w-full h-full variant-{selections[
                                        j
                                    ][i]
                                        ? 'filled-success'
                                        : 'ghost'}">{start} - {end}</span
                                >
                            </td>
                        {/each}
                    </tr>
                {/each}
            </tbody>
        </table>
    </div>
{/if}
