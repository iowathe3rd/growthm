import { serve } from "https://deno.land/std@0.214.0/http/server.ts";
import { errorHandler } from "../_shared/errorHandler.ts";
import {
  extractBearerToken,
  requireAuthenticatedUser,
} from "../_shared/auth.ts";
import { selectRecords, selectSingleRecord } from "../_shared/restClient.ts";
import { generateGrowthReport } from "../_shared/llmClient.ts";
import { getGrowthReport, GrowthReportDeps } from "./handler.ts";
import type { GrowthReportBody } from "../_shared/types.ts";

const deps: GrowthReportDeps = {
  selectSingleRecord,
  selectRecords,
  generateGrowthReport,
};

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(null, { status: 405, headers: { Allow: "POST" } });
    }

    const token = extractBearerToken(req);
    const user = await requireAuthenticatedUser(token);

    const body = (await req.json()) as GrowthReportBody;
    const report = await getGrowthReport(body, user, deps);

    return new Response(JSON.stringify(report), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return errorHandler(error);
  }
});
