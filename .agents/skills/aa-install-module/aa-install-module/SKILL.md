---
name: aa-install-module
description: "Install an Alliance Auth module from a GitHub/GitLab URL into the project: pip install, INSTALLED_APPS, migrate, collectstatic, place its menu item in a sidebar folder, restart supervisor. Trigger: /aa-install-module <repo-url>"
---

# aa-install-module

Installs a third-party Alliance Auth (AA) module from a GitHub or GitLab
repository URL into the current AA project and wires it into the sidebar menu
inside a folder.

Trigger: `/aa-install-module <https://github.com/...> | <https://gitlab.com/...>`

## Project assumptions (verify on first run)

- Virtualenv Python: `/home/allianceserver/venv/auth/bin/python`
- Project dir:        `/home/allianceserver/myauth`
- Settings module:   `myauth.settings.local`
- INSTALLED_APPS are appended in `myauth/myauth/settings/local.py`
- Services managed by supervisor under the `myauth:` group (gunicorn, beat, worker, authenticator)
- Menu items live in the DB (`allianceauth.menu.MenuItem`); folders are rows
  with no `hook_hash` and empty `url`. App items are rows with a `hook_hash`
  generated from the module's `menu_item_hook`.

If any of the above differ, adapt the commands accordingly — do NOT blindly
copy paths.

## Algorithm

### 0. READ THE README FIRST — extract the full install contract

Before touching anything, fetch the module's README and dependency metadata.
Two sources, in order — PyPI JSON is richer (gives `requires_dist` verbatim):

1. **PyPI JSON API (primary):** `https://pypi.org/pypi/<pip-name>/json`
   - `info.description` holds the README (often the same as GitHub/GitLab README,
     rendered to markdown).
   - `info.requires_dist` lists exact dependency constraints — use it to verify
     companion apps WITHOUT reading the repo's setup.py.
   - `info.requires_python` gives the Python version gate.
   - `info.project_urls.Source` / `Homepage` give the repo URL (use it for the
     raw README fallback and for git+URL installs).
   - Derive the pip name from the user's URL: `https://pypi.org/project/<name>/`
     → `<name>`. For GitHub repos where the PyPI name is not the repo name
     (e.g. `allianceauth-corp-tools` repo → `allianceauth-corptools` package),
     fetch the repo's `setup.py`/`setup.cfg`/`pyproject.toml` to get the pip name.
2. **Raw README (fallback / cross-check):**
   - GitHub: `https://raw.githubusercontent.com/<owner>/<repo>/<default-branch>/README.md`
     (default branch usually `main` or `master` — try `main` first, then `master`)
   - GitLab: `https://gitlab.com/<owner>/<repo>/-/raw/<default-branch>/README.md`
   - If `README.rst` exists instead, fetch that (older AA plugins use RST).

Use the `fetch` tool on these URLs (it follows redirects and needs the host
pre-granted). PyPI and `raw.githubusercontent.com` / `gitlab.com` are the usual
hosts — grant them once.

Extract from the README into a written checklist BEFORE running any commands:

**Pre-install / prerequisites**
- Minimum Alliance Auth / Python / Django version required
- Required companion apps that must be installed and added to `INSTALLED_APPS`
  BEFORE this module (e.g. AA-Forum needs nothing extra, but AA-StructureTimers
  needs `structuretimers`, some plugins pull `django-ckeditor-5` as a dep)
- Required AA plugins already present (e.g. "requires Memberaudit") — verify
  they are in `INSTALLED_APPS` already; abort if missing and ask the user
- Required SDE data / ESI scopes / permissions setup
- Any setting that must exist BEFORE `migrate` runs (rare, but real)

**Install steps from the README**
- Exact `pip install` line (some plugins install from git+URL with a tag,
  some from PyPI) — prefer the documented line verbatim
- The exact `INSTALLED_APPS` entry string(s)
- Any additional `INSTALLED_APPS` companion entries

**Post-install config from the README**
- Additional Django settings to add to `myauth/myauth/settings/local.py`
  (API keys, feature toggles, theme overrides, etc.) — copy verbatim with a
  comment citing the README source
- `CELERYBEAT_SCHEDULE[...]` entries to add — copy verbatim. NOTE: some
  modules (e.g. corptools via `ct_setup`, afat via admin) auto-create their
  celery schedules through a management command or admin UI — do NOT
  duplicate those into `local.py`; follow the README's specific mechanism.
