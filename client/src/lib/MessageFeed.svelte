<script>
    export let data;
    import { onMount } from "svelte";

    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    let messages = [];

    onMount(async () => {
        await getMessages();
    });

    async function getMessages() {
        const { data: messageData, error } = await supabase
            .from("notifications")
            .select("*")
            .order("timestamp", { ascending: false })
            .eq("for_user_id", session.user.id);

        if (error) {
            console.error("error", error);
            return;
        } else {
            messages = messageData;
        }
    }

    function resolveMessage(messageText) {
        if (messageText === "booking_request") {
            return "You have a new request for your charger on "
        } else {
            return 
        }
    }

    function prettyDate(date) {
        // format should be 10 August 2021
        return new Date(date).toLocaleDateString('en-GB', {
            day: 'numeric',
            month: 'long',
            year: 'numeric'
        });
    }

    function prettyTimestamp(timestamp) {
        // format should be 2021-08-10 12:00:00 in the user's timezone
        return new Date(timestamp).toLocaleString('en-GB', {
            day: 'numeric',
            month: 'long',
            year: 'numeric',
            hour: 'numeric',
            minute: 'numeric',
            second: 'numeric'
        });
    }

</script>

{#if messages.length === 0}
    <div class="w-full h-full flex items-center justify-center">
        <p>No notifications to display</p>
    </div>
{:else}
    {#each messages as message}
        <div class="card p-4 m-4 card-hover">
            <p class="text-sm text-gray-400">{prettyTimestamp(message.timestamp)}</p>
            <p>{resolveMessage(message.message)} {prettyDate(message.date)}.</p>
        </div>
    {/each}
{/if}
