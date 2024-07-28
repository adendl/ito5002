<script>
    export let targetDate;

    let displayDates = [];
    function buildDisplayDates() {
        displayDates = Array.from({ length: 7 }, (_, i) => {
            let date = new Date(targetDate);
            date.setDate(date.getDate() + i - date.getDay());
            let formattedDate = `${date.getDate()} ${date.toLocaleString("default", { month: "short" })}`;
            return formattedDate;
        });
        displayDates = displayDates;
    }
    $: buildDisplayDates();

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
</script>

<div class="card p-4 w-full">
    <div class="flex w-full justify-end items-end mb-2 mr-8">
        <input
            class="input w-min mr-14 text-right"
            type="date"
            placeholder=""
            tabindex="-1"
            value={targetDate}
        />
    </div>
    <div class="grid grid-cols-[auto_1fr_auto] gap-4 items-center">
        <button type="button" class="btn-icon variant-filled">
            <i class="fa-solid fa-arrow-left" />
        </button>

        <div class="table-container">
            <table class="table table-hover">
                <thead>
                    <tr class="text-center">
                        <th></th>
                        {#each days as day, i}
                            <th
                                class="text-center {targetDate.split('-')[2] ===
                                displayDates[i].split(' ')[0].padStart(2, 0)
                                    ? 'variant-ghost-primary'
                                    : ''}"
                                style="width: calc(100% / 7)"
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
                                <td class="m-0 p-0">
                                    <span
                                        class="chip m-0 w-full h-full variant-ghost-warning"
                                        >{start} - {end}</span
                                    >
                                </td>
                            {/each}
                        </tr>
                    {/each}
                </tbody>
            </table>
        </div>
        <button type="button" class="btn-icon variant-filled">
            <i class="fa-solid fa-arrow-right" />
        </button>
    </div>
</div>
