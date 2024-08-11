<script lang="ts">
    export let data;
    import { onMount } from "svelte";

    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    let messages = [];
    let loaded = false;
    import { ConicGradient } from "@skeletonlabs/skeleton";
    import type { ConicStop } from "@skeletonlabs/skeleton";
    const conicStops: ConicStop[] = [
        { color: "transparent", start: 0, end: 25 },
        { color: "rgb(var(--color-primary-500))", start: 75, end: 100 },
    ];

    onMount(async () => {
        await getMessages();
    });

    async function getMessages() {
        loaded = false;
        const { data: messageData, error } = await supabase
            .from("notifications")
            .select("*")
            .order("timestamp", { ascending: false })
            .eq("for_user_id", session.user.id)
            .limit(30);

        if (error) {
            console.error("error", error);
        } else {
            messages = messageData;
        }
        loaded = true;
    }

    function resolveMessage(messageText) {
        if (messageText === "booking_request") {
            return "You have a new request for your charger on ";
        } else if (messageText === "request_accepted") {
            return "Your request was accepted for a charger on ";
        } else if (messageText === "request_rejected") {
            return "Your request was rejected for a charger on ";
        } else if (messageText === "bookee_cancelled") {
            return "A user cancelled their booking for your charger on ";
        } else if (messageText === "listee_cancelled") {
            return "The listing owner cancelled your booking for a charger on ";
        } else {
            return "Error parsing message for event on ";
        }
    }

    function prettyDate(date) {
        // format should be 10 August 2021
        return new Date(date).toLocaleDateString("en-GB", {
            day: "numeric",
            month: "long",
            year: "numeric",
        });
    }

    function prettyTimestamp(timestamp) {
        // format should be 2021-08-10 12:00:00 in the user's timezone
        return new Date(timestamp).toLocaleString("en-GB", {
            day: "numeric",
            month: "long",
            year: "numeric",
            hour: "numeric",
            minute: "numeric",
            second: "numeric",
        });
    }

    function navigateToMessageDate(message) {
        let calendarType;
        if (["booking_request", "bookee_cancelled"].includes(message.message)) {
            calendarType = "listings";
        } else {
            calendarType = "bookings";
        }
        window.location.href = `/calendar/?calendarType=${calendarType}&date=${message.date}`;
    }
</script>

{#if !loaded}
    <div class="w-full h-full flex items-center justify-center">
        <ConicGradient stops={conicStops} size="100px" />
    </div>
{:else if messages.length === 0}
    <div class="w-full h-full flex items-center justify-center">
        <p>No notifications to display</p>
    </div>
{:else}
    {#each messages as message}
        <div
            class="card p-4 m-4 card-hover"
            on:click={() => navigateToMessageDate(message)}
        >
            <p class="text-sm text-gray-400">
                {prettyTimestamp(message.timestamp)}
            </p>
            <p>{resolveMessage(message.message)} {prettyDate(message.date)}.</p>
        </div>
    {/each}
{/if}
