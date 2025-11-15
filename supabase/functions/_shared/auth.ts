import { ApiError } from "./errorHandler.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL")?.replace(/\/+$/, "");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error(
    "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required for auth checks",
  );
}

const userEndpoint = `${supabaseUrl}/auth/v1/user`;

export function extractBearerToken(req: Request): string {
  const header = req.headers.get("Authorization");
  if (!header || !header.startsWith("Bearer ")) {
    throw new ApiError("Authorization token required", 401);
  }
  return header.replace("Bearer ", "").trim();
}

export async function requireAuthenticatedUser(token: string) {
  const response = await fetch(userEndpoint, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`,
      apikey: serviceRoleKey,
    },
  });

  if (!response.ok) {
    throw new ApiError("Invalid or expired session", 401);
  }

  const json = await response.json();
  return json.user ?? json;
}
