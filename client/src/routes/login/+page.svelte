<script>
    export let data;

    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    console.log(supabase);
    console.log(session);

    function googleLogin() {
        console.log("googleLogin");
        supabase.auth.signInWithOAuth({
            provider: "google",
        });
        console.log("googleLogin end");
    }

    function signOut() {
        console.log("signOut");
        supabase.auth.signOut();
        console.log("signOut end");
    }
</script>

<div class="w-full h-full">
    <button class="btn variant-filled" on:click={googleLogin}>Sign in with Google</button>
    <button class="btn variant-filled" on:click={signOut}>Sign out</button>
</div>
