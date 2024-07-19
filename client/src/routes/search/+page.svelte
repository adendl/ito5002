<script>
    import dummyMap2 from "$lib/dummyData/dummyMap2.png";
</script>

<label class="label flex mb-2">
    <input class="input" type="text" placeholder="Find charging" />
    <button type="button" class="btn m-2 variant-filled">
        <i class="fa-solid fa-filter"></i>
    </button>
    <button type="button" class="btn m-2 variant-filled">
        <i class="fa-solid fa-home"></i>
    </button>
    <button type="button" class="btn m-2 variant-filled">
        <i class="fa-solid fa-briefcase"></i>
    </button>
</label>

<div class="card p-4 h-full relative overflow-auto">
    <img src={dummyMap2} alt="Map" class="w-full h-full rounded-lg" />
    <div
        class="absolute top-0 left-0 flex justify-center items-center w-full h-full"
    >
        <div class="flex justify-center items-center">
            <button
                type="button"
                class="btn btn-icon variant-ghost"
                style="position: absolute; top: 30%; left: 20%;"
            >
                <i class="fa-solid fa-location-dot"></i>
            </button>
            <button
                type="button"
                class="btn btn-icon variant-ghost"
                style="position: absolute; top: 50%; left: 60%;"
            >
                <i class="fa-solid fa-location-dot"></i>
            </button>
            <button
                type="button"
                class="btn btn-icon variant-ghost"
                style="position: absolute; top: 70%; left: 40%;"
            >
                <i class="fa-solid fa-location-dot"></i>
            </button>
            <button
                type="button"
                class="btn btn-icon variant-ghost"
                style="position: absolute; top: 35%; left: 65%;"
            >
                <i class="fa-solid fa-location-dot"></i>
            </button>
        </div>
    </div>
</div>
