import "@supabase/functions-js/edge-runtime.d.ts"

Deno.serve(async (_req: Request) => {
  try {
    const apiKey = Deno.env.get("FAWATERAK_API_KEY")

    if (!apiKey) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "FAWATERAK_API_KEY is missing",
        }),
        {
          status: 500,
          headers: {
            "Content-Type": "application/json",
          },
        },
      )
    }

    const response = await fetch(
      "https://app.fawaterk.com/api/v2/getPaymentmethods",
      {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      },
    )

    const data = await response.json()

    return new Response(
      JSON.stringify({
        success: response.ok,
        status: response.status,
        data: data,
      }),
      {
        status: response.ok ? 200 : response.status,
        headers: {
          "Content-Type": "application/json",
        },
      },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error
          ? error.message
          : String(error),
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
        },
      },
    )
  }
})
