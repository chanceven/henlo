import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  try {
    const authHeader = req.headers.get("Authorization");

    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header." }),
        {
          status: 401,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Client used only to identify the calling user
    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("ANON_KEY")!,
      {
        global: {
          headers: {
            Authorization: authHeader,
          },
        },
      },
    );

    const {
      data: { user },
      error: userError,
    } = await supabaseUser.auth.getUser();

    // Client used for all privileged/admin operations
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    console.log("userError:", userError);
    console.log("user:", user);

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "User not found." }),
        {
          status: 401,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const body = await req.json();

    const reason = body.reason ?? "";
    const otherReason = body.other_reason ?? "";

    // Check if user is a Furrent
    const { data: furrent } = await supabase
      .from("furrents")
      .select("id")
      .eq("id", user.id)
      .maybeSingle();

    // Check if user is a Pawtner
    const { data: pawtner } = await supabase
      .from("pawtners")
      .select("id")
      .eq("id", user.id)
      .maybeSingle();

    const userType = furrent ? "furrent" : pawtner ? "pawtner" : "unknown";

    // Save deletion feedback (wrapped so a failure here never blocks deletion)
    try {
      const { error: feedbackError } = await supabase
        .from("account_deletion_feedback")
        .insert({
          email: user.email,
          user_type: userType,
          reason,
          other_reason: otherReason,
          created_at: new Date().toISOString(),
        });

      if (feedbackError) {
        console.log("feedbackError:", feedbackError);
      }
    } catch (feedbackCatchError) {
      console.log("feedback insert threw:", feedbackCatchError);
    }

    if (furrent) {
      // Delete pets
      await supabase
        .from("pets")
        .delete()
        .eq("furrent_id", user.id);

      // Delete notifications
      await supabase
        .from("notifications")
        .delete()
        .eq("user_id", user.id);

      // Hide conversations AND clear the furrent_id reference
      // (clearing the reference is required so this user's row can
      // actually be deleted later without a foreign key blocking it,
      // while the conversation itself stays intact for the other side)
      await supabase
        .from("conversations")
        .update({
          hidden_for_furrent: true,
          furrent_cleared_at: new Date().toISOString(),
          furrent_id: null,
        })
        .eq("furrent_id", user.id);

      // Hide messages
      await supabase
        .from("messages")
        .update({
          deleted_for_furrent: true,
        })
        .or(`sender_id.eq.${user.id},receiver_id.eq.${user.id}`);

      // Delete Furrent profile
      await supabase
        .from("furrents")
        .delete()
        .eq("id", user.id);
    }

    if (pawtner) {
      // Delete gallery
      await supabase
        .from("gallery")
        .delete()
        .eq("pawtner_id", user.id);

      // Delete service availability
      await supabase
        .from("service_availability")
        .delete()
        .eq("pawtner_id", user.id);

      // Delete services
      await supabase
        .from("services")
        .delete()
        .eq("pawtner_id", user.id);

      // Delete notifications
      await supabase
        .from("notifications")
        .delete()
        .eq("user_id", user.id);

      // Hide conversations AND clear the pawtner_id reference
      // (same reasoning as above, for the pawtner side)
      await supabase
        .from("conversations")
        .update({
          hidden_for_pawtner: true,
          pawtner_cleared_at: new Date().toISOString(),
          pawtner_id: null,
        })
        .eq("pawtner_id", user.id);

      // Hide messages
      await supabase
        .from("messages")
        .update({
          deleted_for_pawtner: true,
        })
        .or(`sender_id.eq.${user.id},receiver_id.eq.${user.id}`);

      // Delete Pawtner profile
      await supabase
        .from("pawtners")
        .delete()
        .eq("id", user.id);
    }

    // Delete auth user
    const { error: deleteAuthError } =
      await supabase.auth.admin.deleteUser(user.id);

    if (deleteAuthError) {
      return new Response(
        JSON.stringify({
          error: deleteAuthError.message,
        }),
        {
          status: 500,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
        },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
        },
      },
    );
  }
});