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
    $: targetDate, buildDisplayDates();
    function incrementOrDecrementDate(increment) {
        console.log("incrementing");
        let date = new Date(targetDate);
        date.setDate(date.getDate() + increment);
        targetDate = date.toISOString().split("T")[0];
        console.log(targetDate);
    }

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

    function clickHandler(i, j) {
        selections[i][j] = !selections[i][j];
        selections = selections;
    }
</script>

<div>
    <div class="card p-4 grid grid-cols-[auto_1fr_auto] gap-4 items-center">
        <button
            type="button"
            class="btn-icon variant-filled"
            on:click={() => {
                incrementOrDecrementDate(-7);
            }}
        >
            <i class="fa-solid fa-arrow-left" />
        </button>

        <div class="table-container">
            <table class="table table-hover">
                <thead>
                    <tr class="text-center">
                        <th></th>
                        {#each days as day, i}
                            <th
                                class="text-center"
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
                                <td
                                    class="m-0 p-0"
                                    on:click={() => {
                                        clickHandler(j, i);
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
        <button
            type="button"
            class="btn-icon variant-filled"
            on:click={() => {
                incrementOrDecrementDate(7);
            }}
        >
            <i class="fa-solid fa-arrow-right" />
        </button>
    </div>
</div>
