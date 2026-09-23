// supabase/functions/places-proxy/index.ts
// Deploy: supabase functions deploy places-proxy --no-verify-jwt
// Secret: supabase secrets set GOOGLE_PLACES_KEY=your_key_here
// @ts-nocheck

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const GOOGLE_KEY = Deno.env.get("GOOGLE_PLACES_KEY")!;
const BASE = "https://places.googleapis.com/v1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { action, ...params } = await req.json();

    let url = "";
    let fieldMask = "";
    let body: Record<string, unknown> = {};
    let method = "POST";

    if (action === "search") {
      url = `${BASE}/places:searchText`;
      fieldMask = "places.location,places.formattedAddress";
      body = { textQuery: params.query, regionCode: "PH" };
    } else if (action === "autocomplete") {
      url = `${BASE}/places:autocomplete`;
      body = {
        input: params.input,
        locationBias: {
          circle: {
            center: { latitude: 12.8797, longitude: 121.7740 },
            radius: 50000.0,
          },
        },
        includedRegionCodes: ["ph"],
      };
    } else if (action === "details") {
      url = `${BASE}/places/${params.placeId}`;
      fieldMask = "location,displayName,formattedAddress";
      method = "GET";
    } else {
      return new Response(JSON.stringify({ error: "Unknown action" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": GOOGLE_KEY,
    };
    if (fieldMask) headers["X-Goog-FieldMask"] = fieldMask;

    const googleRes = await fetch(url, {
      method,
      headers,
      body: method === "POST" ? JSON.stringify(body) : undefined,
    });

    const data = await googleRes.json();

    return new Response(JSON.stringify(data), {
      status: googleRes.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});