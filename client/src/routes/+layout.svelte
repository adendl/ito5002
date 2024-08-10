<script lang="ts">
    // Supabase
    export let data;
    let { supabase, session } = data;
    $: ({ supabase, session } = data);
    console.log("in layout:", supabase);
    console.log("in layout:", session);

    // Authenticating endpoints
    import { page } from "$app/stores";
    import { onMount } from "svelte";
    let loaded = false;
    onMount(() => {
        if ($page.url.pathname === "/login") {
            return;
        } else if ($page.url.pathname == "/about-us") {
            return;
        } else if (session == null || (session.user.role = !"authenticated")) {
            window.location.href = "/login";
        } else {
            loaded = true;
        }
    });
    const unauthRoutes = ["/login", "/about-us"];
    $: if (session === null && !unauthRoutes.includes($page.url.pathname)) {
        window.location.href = "/login";
    }

    // Loading spinner
    import { ConicGradient } from "@skeletonlabs/skeleton";
    import type { ConicStop } from "@skeletonlabs/skeleton";
    const conicStops: ConicStop[] = [
        { color: "transparent", start: 0, end: 25 },
        { color: "rgb(var(--color-primary-500))", start: 75, end: 100 },
    ];

    // Generic styles & shell
    import "../app.postcss";
    import { AppShell, AppBar } from "@skeletonlabs/skeleton";
    import MessageFeed from "$lib/MessageFeed.svelte";

    // Highlight JS
    import hljs from "highlight.js/lib/core";
    import "highlight.js/styles/github-dark.css";
    import { storeHighlightJs } from "@skeletonlabs/skeleton";
    import xml from "highlight.js/lib/languages/xml"; // for HTML
    import css from "highlight.js/lib/languages/css";
    import javascript from "highlight.js/lib/languages/javascript";
    import typescript from "highlight.js/lib/languages/typescript";

    hljs.registerLanguage("xml", xml); // for HTML
    hljs.registerLanguage("css", css);
    hljs.registerLanguage("javascript", javascript);
    hljs.registerLanguage("typescript", typescript);
    storeHighlightJs.set(hljs);

    // Floating UI for Popups
    import {
        computePosition,
        autoUpdate,
        flip,
        shift,
        offset,
        arrow,
    } from "@floating-ui/dom";
    import { storePopup } from "@skeletonlabs/skeleton";
    storePopup.set({ computePosition, autoUpdate, flip, shift, offset, arrow });

    // Font Awesome
    import "@fortawesome/fontawesome-free/css/fontawesome.css";
    import "@fortawesome/fontawesome-free/css/brands.css";
    import "@fortawesome/fontawesome-free/css/solid.css";
    import "@fortawesome/fontawesome-free/css/regular.css";

    // Modals, Toasts, and Dawers
    import { Modal } from "@skeletonlabs/skeleton";
    import { Toast } from "@skeletonlabs/skeleton";
    import { Drawer } from "@skeletonlabs/skeleton";
    import {
        initializeStores,
        getModalStore,
        getDrawerStore,
    } from "@skeletonlabs/skeleton";
    initializeStores();
    const modalStore = getModalStore();
    const drawerStore = getDrawerStore();
    import AddListingModal from "$lib/AddListingModal.svelte";
    import UserProfile from "$lib/UserProfile.svelte";
    const listingModalRef = { ref: AddListingModal };
    $: listingModal = {
        type: "component",
        component: listingModalRef,
        meta: { data },
    };

    function triggerModal(modalId) {
        console.log(modalId);
        modalStore.trigger(modalId);
    }

    function openNotifications() {
        drawerStore.open({
            id: "messages",
            bgDrawer: "bg-purple-900 text-white",
            bgBackdrop:
                "bg-gradient-to-tr from-indigo-500/50 via-purple-500/50 to-pink-500/50",
            width: "w-[280px] md:w-[480px]",
            padding: "p-4",
            rounded: "rounded-xl",
            position: "right",
        });
    }

    function openProfile() {
        drawerStore.open({
            id: "profile",
            bgDrawer: "bg-purple-900 text-white",
            bgBackdrop:
                "bg-gradient-to-tr from-indigo-500/50 via-purple-500/50 to-pink-500/50",
            width: "w-[280px] md:w-[480px]",
            padding: "p-4",
            rounded: "rounded-xl",
            position: "right",
        });
    }
