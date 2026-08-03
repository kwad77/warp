// SPEC §20 — the thin web renderer's first job: a self-contained HTML page (inline
// <style>, no external assets/CDN, no templating-engine dependency) for an unlisted
// postcard link. Pure: no I/O, takes already-fetched data and options in, returns a
// string.
import type { PostcardRenderView } from './service.js';

function escapeHtml(s: string): string {
  return s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    timeZone: 'UTC',
  });
}

const PAGE_STYLE = `
  body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
         background: #1b1f23; color: #f4f4f4; display: flex; justify-content: center; }
  .card { max-width: 480px; width: 100%; padding: 24px; box-sizing: border-box; }
  .photo { width: 100%; border-radius: 12px; display: block; background: #2a2f34;
           aspect-ratio: 4 / 3; object-fit: cover; }
  .placeholder { width: 100%; aspect-ratio: 4 / 3; border-radius: 12px; background: #2a2f34;
                 display: flex; align-items: center; justify-content: center; color: #888; }
  .verified { display: inline-flex; align-items: center; gap: 4px; color: #4caf50;
              font-size: 14px; margin-top: 12px; }
  h1 { font-size: 22px; margin: 8px 0 4px; }
  .meta { color: #aaa; font-size: 14px; }
  .message { margin-top: 16px; padding: 16px; background: #2a2f34; border-radius: 8px;
             font-size: 16px; line-height: 1.4; }
  .credit { margin-top: 12px; font-size: 13px; color: #888; }
  .install { margin-top: 24px; text-align: center; }
  .install a { display: inline-block; padding: 12px 24px; background: #4caf50; color: #fff;
               text-decoration: none; border-radius: 8px; font-weight: 600; }
`;

export function renderPostcardHtml(
  view: PostcardRenderView,
  opts: {
    publicBaseUrl: string;
    appStoreUrl?: string | undefined;
    playStoreUrl?: string | undefined;
  },
): string {
  const photo = view.photoUrlCard
    ? `<img class="photo" src="${escapeHtml(opts.publicBaseUrl + view.photoUrlCard)}" alt="${escapeHtml(view.poiTitle)}">`
    : `<div class="placeholder">📍</div>`;
  const credit =
    view.photographerHandle && view.photographerHandle !== view.senderHandle
      ? `<p class="credit">Photo by ${escapeHtml(view.photographerHandle)}</p>`
      : '';
  const message = view.message ? `<div class="message">${escapeHtml(view.message)}</div>` : '';
  const storeUrl = opts.appStoreUrl ?? opts.playStoreUrl;
  const install = storeUrl
    ? `<div class="install"><a href="${escapeHtml(storeUrl)}">Get Wanderpost</a></div>`
    : '';

  return `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(view.poiTitle)} — a postcard from ${escapeHtml(view.senderHandle)}</title>
<style>${PAGE_STYLE}</style>
</head>
<body>
<div class="card">
  ${photo}
  <h1>${escapeHtml(view.poiTitle)}</h1>
  <p class="meta">${escapeHtml(formatDate(view.verifiedAt))} · sent by ${escapeHtml(view.senderHandle)}</p>
  <div class="verified">✓ Verified in person</div>
  ${credit}
  ${message}
  ${install}
</div>
</body>
</html>`;
}

export function renderPostcardNotFoundHtml(): string {
  return `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Postcard not found</title>
<style>${PAGE_STYLE}</style>
</head>
<body>
<div class="card">
  <h1>This postcard isn't available</h1>
  <p class="meta">It may have been revoked, or the link is incorrect.</p>
</div>
</body>
</html>`;
}
