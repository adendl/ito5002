<script>
    export let targetDate;
    export let availabilities;
    export let bookingRequests = [];

    // Cycle calendar display dates and populate table
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
        let date = new Date(targetDate);
        date.setDate(date.getDate() + increment);
        targetDate = date.toISOString().split("T")[0];
        selections = Array.from({ length: 7 }).map(() =>
            Array.from({ length: 6 }).map(() => false),
        );
        selections = [];
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
        { start: 0, end: 4 },
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

    // Convert selections into booking requests to export
    function convertSelectionsToBookings() {
        bookingRequests = [];
        for (let i = 0; i < 7; i++) {
            for (let j = 0; j < 6; j++) {
                if (selections[i][j] && availabilities[i][j].state) {
                    const selectedYear = new Date(targetDate).getFullYear(); // 2024
                    const month = displayDates[i].split(" ")[1]; // Jul
                    const date = displayDates[i].split(" ")[0]; // 21
                    let timeStart = hourBrackets[j].start; // 12
                    let timeEnd = hourBrackets[j].end; // 16
                    if (j >= 4) {
                        timeStart += 12;
                        timeEnd += 12;
                    }
                    timeStart = timeStart.toString().padStart(2, "0");
                    timeEnd = timeEnd.toString().padStart(2, "0");
                    const monthNumeric =
                        new Date(`${month} 1, ${selectedYear}`).getMonth() + 1;
                    const monthNumericPadded = monthNumeric
                        .toString()
                        .padStart(2, "0");

                    let formattedStartTime = `${selectedYear}-${monthNumericPadded}-${date}T${timeStart}:00:00+10`;
                    let formattedEndTime = `${selectedYear}-${monthNumericPadded}-${date}T${timeEnd}:00:00+10`;
                    bookingRequests.push({
                        //startTime: formattedStartTime,
                        //endTime: formattedEndTime,
                        availability_id:
                            availabilities[i][j].attributes.availability_id,
                    });
                }
            }
        }
    }

    $: selections, convertSelectionsToBookings();
</script>

{#if selections && availabilities}
    <div class="card p-4 w-full">
        <div class="flex w-full justify-end items-end mb-2 mr-8">
            <input
                class="input w-min mr-14 text-right"
                type="date"
                placeholder=""
                tabindex="-1"
                bind:value={targetDate}
            />
        </div>
        <div class="grid grid-cols-[auto_1fr_auto] gap-4 items-center">
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
                                    on:click={() => {
                                        for (let j = 0; j < 7; j++) {
                                            selections[i][j] =
                                                !selections[i][j];
                                        }
                                    }}
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
                                            class="chip m-0 w-full h-full variant-{availabilities[
                                                j
                                            ][i].state && selections[j][i]
                                                ? 'filled-success'
                                                : availabilities[j][i].state &&
                                                    !selections[j][i]
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
{/if}
