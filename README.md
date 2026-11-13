# SalesHub CRM

SalesHub CRM is a Flutter application with a Go API backed by PostgreSQL.

## Deploy the web app to Netlify

Netlify hosts the Flutter web frontend as a static site. The Go API and its
PostgreSQL database must remain deployed separately; the current frontend
default API is `https://server-rho-two-45.vercel.app`.

1. Push this repository to a Git provider and create a Netlify site from it.
2. Set the Netlify base directory to the directory containing `pubspec.yaml`
   and `netlify.toml` (the repository root for this project).
3. Keep the build command and publish directory from `netlify.toml`, or set:
   - Build command: `bash scripts/netlify-build.sh`
   - Publish directory: `build/web`
4. In **Site configuration → Environment variables**, set `API_BASE_URL` to
   the public HTTPS URL of your running Go API if it differs from the current
   default. This value is compiled into the web app, so trigger a new deploy
   after changing it. Do not put database passwords, signing keys, or other
   secrets in this frontend variable.
5. Deploy the site. Netlify downloads the pinned Flutter SDK, resolves the
   Dart dependencies, and builds the web app. `netlify.toml` also configures
   the fallback needed for Flutter web routes.

### Backend requirements

Before deploying the frontend, confirm that the API is reachable over HTTPS
and configure the backend host with `DATABASE_URL` (or `POSTGRES_URL` /
`DB_HOST` and the other `DB_*` settings) and a strong `JWT_SECRET`. The server
does not run as part of this Netlify build. If the API restricts CORS, add the
Netlify site's origin (and any custom domain) to its `CORS_ALLOWED_ORIGINS`
setting, then redeploy the backend.

Firebase web authentication and Remote Config require Firebase web app
configuration. The current app does not supply web Firebase options, so
Firebase initialization is skipped in browsers; backend email/password
authentication remains available through the Go API.

### Local web build

With Flutter 3.44.4 or compatible installed:

```sh
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://your-api.example.com
```

The generated site is in `build/web`.
