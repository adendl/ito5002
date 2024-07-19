<script>
    import { dummyMessages } from "../lib/dummyData/dummyMessages.js";
</script>

{#each dummyMessages as message}
    <div class="card p-4 m-4">
        <p class="mt-4">{message.subject} {message.message}</p>
    </div>
{/each}
