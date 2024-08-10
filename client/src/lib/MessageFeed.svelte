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
            .from("messages")
            .select("*")
            .order("created_at", { ascending: false });

        if (error) {
            console.error("error", error);
            return;
        } else {
            messages = messageData;
        }
    }
</script>

{#if messages.length === 0}
    <div class="w-full h-full flex items-center justify-center">
        <p>No notifications to display</p>
    </div>
{:else}
    {#each messages as message}
        <div class="card p-4 m-4">
            <p class="mt-4">{message.subject} {message.message}</p>
        </div>
    {/each}
{/if}
