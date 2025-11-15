import { serve } from "https://deno.land/std@0.214.0/http/server.ts";
import { errorHandler } from "../_shared/errorHandler.ts";
import {
  extractBearerToken,
  requireAuthenticatedUser,
} from "../_shared/auth.ts";
import {
  insertRecords,
  selectRecords,
  selectSingleRecord,
  updateRecords,
} from "../_shared/restClient.ts";
import {
  generateSkillTreeDraft,
  planAdaptiveSprint,
} from "../_shared/llmClient.ts";
import { regenerateSprint, RegenerateSprintDeps } from "./handler.ts";

const deps: RegenerateSprintDeps = {
  selectSingleRecord,
  selectRecords,
  insertRecords,
  updateRecords,
  planAdaptiveSprint,
  generateSkillTreeDraft,
};

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(null, { status: 405, headers: { Allow: "POST" } });
    }

    const token = extractBearerToken(req);
    const user = await requireAuthenticatedUser(token);

    const body = await req.json();
    const response = await regenerateSprint(body, user, deps);

    return new Response(JSON.stringify(response), {
      status: 201,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return errorHandler(error);
  }
});
