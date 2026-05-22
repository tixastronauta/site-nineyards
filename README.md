# nineyards — Site

Deployment pipeline for the [nineyards](https://nineyards.pt) website. Source files are exported from Webflow; the build pipeline injects SEO metadata, GTM, contact form fields, and static overrides before deploying to Cloudflare Workers.

---

## Stack

| Layer | Tech |
|---|---|
| Hosting | Cloudflare Workers (static assets via `ASSETS`) |
| Source | Webflow HTML export |
| Build | Bash pipeline (`build.sh`) |
| Package manager | npm (wrangler only) |

---

## Project structure

```
src/              Webflow export — do not edit directly
static/
  css/custom.css  CSS overrides (applied on top of Webflow styles)
  js/form-status.js  Form feedback modal (placeholders replaced at build)
dist/             Build output — gitignored, regenerated on every build
build.sh          Build pipeline
deploy.sh         build + wrangler deploy
worker.js         Cloudflare Worker (www → apex redirect, serves assets)
wrangler.toml     Worker config
site.env          Site metadata & secrets
```

---

## Commands

```bash
npm install          # first time only — installs wrangler

npm run build        # build src/ → dist/ (required before preview or manual wrangler commands)
npm run preview      # build + serve locally via wrangler dev
npm run deploy       # build + deploy to production (nineyards.pt)
npm run offline      # put the site into maintenance mode (503) immediately — no build needed
```

To bring the site back online after `offline`, run `npm run deploy`.

---

## Configuration

All build-time values live in `site.env`:

| Variable | Description |
|---|---|
| `SITE_URL` | Canonical site URL |
| `TITLE` | `<title>` and OG title |
| `DESCRIPTION` | Meta description |
| `KEYWORDS` | Meta keywords |
| `AUTHOR` | Meta author |
| `OG_IMAGE` | Open Graph image URL |
| `OG_LOCALE` | e.g. `en_US` |
| `OG_SITE_NAME` | Site name for OG |
| `GTM_ID` | Google Tag Manager container ID |
| `LINKEDIN_URL` | LinkedIn company page URL |
| `HIDE_NEWSLETTER` | `true` / `false` — hide the newsletter section in the footer |
| `HIDE_WEBFLOW_BADGE` | `true` / `false` — hide the "Powered by Webflow" footer text |
| `FORM_ACTION` | Mailer endpoint URL |
| `FORM_RECIPIENT` | Email address for form submissions |
| `FORM_SUCCESS_MSG` | Success message shown after form submit |
| `FORM_ERROR_MSG` | Error message shown after form submit |

> **Note:** `GTM_ID` is currently set to `GTM-XXXXXXX` — replace it with the real container ID before deploying to production.

---

## What the build pipeline does

1. Copies `src/` → `dist/`
2. Merges `static/` overrides into `dist/`
3. Injects `css/custom.css` link into every HTML page
4. Removes template/internal pages (`401.html`, `style-guide.html`, `changelog.html`)
5. Replaces SEO metadata in `index.html` from `site.env`
6. Strips Webflow comments and generator meta tag
7. Sets contact form `action` + `method="post"` on all pages that carry the form
8. Injects honeypot, `_template`, and `_recipient` hidden fields into the contact form
9. Injects GTM head + body snippets into `index.html`
10. Substitutes message placeholders in `form-status.js`
11. Injects `form-status.js` into every HTML page
12. Stamps a build timestamp comment at the top of every HTML file

---

## Updating the site

1. Export the site from Webflow
2. Replace the contents of `src/` with the new export
3. Run `npm run build` and verify `dist/index.html`
4. Run `npm run preview` to smoke-test locally
5. Run `npm run deploy`
