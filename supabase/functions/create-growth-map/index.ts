import { serve } from "https://deno.land/std@0.214.0/http/server.ts";
import { ApiError, errorHandler } from "../_shared/errorHandler.ts";
import {
  extractBearerToken,
  requireAuthenticatedUser,
} from "../_shared/auth.ts";
import { insertRecords } from "../_shared/restClient.ts";
import {
  generateSkillTreeDraft,
  planInitialSprint,
} from "../_shared/llmClient.ts";
import { createGrowthMap, CreateGrowthMapDeps } from "./handler.ts";
import type { CreateGrowthMapBody } from "../_shared/types.ts";

const deps: CreateGrowthMapDeps = {
  insertRecords,
  generateSkillTreeDraft,
  planInitialSprint,
};

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(null, { status: 405, headers: { Allow: "POST" } });
    }

    const token = extractBearerToken(req);
    const user = await requireAuthenticatedUser(token);

    const payload = (await req.json()) as CreateGrowthMapBody;
    const result = await createGrowthMap(payload, user, deps);

    return new Response(JSON.stringify(result), {
      status: 201,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return errorHandler(error);
  }
});
