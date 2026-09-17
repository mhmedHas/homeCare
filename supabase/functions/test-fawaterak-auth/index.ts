import "@supabase/functions-js/edge-runtime.d.ts"

Deno.serve(async (_req: Request) => {
  try {
    const clientId = Deno.env.get("FAWATERAK_CLIENT_ID")
    const clientSecret = Deno.env.get("FAWATERAK_CLIENT_SECRET")

    if (!clientId || !clientSecret) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Fawaterak OAuth secrets are missing",
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      )
    }

    const response = await fetch(
      "https://app.fawaterk.com/oauth/token",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Accept": "application/json",
        },
        body: new URLSearchParams({
          grant_type: "client_credentials",
          client_id: clientId,
          client_secret: clientSecret,
        }),
      },
    )

    const data = await response.json()

    if (!response.ok) {
      return new Response(
        JSON.stringify({
          success: false,
          status: response.status,
          error: data,
        }),
        {
          status: response.status,
          headers: { "Content-Type": "application/json" },
        },
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        token_type: data.token_type,
        expires_in: data.expires_in,
        message: "OAuth authentication successful",
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : String(error),
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    )
  }
})
