import { ApiError } from "./errorHandler.ts";

const supabaseUrlRaw = Deno.env.get("SUPABASE_URL")?.replace(/\/+$/, "");
const serviceRoleKeyRaw = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!supabaseUrlRaw || !serviceRoleKeyRaw) {
  throw new Error(
    "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be configured for REST access",
  );
}

const supabaseUrl = supabaseUrlRaw;
const serviceRoleKey = serviceRoleKeyRaw;
const restBase = `${supabaseUrl}/rest/v1`;

type QueryValue = string | number | boolean | Array<string | number | boolean>;
export type QueryParams = Record<string, QueryValue | undefined>;

interface RequestOptions {
  method?: "GET" | "POST" | "PATCH" | "DELETE";
  params?: QueryParams;
  body?: unknown;
  headers?: Record<string, string>;
}

function buildQuery(params?: QueryParams): string {
  if (!params) {
    return "";
  }
  const tokens: string[] = [];
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined) {
      continue;
    }
    const values = Array.isArray(value) ? value : [value];
    for (const item of values) {
      tokens.push(
        `${encodeURIComponent(key)}=${encodeURIComponent(String(item))}`,
      );
    }
  }
  return tokens.join("&");
}

async function request<T>(
  table: string,
  options: RequestOptions = {},
): Promise<T> {
  const query = buildQuery(options.params);
  const url = `${restBase}/${table}${query ? `?${query}` : ""}`;
  const headers = new Headers({
    apikey: serviceRoleKey,
    Authorization: `Bearer ${serviceRoleKey}`,
    "Content-Type": "application/json",
    ...(options.headers ?? {}),
  });

  const response = await fetch(url, {
    method: options.method ?? "GET",
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  if (!response.ok) {
    const text = await response.text();
    throw new ApiError(
      text || `Supabase request failed with status ${response.status}`,
      response.status,
    );
  }

  const text = await response.text();
  if (!text) {
    return [] as unknown as T;
  }

  try {
    return JSON.parse(text) as T;
  } catch (error) {
    throw new ApiError("Failed to parse Supabase response", 500);
  }
}

export async function selectRecords<T>(
  table: string,
  params?: QueryParams,
): Promise<T[]> {
  return await request<T[]>(table, {
    method: "GET",
    params: { select: "*", ...params },
  });
}

export async function selectSingleRecord<T>(
  table: string,
  params?: QueryParams,
): Promise<T | null> {
  const records = await selectRecords<T>(table, params);
  return records[0] ?? null;
}

export async function insertRecords<T>(
  table: string,
  payload: Record<string, unknown> | Record<string, unknown>[],
): Promise<T[]> {
  return await request<T[]>(table, {
    method: "POST",
    params: { select: "*" },
    headers: { Prefer: "return=representation" },
    body: payload,
  });
}

export async function updateRecords<T>(
  table: string,
  payload: Record<string, unknown>,
  params?: QueryParams,
): Promise<T[]> {
  return await request<T[]>(table, {
    method: "PATCH",
    params,
    headers: { Prefer: "return=representation" },
    body: payload,
  });
}