</script>

<!-- App Shell -->
{#if $page.url.pathname === "/login"}
    <slot />
{:else if $page.url.pathname === "/about-us"}
    <slot />
{:else if !loaded}
    <div class="w-full h-full flex justify-center items-center text-center">
        <ConicGradient stops={conicStops} spin>Loading</ConicGradient>
    </div>
{:else}
    <Drawer>
        {#if $drawerStore.id === "messages"}
            <MessageFeed {data} />
        {:else if $drawerStore.id === "profile"}
            <UserProfile {data} />
        {/if}
    </Drawer>
    <Modal />
    <Toast zIndex="z-[1000]" />
    <AppShell>
        <svelte:fragment slot="header">
            <!-- App Bar -->
            <AppBar class="max-h-[8vh]">
                <svelte:fragment slot="lead">
                    <strong
                        class="text-xl uppercase"
                        on:click={() => {
                            window.location.href = "/";
                        }}
                        >Community<i class="fa-solid fa-bolt"></i>Power</strong
                    >
                </svelte:fragment>
                <svelte:fragment slot="trail">
                    <button
                        class="btn variant-ghost-surface"
                        on:click={openProfile}
                    >
                        <i class="fa-solid fa-user"></i>
                    </button>
                    <button
                        class="btn variant-ghost-surface"
                        on:click={openNotifications}
                    >
                        <i class="fa-solid fa-bell"></i>
                    </button>
                </svelte:fragment>
            </AppBar>
        </svelte:fragment>
        <div class="w-full p-4" style="height: 83vh;">
            <slot />
        </div>
        <svelte:fragment slot="footer">
            <AppBar class="bg-ghost-100-800-token p-0 space-y-0 max-h-[10vh]">
                <svelte:fragment slot="lead"></svelte:fragment>
                <svelte:fragment slot="headline">
                    <div
                        class="w-full flex items-center justify-center text-center"
                    >
                        <div class="flex justify-center max-w-[400px]"></div>
                        <div class="flex justify-center">
                            <button
                                class="btn btn-m variant-filled-primary rounded-full mx-3"
                                on:click={() => {
                                    window.location.href = "/about-us";
                                }}
                            >
                                <i class="fa-solid fa-info"></i>
                            </button>
                            <button
                                class="btn btn-m variant-filled-primary rounded-full mx-3"
                                on:click={() => {
                                    window.location.href = "/";
                                }}
                            >
                                <i class="fa-solid fa-house"></i>
                            </button>
                        </div>
                        <div class="flex justify-center">
                            <button
                                class="btn btn-xl variant-filled-primary rounded-full mx-3"
                                on:click={() => {
                                    triggerModal(listingModal);
                                }}
                            >
                                <i class="fa-solid fa-plus"></i>
                            </button>
                        </div>
                        <div class="flex justify-center">
                            <button
                                class="btn btn-m variant-filled-primary rounded-full mx-3"
                                on:click={() => {
                                    window.location.href = "/calendar";
                                }}
                            >
                                <i class="fa-solid fa-calendar"></i>
                            </button>
                            <button
                                class="btn btn-m variant-filled-primary rounded-full mx-3"
                                on:click={() => {
                                    window.location.href = "/search";
                                }}
                            >
                                <i class="fa-solid fa-search"></i>
                            </button>
                        </div>
                    </div>
                </svelte:fragment>
                <svelte:fragment slot="trail"></svelte:fragment>
            </AppBar>
        </svelte:fragment>
    </AppShell>
{/if}
