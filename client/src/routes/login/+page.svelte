<script lang="ts">
    export let data;
    import { onMount } from "svelte";
    import { ConicGradient } from "@skeletonlabs/skeleton";
    import type { ConicStop } from "@skeletonlabs/skeleton";

    // Loading spinner
    let loaded = false;
    const conicStops: ConicStop[] = [
        { color: "transparent", start: 0, end: 25 },
        { color: "rgb(var(--color-primary-500))", start: 75, end: 100 },
    ];

    let { supabase, session } = data;
    $: ({ supabase, session } = data);
    console.log(supabase);
    console.log(session);

    onMount(() => {
        if (session == null) {
            loaded = true;
        } else {
            if (session.user.role === "authenticated") {
                window.location.href = "/";
            } else {
                loaded = true;
            }
        }
    });

    function googleLogin() {
        supabase.auth.signInWithOAuth({
            provider: "google",
        });
    }
</script>

<div class="w-full h-full flex justify-center items-center text-center">
    {#if loaded}
        <div>
            <div>
                <strong class="text-xl uppercase"
                    >Community<i class="fa-solid fa-bolt"></i>Power</strong
                >
            </div>
            <div class="m-2">
                <button class="btn variant-filled" on:click={googleLogin}
                    >Sign in with Google <i class="ml-2 fa-brands fa-google"
                    ></i></button
                >
            </div>
            <div class="mt-4">
                <a href="/about-us"><i class="hover:underline">About us</i></a>
            </div>
        </div>
    {:else}
        <ConicGradient stops={conicStops} spin>Loading</ConicGradient>
    {/if}
</div>
