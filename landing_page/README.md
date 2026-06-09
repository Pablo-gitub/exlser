# Exlser Landing Page

React/Vite landing page for the public Exlser website.

Planned hosting target:

```text
exlser.com      -> React landing page
exlser.it       -> same landing page or localized alias
exlser.com/demo -> Flutter web demo app
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

The GitHub Action builds both:

```text
landing_page/dist        -> React landing
landing_page/dist/demo   -> Flutter web app built with --base-href /demo/
```

## Firebase Hosting

The landing is configured to deploy to the Firebase Hosting target `landing`.
The expected Hosting site id is `exlser-landing` inside the existing
`excelcategory` Firebase project.

Before the GitHub Action can deploy, create or verify the Hosting site and
connect the domains in Firebase Console:

```bash
firebase hosting:sites:create exlser-landing
firebase target:apply hosting landing exlser-landing
```

Then connect `exlser.com` and `exlser.it` to that Hosting site and configure
the DNS records in the domain registrar.
