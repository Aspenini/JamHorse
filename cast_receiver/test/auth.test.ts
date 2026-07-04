import {attachHeaders, sanitizedHeaders} from "../src/auth";
import {describe, expect, it} from "vitest";

describe("receiver authentication", () => {
  it("keeps only safe in-memory request headers", () => {
    expect(
      sanitizedHeaders({
        Authorization: 'MediaBrowser Token="secret"',
        Cookie: "must-not-pass",
        Accept: "application/json",
      }),
    ).toEqual({
      Authorization: 'MediaBrowser Token="secret"',
      Accept: "application/json",
    });
  });

  it("attaches authentication without changing the URL", () => {
    const request = {headers: {Range: "bytes=0-"}};
    attachHeaders(request, {Authorization: "secret"});
    expect(request).toEqual({
      headers: {Range: "bytes=0-", Authorization: "secret"},
    });
  });
});
