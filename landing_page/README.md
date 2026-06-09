# Exlser Landing Page

React/Vite landing page for the public Exlser website.

Planned hosting target:

```text
exlser.com      -> React landing page
exlser.com/app  -> optional Flutter web app
```

## Local Development

```bash
npm install
npm run dev
```

## Production Build

```bash
npm run build
npm run preview
```

The landing currently uses static assets copied from `flutter_app/assets`.
If those app screenshots change, refresh the matching files in
`landing_page/public/assets`.

The hero trailer is committed as `public/assets/trailer.mp4`. Keep the original
`.mov` source local unless it is explicitly needed.

The landing has its own lightweight i18n dictionary in `src/i18n.js`, aligned
with the same nine languages supported by the Flutter app.