- `APPS_WITH_PUBLIC_VIEWS` additions if the module exposes public views
- **`modeltranslation` prepend ordering** — afat and similar modules require
  `INSTALLED_APPS = ["modeltranslation"] + INSTALLED_APPS` (prepend, not
  append) right after the `INSTALLED_APPS += [...]` block. Check the README
  for this exact line; respect the prepend-vs-append distinction.
- **Companion-app settings** — e.g. `eve_sde` requires `ESDE_TASK_SPLIT = True`
  for bare-metal installs, plus its own `CELERYBEAT_SCHEDULE` entry for
  `check_for_sDE_updates`. If the README bundles companion settings, add
  them when you add the companion app.
- **Settings via admin backend, NOT local.py** — many modules (afat,
  corptools, metenox) store feature config in a Django admin model (e.g.
  "Corptools Configuration", afat's admin settings) or in plain Django
  settings with sane defaults. Do NOT invent settings for these — only add
  what the README explicitly puts in `local.py`. Note admin-config items as
  TODOs for the user.
- Permissions/groups to create via Django admin (note them for the user;
  do not create admin accounts unprompted)
- Required cron jobs / systemd timers / external services
- Webhook / Discord bot configuration
- Theme or asset compilation steps (rare for AA plugins, but some need
  `npm install` in a vendored dir — flag for the user, do not run npm)

**Post-install management commands**
Grep the README for `python manage.py <cmd>` and `auth <cmd>` (the `auth`
  alias is docker-only — for bare metal use `manage.py`). Common ones:
- `ct_setup` (corptools) — one-time setup, auto-creates celery schedules
- `esde_load_sde` (eve_sde companion, used by afat) — loads EVE SDE data
- `afat_import_from_allianceauth_fat` (afat) — one-time data migration,
  ONLY if migrating from native FAT; conditional, not always run
- `metenox_update_moons_from_moonmining` (metenox) — conditional data import,
  only if aa-moonmining is already installed
Record each command, whether it's mandatory or conditional, and its order.

**URL config changes (`myauth/myauth/urls.py`)**
Some AA modules require edits BEYOND `local.py` — to the global URL config.
Grep the README for `urls.py`, `urlpatterns`, `include(`. Real example (aa-forum
with django-ckeditor-5):
```python
if apps.is_installed("django_ckeditor_5"):
    urlpatterns = (
        [path("ckeditor5/", include("django_ckeditor_5.urls"))]
        + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
        + urlpatterns
    )
```
Record: which app's URLs to include, the mount path, whether it must be
prepended/appended relative to existing `urlpatterns`, and any `static()`
media-serving helper needed.

**Webserver (Nginx/Apache) media/static location**
Modules that handle user-uploaded files (forum images, etc.) need the reverse
proxy to serve a `MEDIA_ROOT` directory directly instead of proxying to
gunicorn. Detect this when the README defines `MEDIA_ROOT`/`MEDIA_URL` AND
shows an Apache `Alias /media ...` + `ProxyPassMatch ^/media !` block OR an
Nginx `location /media { alias ...; }` block. For this server (Nginx, config
at `/etc/nginx/sites-enabled/<vhost>`), record: the `location` path, the
`alias` target directory, and that it sits next to the existing
`location /static` block. Flag Apache-only instructions as N/A here.

Print the extracted checklist to the user and confirm anything ambiguous
(especially companion-app prerequisites and any setting that takes a secret
or API key) before proceeding. Quote the README sections you relied on.

Then execute steps 1–9 below, weaving in the README-specific items where the
algorithm marks `«README: ...»`.

### 1. Resolve pip package name and Django app label from the repo URL

The URL is NOT always the pip name. Resolve in this order:

1. Fetch the repo's `setup.py` / `setup.cfg` / `pyproject.toml` from the
   default branch (use the `fetch` tool or `curl` the raw URL).
   - GitHub raw URL pattern: `https://raw.githubusercontent.com/<owner>/<repo>/<branch>/setup.py`
   - GitLab raw URL pattern: `https://gitlab.com/<owner>/<repo>/-/raw/<branch>/setup.py`
2. Extract:
   - **pip package name** from `name=` in setup.py / `[project] name =` in
     pyproject.toml / `[metadata] name =` in setup.cfg.
   - **Django app label** from `install_requires`/dependencies is NOT enough.
     Prefer the documented import name. Common convention for AA plugins:
     pip package `aa-foo-bar` → app label `aa_foo_bar` (hyphens → underscores).
     Verify by checking the repo for a top-level package dir matching that
     snake_case name, or `urls.py` / `auth_hooks.py` referencing the namespace.
3. If ambiguous, check the repo's README — AA plugins document both the pip
   install line and the `INSTALLED_APPS` entry. Quote them back to the user
   before editing settings.

Example mapping (verified):
- `https://github.com/ppfeufer/aa-forum` → pip `aa-forum`, app `aa_forum`

### 2. pip install

Use the README's `pip install` line if it gave one verbatim. Otherwise:

```sh
/home/allianceserver/venv/auth/bin/pip install <pip-package-name>
```

«README: respect these README specifics —
- **Pinned versions**: afat pins `pip install allianceauth-afat==6.2.0`.
  Copy the `==X.Y.Z` pin verbatim if the README specifies it; otherwise omit.
- **`-U` flag**: corptools uses `pip install -U allianceauth-corptools`.
  Preserve `-U` when the README uses it.
- **git+URL installs**: some plugins install from a git tag/branch, not PyPI.
  Use the exact install line the README provides.»

«README: if the README requires companion pip packages (e.g. a specific
branch of a fork, or an extra like `pip install foo[full]`), install those
too, in the order the README specifies. Use `requires_dist` from the PyPI
JSON to confirm companion pip names without guessing.»

Capture the `Successfully installed ...` line and note any extra deps pulled in
(CKEditor, django-ninja, networkx, etc.).

### 3. Add to INSTALLED_APPS

Edit `myauth/myauth/settings/local.py`. The file has a list literal:

```python
INSTALLED_APPS += [
    ...
    'eve_sde',
]
```

Append the new app label (snake_case) as a string before the closing `]`.
Keep alphabetical-ish grouping consistent with the existing style.

«README: add any companion apps the README requires, in the order it specifies.
Some modules require their companion apps to appear BEFORE or AFTER their own
entry — respect that ordering. If the README lists extra companion apps that
are not yet installed, `pip install` them first (step 2 should have already
done this — verify against `requires_dist`).»

«README: `modeltranslation` prepend — afat and similar modules require
`INSTALLED_APPS = ["modeltranslation"] + INSTALLED_APPS` placed right after
the `INSTALLED_APPS += [...]` block (prepend, not append). If the README
shows this line, add it verbatim. If `modeltranslation` is already prepended
from a prior module install, do not add it again.»

### 4. Migrate

```sh
DJANGO_SETTINGS_MODULE=myauth.settings.local \
/home/allianceserver/venv/auth/bin/python manage.py migrate
```

Run from `/home/allianceserver/myauth`. Confirm the new app's migrations apply
with `OK`. Pre-existing `mysql.W002` / `structures.W001` warnings are
non-blocking — do not "fix" them as part of this task.

### 5. collectstatic

```sh
DJANGO_SETTINGS_MODULE=myauth.settings.local \
/home/allianceserver/venv/auth/bin/python manage.py collectstatic --noinput
```

Note the count of copied files for the summary.

### 5b. Apply post-install config from the README (step 0)

Before restarting services, apply every post-install item extracted from the
README in step 0. Concretely, edit `myauth/myauth/settings/local.py` and add:

- `CELERYBEAT_SCHEDULE[...]` entries — copy verbatim from the README, keep the
  task import path and crontab exactly. Place them near the other
  `CELERYBEAT_SCHEDULE` blocks in `local.py` for consistency.
- Any plain settings (API keys, feature flags, theme hooks, `*_URL`, etc.) —
  copy verbatim. If a value is a secret (API key, token), STOP and ask the user
  for the value; never invent or hardcode a placeholder that looks like a real
  key.
- `APPS_WITH_PUBLIC_VIEWS` additions (append the app label to the existing
  list in `local.py`).
- Permission/group setup — do NOT create admin accounts unprompted. Note in
  the summary what the user needs to configure in Django admin.
- External services (Discord webhook URL, Janice API key, etc.) — note as a
  follow-up for the user; do not invent values.

After editing settings, re-run `python -c "import django; django.setup()"`
wrapped in `manage.py shell -c` or a quick `manage.py check` to catch syntax
errors in `local.py` BEFORE restarting supervisor:

```sh
DJANGO_SETTINGS_MODULE=myauth.settings.local \
/home/allianceserver/venv/auth/bin/python manage.py check 2>&1 | tail -20
```

Fix any `local.py` syntax errors before continuing — a broken settings file
will crash gunicorn on restart.

### 5c. Run module-specific post-install management commands (step 0)

Many AA modules ship a one-time management command that must run AFTER
`migrate` + `collectstatic` but BEFORE supervisor restart. These are NOT
standard Django commands — they are module-specific. Run each one captured
in step 0's "post-install management commands" checklist, in README order:

```sh
DJANGO_SETTINGS_MODULE=myauth.settings.local \
/home/allianceserver/venv/auth/bin/python manage.py <command>
```

Examples seen in the wild:
- `corptools` → `python manage.py ct_setup` (mandatory, auto-creates celery
  schedules and default config).
- `eve_sde` (companion, used by `afat`) → `python manage.py esde_load_sde`
  (loads EVE SDE reference data; long-running).
- `afat` → `python manage.py afat_import_from_allianceauth_fat` (CONDITIONAL —
  only when migrating from the deprecated native FAT module; skip otherwise).
- `metenox` → `python manage.py metenox_update_moons_from_moonmining` and
  `metenox_update_all_prices` (CONDITIONAL — only if `aa-moonmining` is already
  installed; the first imports moon scans, the second refreshes prices).

Rules:
- **Mandatory commands** (like `ct_setup`, `esde_load_sde`) — run them.
- **Conditional commands** — only run if the README's precondition is met
  (e.g. the source module is already in `INSTALLED_APPS`). When in doubt,
  ask the user; do not blindly run a data-import command that could clobber
  state.
- Capture each command's output for the summary. Some (e.g. `esde_load_sde`)
  pull large datasets and can take minutes — use `timeout_ms` generously.

### 5d. Apply URL config and webserver changes (step 0)

Some AA modules need edits BEYOND `local.py`. Apply them only if step 0's
checklist captured them; otherwise skip this step.

**URL config (`myauth/myauth/urls.py`)**
Add the README-specified URL block, guarding it with `apps.is_installed("<app>")`
so it only activates when the module is installed. Pattern (aa-forum/
django-ckeditor-5):
```python
from django.apps import apps
from django.conf import settings
from django.conf.urls.static import static
from django.urls import include, path

urlpatterns = [path('', include(urls))]  # existing

if apps.is_installed("<app>"):
    urlpatterns = (
        [path("<mount>/", include("<app>.urls"))]
        + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
        + urlpatterns
    )
```
Respect prepend-vs-append ordering exactly as the README shows — the new
urlpatterns block usually goes BEFORE the existing `urlpatterns` (so the
module's routes take priority) but keep the existing AA `urlpatterns` intact.
Re-run `manage.py check` after editing to catch URLconf errors before restart.

**Webserver media location (Nginx)**
This server uses Nginx; config lives at `/etc/nginx/sites-enabled/<vhost>`
(detect the vhost from the project's `SITE_URL` in `local.py`). If the README
defines `MEDIA_ROOT` AND shows an Nginx/Apache media block, add a Nginx
`location /media` block right after the existing `location /static` block:
```nginx
location /media {
    alias /var/www/myauth/media;
    autoindex off;
}
```
The `alias` target must match the README's `MEDIA_ROOT` parent (typically
`/var/www/myauth/media`, with uploads going to the `MEDIA_ROOT` subdirectory).
Create the directory if missing and set ownership to the user running gunicorn
(`allianceserver`):
```sh
sudo mkdir -p <MEDIA_ROOT>
sudo chown -R allianceserver:allianceserver <MEDIA_ROOT parent>
sudo chmod -R 755 <MEDIA_ROOT parent>
```
Back up the vhost before editing (`cp ... .bak.$(date +%s)`), then:
```sh
sudo nginx -t && sudo systemctl reload nginx
```
Skip this sub-step if the module has no `MEDIA_ROOT`/uploads requirement.
For Apache-only READMEs, note the Apache block as a TODO for the user (the
server here is Nginx — do NOT install Apache just to serve media).

### 6. Place the module's menu item in a sidebar folder

Run the bundled helper from `scripts/place_in_menu_folder.py`. The script:
- resolves the module's `menu_item_hook` by matching the app label to the
  hook class module,
- looks up (or creates) a `MenuItem` folder by text,
- sets `parent` + `order` on the app item row.

```sh
DJANGO_SETTINGS_MODULE=myauth.settings.local \
/home/allianceserver/venv/auth/bin/python \
    <skill_dir>/scripts/place_in_menu_folder.py \
    --app <django_app_label> \
    --folder <ExistingFolderNameOrNewName> \
    --order 9999 \
    [--icon "fa-solid fa-comments"]
```

Folder choice guidance:
- Prefer an EXISTING folder that fits the module's purpose (e.g. "Informative"
  for wiki/forum/news, "Structures" for moonmining/structures, "Fleets" for
  SRP/AFAT/fittings, "Audit" for MemberAudit/CorpTools, "Groups" for group
  tools). List current folders first if unsure:
  ```sh
  DJANGO_SETTINGS_MODULE=myauth.settings.local \
  /home/allianceserver/venv/auth/bin/python -c "
  import django; django.setup()
  from allianceauth.menu.models import MenuItem
  for i in MenuItem.objects.filter(parent__isnull=True, hook_hash__isnull=True, url=''):
      print(i.id, i.text)
  "
  ```
- If no suitable folder exists, pass a new folder name + `--icon` and the
  script creates it. Good default icon: `fa-solid fa-folder`.

The menu is rendered from the DB on every request — no restart needed for the
menu change to take effect.

### 7. Restart supervisor services

The Python code changes require a restart of gunicorn / worker / beat:

```sh
sudo supervisorctl restart myauth:*
```

Then verify:

```sh
sudo supervisorctl status
```

All `myauth:*` programs must be `RUNNING`. `memmon`, `seat:*`, `tg-bot` etc.
are unrelated and should be left alone.

### 8. Summary

Report back:
- pip package + version installed, plus any companion deps
- README items found and which were applied vs deferred to the user (secrets,
  external services, admin config)
- app label added to `INSTALLED_APPS` (+ companion apps if any)
- migrations applied (count)
- static files collected (count)
- post-install settings added to `local.py` (Celery schedules, feature flags,
  public-views list) — list each
- post-install management commands run (mandatory vs conditional)
- URL config changes applied to `myauth/urls.py` (if any)
- webserver media location added (vhost path, Nginx reload status) — or N/A
- folder the menu item was placed into (created vs reused)
- supervisor restart status
- explicit TODOs for the user (API keys to fill in, admin permissions to
  create, external services to configure) — do not silently skip these

Do NOT commit, push, or open a PR unless explicitly asked.

## Notes & edge cases

- **README is the source of truth.** The generic algorithm assumes a standard
  AA plugin. If the README contradicts any step (different pip line, different
  app label, required companion apps, additional settings, a mandatory
  management command like `ct_setup`/`esde_load_sde`), follow the README and
  note the deviation in the summary. Never silently override the README.
- **PyPI JSON API is the richest single source.** `requires_dist` gives exact
  companion-app constraints (no need to read setup.py), `requires_python`
  gates the Python version, and `info.description` holds the README. Prefer
  it over scraping the repo for setup.py when the pip name is known.
- **Two-step menu sync:** the first request after `migrate` may lazily create
  the `MenuItem` row for the new hook. If the helper can't find it, it forces
  a `menu_items` template-tag sync as a fallback.
- **Modules without a menu hook** (pure backend, e.g. `django_celery_results`,
  `sri`) have no `MenuItem` row — skip step 6 for them; they don't appear in
  the sidebar.
- **Modules needing extra Celery schedules:** add `CELERYBEAT_SCHEDULE[...]`
  entries to `local.py` per the module's README BEFORE restarting `beat`,
  otherwise scheduled tasks won't run. EXCEPTION: corptools (`ct_setup`) and
  afat auto-create their schedules via a management command or admin UI — for
  those, follow the README's specific mechanism and do NOT duplicate entries
  into `local.py`.
- **Updating an existing install** (not initial): some modules (afat) call
  for `redis-cli flushall` after `collectstatic`/`migrate` to clear stale
  cache. Check the README's "Updating" section and flush if instructed —
  otherwise caches may hold pre-upgrade state.
- **Settings live in admin, not local.py:** many modules (afat, corptools,
  metenox) store feature config in a Django admin model or in Django settings
  with sane defaults. Only add to `local.py` what the README explicitly puts
  there; flag admin-config items (expiry times, holding corps, doctrine
  toggles, module enable/active flags) as TODOs for the user.
- **Management commands are module-specific:** grep the README for
  `python manage.py <cmd>` / `auth <cmd>`. Mandatory ones (`ct_setup`,
  `esde_load_sde`) must run before restart. Conditional ones (data imports
  from a deprecated module) run only if their precondition holds.
- **Modules needing `APPS_WITH_PUBLIC_VIEWS`:** add to the list in `local.py`
  if the module exposes public views.
- **Settings module is `myauth.settings.local`, NOT `myauth.settings`.**
  `myauth.settings` is an empty package init; using it yields an empty
  `INSTALLED_APPS` and a `RuntimeError: Model class ... doesn't declare an
  explicit app_label`. Always use `myauth.settings.local`.
- **Bare-metal vs Docker paths:** AA READMEs document both. This skill is
  bare-metal — follow the "Bare Metal" section of the README, not the
  "Docker" section (no `docker compose`, no `auth <cmd>` alias).
- **URL config changes (`urls.py`):** a minority of AA modules need edits to
  `myauth/urls.py`, not just `local.py`. aa-forum (django-ckeditor-5) is the
  canonical example: it prepends a `path("ckeditor5/", include(...))` block
  guarded by `apps.is_installed("django_ckeditor_5")`. Always guard these
  blocks with `apps.is_installed(...)` so they no-op when the module is
  absent. Re-run `manage.py check` after editing to catch URLconf errors.
- **Webserver media location:** modules that handle uploads (forum images,
  etc.) require the reverse proxy to serve `MEDIA_ROOT` directly. This server
  is Nginx — add a `location /media { alias ...; }` block next to the existing
  `location /static`, create the directory, chown to the gunicorn user, and
  `nginx -t && systemctl reload nginx`. Apache-only README blocks are N/A
  here — do NOT install Apache just for media serving.

## Reference install (worked example: aa-forum)

```sh
# 1. pip
/home/allianceserver/venv/auth/bin/pip install aa-forum==3.2.0
# 2. INSTALLED_APPS in local.py: add 'django_ckeditor_5' BEFORE 'aa_forum',
#    plus the full CKEDITOR_5_* config block (FILE_UPLOAD_PERMISSION,
#    MEDIA_URL, MEDIA_ROOT, customColorPalette, CKEDITOR_5_CONFIGS)
# 3. urls.py: prepend the ckeditor5 URL block guarded by apps.is_installed()
# 4. create MEDIA_ROOT, chown to allianceserver
sudo mkdir -p /var/www/myauth/media/uploads
sudo chown -R allianceserver:allianceserver /var/www/myauth/media
# 5. Nginx: add `location /media` next to `location /static`, nginx -t && reload
# 6. migrate
DJANGO_SETTINGS_MODULE=myauth.settings.local \
/home/allianceserver/venv/auth/bin/python manage.py migrate
# 7. static
DJANGO_SETTINGS_MODULE=myauth.settings.local \
/home/allianceserver/venv/auth/bin/python manage.py collectstatic --noinput
# 8. manage.py check (catch URLconf / settings errors before restart)
DJANGO_SETTINGS_MODULE=myauth.settings.local \
/home/allianceserver/venv/auth/bin/python manage.py check
# 9. menu → Informative folder
DJANGO_SETTINGS_MODULE=myauth.settings.local \
/home/allianceserver/venv/auth/bin/python \
    <skill_dir>/scripts/place_in_menu_folder.py --app aa_forum --folder Informative
# 10. restart
sudo supervisorctl restart myauth:*
```

This example mirrors the real fix applied to this server: the initial install
skipped `django_ckeditor_5` in `INSTALLED_APPS`, the `CKEDITOR_5_*` config
block, the `urls.py` change, and the Nginx `/media` location, which caused
`ValueError: Missing staticfiles manifest entry for
'django_ckeditor_5/dist/styles.css'` on the forum profile view. All four
omissions are now covered by steps 3, 5b, 5c, 5d.