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

log_step "Downloading external JS vendor dependencies"
VENDOR_CACHE="$ROOT_DIR/static/js/vendor"
mkdir -p "$VENDOR_CACHE"
vendor_urls=()
vendor_files=()
while IFS= read -r url; do
  [[ -z "$url" ]] && continue
  filename="$(basename "${url%%\?*}")"
  vendor_urls+=("$url")
  vendor_files+=("$filename")
  if [[ ! -f "$VENDOR_CACHE/$filename" ]]; then
    log_info "Downloading $filename"
    curl -fsSL -o "$VENDOR_CACHE/$filename" "$url" \
      || { log_error "Failed to download: $url"; exit 1; }
  else
    log_info "Using cached $filename"
  fi
done < <(
  grep -rEoh 'src="https?://[^"]+\.js[^"]*"' "$ROOT_DIR/src" 2>/dev/null \
    | grep -oE 'https?://[^"]+' | sort -u
)
log_ok "Vendor cache ready (${#vendor_urls[@]} external scripts)"

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
rm -f "$ROOT_DIR"/dist/component*.html
rm -rf "$ROOT_DIR"/dist/template-pages/
rm -f "$ROOT_DIR/dist/401.html"
rm -f "$ROOT_DIR/dist/style-guide.html"
rm -f "$ROOT_DIR/dist/changelog.html"
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

log_step "Replacing external JS with local vendor copies"
if [[ ${#vendor_urls[@]} -gt 0 ]]; then
  while IFS= read -r -d '' html_file; do
    rel_dir="$(dirname "$html_file")"
    if [[ "$rel_dir" == "$ROOT_DIR/dist" ]]; then
      vendor_prefix="js/vendor"
    else
      depth=$(python3 -c "import os; print(len(os.path.relpath('$rel_dir', '$ROOT_DIR/dist').split(os.sep)))")
      vendor_prefix="$(python3 -c "print('../' * ${depth})")js/vendor"
    fi
    for i in "${!vendor_urls[@]}"; do
      ORIGINAL_URL="${vendor_urls[$i]}" LOCAL_PATH="${vendor_prefix}/${vendor_files[$i]}" \
      perl -0777 -i -pe '
        my $u = quotemeta($ENV{ORIGINAL_URL});
        my $p = $ENV{LOCAL_PATH};
        s|src="$u"|src="$p"|g;
      ' "$html_file"
    done
  done < <(find "$ROOT_DIR/dist" -type f -name "*.html" -print0)
fi
log_ok "External JS replaced with local vendor copies"

log_step "Normalising brand name to 'nineyards' (text content only)"
while IFS= read -r -d '' html_file; do
  perl -0777 -i -pe '
    s/(<[^>]*>)|Nine\s+Yards|NineYards|Nineyards|NINEYARDS/
      $1 ? $1 : "nineyards"
    /ge;
  ' "$html_file"
done < <(find "$ROOT_DIR/dist" -type f -name "*.html" -print0)
log_ok "Brand name normalised in text content across all HTML files"

log_step "Setting LinkedIn company URL in footer"
while IFS= read -r -d '' html_file; do
  LINKEDIN_URL="$LINKEDIN_URL" perl -0777 -i -pe \
    's|href="https://www\.linkedin\.com/"|href="$ENV{LINKEDIN_URL}"|g' "$html_file"
done < <(find "$ROOT_DIR/dist" -type f -name "*.html" -print0)
log_ok "LinkedIn URL set to $LINKEDIN_URL"

log_step "Applying visibility toggles"
TOGGLE_CSS=""
[[ "${HIDE_NEWSLETTER:-false}" == "true" ]] && TOGGLE_CSS+="._3{display:none;}"
[[ "${HIDE_WEBFLOW_BADGE:-false}" == "true" ]] && TOGGLE_CSS+=".footer-info-right-wrap{display:none;}"
if [[ -n "$TOGGLE_CSS" ]]; then
  while IFS= read -r -d '' html_file; do
    TOGGLE_CSS="$TOGGLE_CSS" perl -0777 -i -pe \
      's|</head>|<style>$ENV{TOGGLE_CSS}</style>\n</head>|s' "$html_file"
  done < <(find "$ROOT_DIR/dist" -type f -name "*.html" -print0)
fi
log_ok "Toggles — newsletter:${HIDE_NEWSLETTER:-false} webflow-badge:${HIDE_WEBFLOW_BADGE:-false}"

log_step "Setting contact form action and method"
for f in "$INDEX_FILE" "$ROOT_DIR/dist/work.html" "$ROOT_DIR/dist/financial-partnerships.html"; do
  [[ -f "$f" ]] || continue
  perl -0777 -i -pe '
    s|(<form id="wf-form-Main-Contact-Form"[^>]*?) method="get"|$1 method="post"|s;
    s|(<form id="wf-form-Main-Contact-Form"[^>]*)>|$1 action="$ENV{FORM_ACTION}">|s;
  ' "$f"
done
log_ok "Form action set to $FORM_ACTION (method: post)"

log_step "Injecting honeypot field into contact form"
HONEYPOT='<div style="position:absolute;left:-9999px;top:-9999px;" aria-hidden="true"><input type="text" name="website_url" id="website_url" tabindex="-1" autocomplete="off" value=""></div>'
for f in "$INDEX_FILE" "$ROOT_DIR/dist/work.html" "$ROOT_DIR/dist/financial-partnerships.html"; do
  [[ -f "$f" ]] || continue
  perl -0777 -i -pe "s|(<form id=\"wf-form-Main-Contact-Form\"[^>]*>)|\$1\n                  ${HONEYPOT}|s;" "$f"
done
log_ok "Honeypot field injected (name: website_url)"

log_step "Injecting _template hidden field into contact form"
TEMPLATE_FIELD='<input type="hidden" name="_template" value="nineyards-pt-site_new_lead">'
for f in "$INDEX_FILE" "$ROOT_DIR/dist/work.html" "$ROOT_DIR/dist/financial-partnerships.html"; do
  [[ -f "$f" ]] || continue
  perl -0777 -i -pe "s|(<form id=\"wf-form-Main-Contact-Form\"[^>]*>)|\$1\n                  ${TEMPLATE_FIELD}|s;" "$f"
done
log_ok "_template hidden field injected"

log_step "Injecting _recipient hidden field into contact form"
for f in "$INDEX_FILE" "$ROOT_DIR/dist/work.html" "$ROOT_DIR/dist/financial-partnerships.html"; do
  [[ -f "$f" ]] || continue
  perl -0777 -i -pe '
    my $field = "<input type=\"hidden\" name=\"_recipient\" value=\"$ENV{FORM_RECIPIENT}\">";
    s|(<form id="wf-form-Main-Contact-Form"[^>]*>)|$1\n                  $field|s;
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
  my $success = $ENV{FORM_SUCCESS_MSG}; $success =~ s/'"'"'/\\'"'"'/g;
  my $error   = $ENV{FORM_ERROR_MSG};   $error   =~ s/'"'"'/\\'"'"'/g;
  s/__FORM_SUCCESS_MSG__/$success/g;
  s/__FORM_ERROR_MSG__/$error/g;
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
