import { serve } from "https://deno.land/std@0.214.0/http/server.ts";
import { errorHandler } from "../_shared/errorHandler.ts";
import {
  extractBearerToken,
  requireAuthenticatedUser,
} from "../_shared/auth.ts";
import { selectRecords, selectSingleRecord } from "../_shared/restClient.ts";
import { getGoalDetail, GetGoalDetailDeps } from "./handler.ts";

const deps: GetGoalDetailDeps = {
  selectSingleRecord,
  selectRecords,
};

serve(async (req) => {
  try {
    if (req.method !== "GET") {
      return new Response(null, { status: 405, headers: { Allow: "GET" } });
    }

    const token = extractBearerToken(req);
    const user = await requireAuthenticatedUser(token);

    const url = new URL(req.url);
    const goalId = url.searchParams.get("goal_id")?.trim();
    if (!goalId) {
      return new Response(JSON.stringify({ error: "goal_id is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const response = await getGoalDetail(goalId, user, deps);
    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return errorHandler(error);
  }
});
