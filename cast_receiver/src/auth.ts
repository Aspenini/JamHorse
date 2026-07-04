export type RequestInfo = {
  headers?: Record<string, string>;
};

const allowedHeaders = new Set(["authorization", "accept"]);

export function sanitizedHeaders(value: unknown): Record<string, string> {
  if (value === null || typeof value !== "object") return {};
  const output: Record<string, string> = {};
  for (const [name, headerValue] of Object.entries(value)) {
    if (
      allowedHeaders.has(name.toLowerCase()) &&
      typeof headerValue === "string" &&
      !headerValue.includes("\r") &&
      !headerValue.includes("\n")
    ) {
      output[name] = headerValue;
    }
  }
  return output;
}

export function attachHeaders(
  request: RequestInfo,
  headers: Record<string, string>,
): void {
  request.headers = {...request.headers, ...headers};
}
