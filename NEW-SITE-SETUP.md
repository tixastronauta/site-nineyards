# New Webflow Site Setup Instructions

Instructions for a new Claude Code agent to build a deployment pipeline for a Webflow-exported site, mirroring the structure of this project. Assumes the exported Webflow files are already placed under `src/`.

## What you need to know up front

Ask the user (or read from context) for these values before starting:

| Variable | Example |
|---|---|
| `WORKER_NAME` | `my-site-worker` |
| `CANONICAL_HOST` | `mysite.com` (no `www`) |
| `SITE_URL` | `https://mysite.com` |
| `TITLE` | SEO page title |
| `DESCRIPTION` | Meta description |
| `KEYWORDS` | Comma-separated keywords |
| `AUTHOR` | Site author name |
| `OG_IMAGE` | Full URL to OG image |
| `OG_LOCALE` | e.g. `pt_PT` or `en_US` |
| `OG_SITE_NAME` | Site name for OG |
| `GTM_ID` | Google Tag Manager container ID (e.g. `GTM-XXXXXXX`) |
| `FORM_ACTION` | Mailer endpoint URL |
| `FORM_RECIPIENT` | Email address for form submissions |
| `FORM_SUCCESS_MSG` | Success feedback message (in site's language) |
| `FORM_ERROR_MSG` | Error feedback message (in site's language) |
| `CONTACT_FORM_ID` | The `id` attribute of the `<form>` element — inspect `src/` to find it |

---

## Files to create

### `package.json`

```json
{
  "name": "WORKER_NAME",
  "private": true,
  "scripts": {
    "build": "bash build.sh",
    "deploy": "bash deploy.sh",
    "preview": "wrangler dev"
  },
  "devDependencies": {
    "wrangler": "^4.86.0"
  }
}
```

### `wrangler.toml`

```toml
name = "WORKER_NAME"
compatibility_date = "2026-04-28"
main = "worker.js"

[assets]
directory = "./dist"

[[routes]]
pattern = "CANONICAL_HOST"
custom_domain = true

[[routes]]
pattern = "www.CANONICAL_HOST"
custom_domain = true
```

### `worker.js`

```js
export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    const canonicalProtocol = "https:";
    const canonicalHost = "CANONICAL_HOST";

    if (url.protocol !== canonicalProtocol || url.hostname === "www.CANONICAL_HOST") {
      url.protocol = canonicalProtocol;
      url.hostname = canonicalHost;
      return Response.redirect(url.toString(), 301);
    }

    return env.ASSETS.fetch(request);
  },
};
```

### `site.env`

```
SITE_URL="SITE_URL"
TITLE="TITLE"
DESCRIPTION="DESCRIPTION"
KEYWORDS="KEYWORDS"
AUTHOR="AUTHOR"
ROBOTS="index,follow"
OG_LOCALE="OG_LOCALE"
OG_SITE_NAME="OG_SITE_NAME"
OG_IMAGE="OG_IMAGE"
TWITTER_CARD="summary_large_image"
GTM_ID="GTM_ID"
FORM_ACTION="FORM_ACTION"
FORM_RECIPIENT="FORM_RECIPIENT"
FORM_SUCCESS_MSG="FORM_SUCCESS_MSG"
FORM_ERROR_MSG="FORM_ERROR_MSG"
```

### `deploy.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$ROOT_DIR/build.sh"

echo
echo "Deploying to Cloudflare Workers..."
npx wrangler deploy
```

### `static/css/custom.css`

Create this file and leave it empty for now. Add CSS overrides here as needed.

### `static/js/form-status.js`

Copy verbatim — `build.sh` replaces the `__FORM_SUCCESS_MSG__` and `__FORM_ERROR_MSG__` placeholders at build time.

```js
(function () {
  var SUCCESS_MSG = '__FORM_SUCCESS_MSG__';
  var ERROR_MSG = '__FORM_ERROR_MSG__';

  var params = new URLSearchParams(window.location.search);
  var status = params.get('form-status');

  if (status !== 'success' && status !== 'error') return;

  var cleanUrl = new URL(window.location.href);
  cleanUrl.searchParams.delete('form-status');
  history.replaceState(null, '', cleanUrl.toString());

  var isSuccess = status === 'success';
  var accentColor = isSuccess ? '#22c55e' : '#ff4d4d';
  var title = isSuccess ? 'Pedido enviado!' : 'Algo correu mal';
  var msg = isSuccess ? SUCCESS_MSG : ERROR_MSG;

  var overlay = document.createElement('div');
  overlay.style.cssText = [
    'position:fixed','inset:0','z-index:99999','display:flex',
    'align-items:center','justify-content:center','background:rgba(0,0,0,0.72)',
    'backdrop-filter:blur(4px)','-webkit-backdrop-filter:blur(4px)',
    'font-family:sans-serif','padding:24px','box-sizing:border-box',
  ].join(';');

  var card = document.createElement('div');
  card.style.cssText = [
    'position:relative','background:#0d0d0d','border:1px solid #272727',
    'border-radius:16px','max-width:480px','width:100%','padding:40px 36px',
    'text-align:center','box-shadow:0 24px 64px rgba(0,0,0,0.6)','box-sizing:border-box',
  ].join(';');

  var closeBtn = document.createElement('button');
  closeBtn.innerHTML = '&times;';
  closeBtn.style.cssText = [
    'position:absolute','top:16px','right:16px','background:none','border:none',
    'color:#666','font-size:24px','line-height:1','cursor:pointer','padding:4px 8px',
  ].join(';');

  var icon = document.createElement('div');
  icon.style.cssText = [
    'width:64px','height:64px','border-radius:50%','border:2px solid ' + accentColor,
    'display:flex','align-items:center','justify-content:center','margin:0 auto 24px',
    'font-size:28px','color:' + accentColor,
  ].join(';');
  icon.textContent = isSuccess ? '✓' : '✕';

  var titleEl = document.createElement('h3');
  titleEl.textContent = title;
  titleEl.style.cssText = ['color:#fff','font-size:22px','font-weight:700','margin:0 0 12px'].join(';');

  var msgEl = document.createElement('p');
  msgEl.textContent = msg;
  msgEl.style.cssText = ['color:#bbb','font-size:15px','line-height:1.6','margin:0 0 28px'].join(';');

  var ctaBtn = document.createElement('button');
  ctaBtn.textContent = 'Fechar';
  ctaBtn.style.cssText = [
    'background:' + accentColor,'color:' + (isSuccess ? '#0d0d0d' : '#fff'),
    'border:none','border-radius:8px','font-size:15px','font-weight:600',
    'padding:12px 32px','cursor:pointer','width:100%',
  ].join(';');

  function close() { overlay.remove(); }
  closeBtn.addEventListener('click', close);
  ctaBtn.addEventListener('click', close);
  overlay.addEventListener('click', function (e) { if (e.target === overlay) close(); });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') close(); });

  card.appendChild(closeBtn);
  card.appendChild(icon);
  card.appendChild(titleEl);
  card.appendChild(msgEl);
  card.appendChild(ctaBtn);
  overlay.appendChild(card);

  function mount() { document.body.appendChild(overlay); }
  if (document.body) { mount(); } else { document.addEventListener('DOMContentLoaded', mount); }
})();
```

### `build.sh`

Replace every `CONTACT_FORM_ID` with the actual form `id` found in `src/`. Adapt the "Removing unnecessary pages" step by inspecting `src/` for pages that should not ship (template pages, checkout, confirmation pages, etc.).

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
META_FILE="$ROOT_DIR/site.env"
INDEX_FILE="$ROOT_DIR/dist/index.html"

if [[ -t 1 ]]; then
  C_RESET="$(tput sgr0)"; C_BOLD="$(tput bold)"; C_BLUE="$(tput setaf 4)"
  C_GREEN="$(tput setaf 2)"; C_YELLOW="$(tput setaf 3)"; C_RED="$(tput setaf 1)"
else
  C_RESET=""; C_BOLD=""; C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""
fi

step=0
log_header() { echo; echo "${C_BOLD}${C_BLUE}========================================${C_RESET}"; echo "${C_BOLD}${C_BLUE} Build Pipeline${C_RESET}"; echo "${C_BOLD}${C_BLUE}========================================${C_RESET}"; }
log_step()   { step=$((step+1)); echo "${C_BOLD}${C_BLUE}[STEP ${step}]${C_RESET} $1"; }
log_ok()     { echo "${C_GREEN}[OK]${C_RESET} $1"; }
log_info()   { echo "${C_YELLOW}[INFO]${C_RESET} $1"; }
log_error()  { echo "${C_RED}[ERROR]${C_RESET} $1" >&2; }

[[ -f "$META_FILE" ]] || { log_error "Missing metadata file: $META_FILE"; exit 1; }

log_header
log_info "Project root: $ROOT_DIR"

log_step "Loading metadata configuration"
set -a; source "$META_FILE"; set +a
log_ok "Loaded metadata from $META_FILE"

log_step "Preparing dist directory"
rm -rf "$ROOT_DIR/dist"
cp -R "$ROOT_DIR/src" "$ROOT_DIR/dist"
log_ok "Copied src to dist"

log_step "Copying static overrides into dist"
if [[ -d "$ROOT_DIR/static" ]]; then
  cp -R "$ROOT_DIR/static/." "$ROOT_DIR/dist/"
  log_ok "Copied static/ into dist/"
else
  log_info "No static/ directory found, skipping"
fi

log_step "Injecting custom stylesheet into HTML pages"
while IFS= read -r -d '' html_file; do
  perl -0777 -i -pe 's|\n[ \t]*<link href="/css/custom.css" rel="stylesheet" type="text/css">||g' "$html_file"
  if ! rg -q 'href="css/custom.css"' "$html_file"; then
    perl -0777 -i -pe 's|</head>|  <link href="css/custom.css" rel="stylesheet" type="text/css">\n</head>|s' "$html_file"
  fi
done < <(find "$ROOT_DIR/dist" -type f -name "*.html" -print0)
log_ok "Ensured css/custom.css is linked in dist HTML"

log_step "Removing unnecessary pages from dist"
# Inspect src/ and add rm -f lines for pages that should not ship.
rm -f "$ROOT_DIR"/dist/component*.html
rm -rf "$ROOT_DIR"/dist/template-pages/
log_ok "Removed template-only pages"

log_step "Injecting SEO metadata into dist/index.html"
perl -0777 -i -pe '
  s|<title>.*?</title>|<title>$ENV{TITLE}</title>|s;
  s|<meta\s+content="[^"]*"\s+name="description">|<meta content="$ENV{DESCRIPTION}" name="description">|s;
  s|<meta\s+content="[^"]*"\s+property="og:title">|<meta content="$ENV{TITLE}" property="og:title">|s;
  s|<meta\s+content="[^"]*"\s+property="og:description">|<meta content="$ENV{DESCRIPTION}" property="og:description">|s;
  s|<meta\s+content="[^"]*"\s+property="og:image">|<meta content="$ENV{OG_IMAGE}" property="og:image">|s;
  s|<meta\s+content="[^"]*"\s+property="twitter:title">|<meta content="$ENV{TITLE}" property="twitter:title">|s;
  s|<meta\s+content="[^"]*"\s+property="twitter:description">|<meta content="$ENV{DESCRIPTION}" property="twitter:description">|s;
  s|<meta\s+content="[^"]*"\s+property="twitter:image">|<meta content="$ENV{OG_IMAGE}" property="twitter:image">|s;
  s|<meta\s+content="[^"]*"\s+name="twitter:card">|<meta content="$ENV{TWITTER_CARD}" name="twitter:card">|s;

  my $extra = "\n"
    . "  <meta content=\"$ENV{KEYWORDS}\" name=\"keywords\">\n"
    . "  <meta content=\"$ENV{AUTHOR}\" name=\"author\">\n"
    . "  <meta content=\"$ENV{ROBOTS}\" name=\"robots\">\n"
    . "  <link href=\"$ENV{SITE_URL}/\" rel=\"canonical\">\n"
    . "  <meta content=\"$ENV{OG_LOCALE}\" property=\"og:locale\">\n"
    . "  <meta content=\"$ENV{OG_SITE_NAME}\" property=\"og:site_name\">\n"
    . "  <meta content=\"$ENV{SITE_URL}/\" property=\"og:url\">\n";

  s|(<meta\s+content="[^"]*"\s+name="twitter:card">\s*)|$1$extra|s;
' "$INDEX_FILE"
log_ok "Metadata replaced from environment values"

log_step "Webflow comments removal"
perl -0777 -i -pe '
  s|<!--\s*This site was created in Webflow\.[\s\S]*?-->||g;
  s|<!--\s*Last Published:[\s\S]*?-->||g;
' "$INDEX_FILE"
log_ok "Removed Webflow-generated HTML comments"

log_step "Webflow generator meta removal"
perl -0777 -i -pe 's|\n[ \t]*<meta\s+content="Webflow"\s+name="generator">||g' "$INDEX_FILE"
log_ok "Removed Webflow generator meta tag"

log_step "Setting contact form action and method"
# Add any other HTML files that contain the contact form to this list.
for f in "$INDEX_FILE"; do
  [[ -f "$f" ]] || continue
  perl -0777 -i -pe '
    s|(<form id="CONTACT_FORM_ID"[^>]*?) method="get"|$1 method="post"|s;
    s|(<form id="CONTACT_FORM_ID"[^>]*)>|$1 action="$ENV{FORM_ACTION}">|s;
  ' "$f"
done
log_ok "Form action set to $FORM_ACTION (method: post)"

log_step "Injecting honeypot field into contact form"
HONEYPOT='<div style="position:absolute;left:-9999px;top:-9999px;" aria-hidden="true"><input type="text" name="website_url" id="website_url" tabindex="-1" autocomplete="off" value=""></div>'
for f in "$INDEX_FILE"; do
  [[ -f "$f" ]] || continue
  perl -0777 -i -pe "s|(<form id=\"CONTACT_FORM_ID\"[^>]*>)|\$1\n                  ${HONEYPOT}|s;" "$f"
done
log_ok "Honeypot field injected (name: website_url)"

log_step "Injecting _template hidden field into contact form"
TEMPLATE_FIELD='<input type="hidden" name="_template" value="WORKER_NAME_new_lead">'
for f in "$INDEX_FILE"; do
  [[ -f "$f" ]] || continue
  perl -0777 -i -pe "s|(<form id=\"CONTACT_FORM_ID\"[^>]*>)|\$1\n                  ${TEMPLATE_FIELD}|s;" "$f"
done
log_ok "_template hidden field injected"

log_step "Injecting _recipient hidden field into contact form"
for f in "$INDEX_FILE"; do
  [[ -f "$f" ]] || continue
  perl -0777 -i -pe '
    my $field = "<input type=\"hidden\" name=\"_recipient\" value=\"$ENV{FORM_RECIPIENT}\">";
    s|(<form id="CONTACT_FORM_ID"[^>]*>)|$1\n                  $field|s;
  ' "$f"
done
log_ok "_recipient hidden field injected (value: $FORM_RECIPIENT)"

log_step "Injecting Google Tag Manager"
perl -0777 -i -pe '
  my $head_snippet = "<!-- Google Tag Manager -->\n"
    . "<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({\x27gtm.start\x27:\n"
    . "new Date().getTime(),event:\x27gtm.js\x27});var f=d.getElementsByTagName(s)[0],\n"
    . "j=d.createElement(s),dl=l!=\x27dataLayer\x27?\x27&l=\x27+l:\x27\x27;j.async=true;j.src=\n"
    . "\x27https://www.googletagmanager.com/gtm.js?id=\x27+i+dl;f.parentNode.insertBefore(j,f);\n"
    . "})(window,document,\x27script\x27,\x27dataLayer\x27,\x27$ENV{GTM_ID}\x27);</script>\n"
    . "<!-- End Google Tag Manager -->\n"
    . "  ";

  my $body_snippet = "<!-- Google Tag Manager (noscript) -->\n"
    . "<noscript><iframe src=\"https://www.googletagmanager.com/ns.html?id=$ENV{GTM_ID}\"\n"
    . "height=\"0\" width=\"0\" style=\"display:none;visibility:hidden\"></iframe></noscript>\n"
    . "<!-- End Google Tag Manager (noscript) -->\n";

  s|(<meta charset="utf-8">)|$1\n  $head_snippet|s;
  s|(<body[^>]*>\n)|$1$body_snippet|s;
' "$INDEX_FILE"
log_ok "Injected GTM head and body snippets (container: $GTM_ID)"

log_step "Removing .DS_Store files"
find "$ROOT_DIR/dist" -name ".DS_Store" -delete
log_ok "Removed .DS_Store files"

log_step "Substituting env vars in form-status.js"
perl -0777 -i -pe '
  s/__FORM_SUCCESS_MSG__/$ENV{FORM_SUCCESS_MSG}/g;
  s/__FORM_ERROR_MSG__/$ENV{FORM_ERROR_MSG}/g;
' "$ROOT_DIR/dist/js/form-status.js"
log_ok "form-status.js placeholders replaced"

log_step "Injecting form-status.js into HTML pages"
while IFS= read -r -d '' html_file; do
  rel_dir="$(dirname "$html_file")"
  if [[ "$rel_dir" == "$ROOT_DIR/dist" ]]; then
    script_src="js/form-status.js"
  else
    depth=$(python3 -c "import os; print(len(os.path.relpath('$rel_dir', '$ROOT_DIR/dist').split(os.sep)))")
    prefix=$(python3 -c "print('../' * ${depth})")
    script_src="${prefix}js/form-status.js"
  fi
  if ! grep -q "form-status.js" "$html_file"; then
    perl -0777 -i -pe "s|</body>|<script src=\"${script_src}\" type=\"text/javascript\"></script>\n</body>|s" "$html_file"
  fi
done < <(find "$ROOT_DIR/dist" -type f -name "*.html" -print0)
log_ok "form-status.js injected into all HTML pages"

log_step "Injecting build timestamp comment"
BUILD_TIMESTAMP="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
while IFS= read -r -d '' html_file; do
  perl -0777 -i -pe "s|^|<!-- Built: ${BUILD_TIMESTAMP} -->\n|s" "$html_file"
done < <(find "$ROOT_DIR/dist" -type f -name "*.html" -print0)
log_ok "Build timestamp injected ($BUILD_TIMESTAMP)"

log_step "Finalizing build"
log_ok "Build complete: $ROOT_DIR/dist"
echo "${C_BOLD}${C_GREEN}Done.${C_RESET} Output is ready in dist/."
```

---

## After creating all files

1. **Find the contact form id** — inspect `src/` HTML files for the `<form>` element and replace every `CONTACT_FORM_ID` occurrence in `build.sh`.
2. **Find all files with the contact form** — if the form appears in pages other than `index.html` (e.g. a dedicated contact page), add those paths to the `for f in` loops in the form injection steps of `build.sh`.
3. **Prune unnecessary pages** — inspect `src/` for pages that should not ship (template pages, checkout, order confirmation, 401, etc.) and add `rm -f` lines in the "Removing unnecessary pages" step of `build.sh`.
4. Run `npm install` to install wrangler.
5. Run `npm run build` and verify `dist/index.html` contains: GTM snippets, injected SEO tags, form fields (`_template`, `_recipient`, honeypot), and the `css/custom.css` link.
6. Run `npm run preview` to smoke-test the site locally before deploying.
