import {attachHeaders, sanitizedHeaders} from "./auth";

declare const cast: any;

const context = cast.framework.CastReceiverContext.getInstance();
const player = context.getPlayerManager();

player.setMediaPlaybackInfoHandler((loadRequest: any, playbackConfig: any) => {
  const headers = sanitizedHeaders(
    loadRequest?.media?.customData?.headers ??
      loadRequest?.customData?.headers,
  );
  const addAuthentication = (request: any) => attachHeaders(request, headers);
  playbackConfig.manifestRequestHandler = addAuthentication;
  playbackConfig.segmentRequestHandler = addAuthentication;
  playbackConfig.captionsRequestHandler = addAuthentication;
  return playbackConfig;
});

context.start({
  disableIdleTimeout: false,
  maxInactivity: 3600,
});
