import { SupabaseClient, Session } from "@supabase/supabase-js";

// See https://kit.svelte.dev/docs/types#app
// for information about these interfaces
// and what to do when importing types
declare namespace App {
	// interface Locals {}
	 interface PageData {
        supabase: SupabaseClient
        session: Session | null
     }
	// interface Error {}
	// interface Platform {}
}


export {};