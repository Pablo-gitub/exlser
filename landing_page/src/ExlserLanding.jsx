import { useEffect, useMemo, useState } from "react";
import {
  BarChart3,
  ChevronDown,
  Database,
  Download,
  FileJson,
  FileSpreadsheet,
  FileText,
  Filter,
  Globe2,
  History,
  Languages,
  MonitorDown,
  QrCode,
  SearchCode,
  ShieldCheck,
  Smartphone,
  Table2,
} from "lucide-react";
import { FaApple, FaGithub, FaInstagram, FaLinkedin, FaLinux, FaWindows } from "react-icons/fa";
import {
  getDemoPath,
  getInitialLanguage,
  getLanguageFromPath,
  getLocalizedPath,
  languages,
  translations,
} from "./i18n.js";
import { useLandingVideoPreviews } from "./useLandingVideoPreviews.js";
import { usePointerGlow, useScrollReveal } from "./useLandingMotion.js";

const links = {
  releases: "https://github.com/Pablo-gitub/exlser/releases",
  legacy: "https://excelcategory.web.app",
  github: "https://github.com/Pablo-gitub/exlser",
  linkedin: "https://www.linkedin.com/in/paolo-pietrelli",
  instagram: "https://www.instagram.com/ing_paolo_pietrelli/",
  developer: "https://paolopietrelli.com",
};

const featureImages = [
  "/assets/home.jpeg",
  "/assets/filtering.jpeg",
  "/assets/works_list.png",
  "/assets/query.jpeg",
  "/assets/data_analysis.jpeg",
  "/assets/export.jpeg",
  "/assets/card_view.jpeg",
  "/assets/multi_languages.png",
];

const channelIcons = [Smartphone, MonitorDown, Globe2, FaGithub];
const featureIcons = [
  FileSpreadsheet,
  Filter,
  Database,
  SearchCode,
  BarChart3,
  Download,
  QrCode,
  Languages,
];
const formatIcons = {
  Excel: FileSpreadsheet,
  CSV: Table2,
  JSON: FileJson,
  PDF: FileText,
  SQL: Database,
};

// Input formats surfaced as chips beside the hero device — what you bring in,
// echoing the "your spreadsheets" headline. Export breadth lives in its own section.
const heroInputFormats = ["CSV", "Excel"];

// GitHub's stable "latest" redirect: always resolves to the newest release's
// asset, so these never go stale when a new desktop version is published.
const desktopReleaseBase = "https://github.com/Pablo-gitub/exlser/releases/latest/download";
const desktopTargets = [
  { id: "macos", label: "macOS", icon: FaApple, url: `${desktopReleaseBase}/macos-build.zip` },
  { id: "windows", label: "Windows", icon: FaWindows, url: `${desktopReleaseBase}/windows-build.zip` },
  { id: "linux", label: "Linux", icon: FaLinux, url: `${desktopReleaseBase}/linux-build.zip` },
];

// Best-effort desktop OS sniff; returns null on mobile or when unknown so the UI
// can fall back to offering every build.
function detectDesktopOS() {
  if (typeof navigator === "undefined") {
    return null;
  }

  const platform = navigator.userAgentData?.platform ?? navigator.platform ?? "";
  const haystack = `${platform} ${navigator.userAgent ?? ""}`.toLowerCase();

  if (/android|iphone|ipad|ipod/.test(haystack)) {
    return null;
  }
  if (/mac/.test(haystack)) {
    return "macos";
  }
  if (/win/.test(haystack)) {
    return "windows";
  }
  if (/linux|x11|cros/.test(haystack)) {
    return "linux";
  }
  return null;
}

function scrollToSection(id) {
  document.getElementById(id)?.scrollIntoView({ behavior: "smooth" });
}

function ExternalLink({ className, href, children, icon: Icon, newTab = true }) {
  return (
    <a
      className={className}
      href={href}
      target={newTab ? "_blank" : undefined}
      rel={newTab ? "noreferrer" : undefined}
    >
      {Icon ? <Icon aria-hidden="true" size={18} strokeWidth={2.2} /> : null}
      {children}
    </a>
  );
}

/** Renders `title` with `accent` wrapped in a gradient span, wherever it falls. */
function Headline({ title, accent }) {
  const start = accent ? title.indexOf(accent) : -1;

  if (start === -1) {
    return <h1>{title}</h1>;
  }

  return (
    <h1>
      {title.slice(0, start)}
      <span className="accent">{accent}</span>
      {title.slice(start + accent.length)}
    </h1>
  );
}

/**
 * OS-aware desktop download: a direct button for the detected platform plus a
 * dropdown for the others. Rendered inside the video section's action row.
 */
function DesktopDownload({ copy }) {
  const [os] = useState(detectDesktopOS);
  const detected = desktopTargets.find((target) => target.id === os);
  const others = detected ? desktopTargets.filter((target) => target.id !== os) : desktopTargets;

  return (
    <>
      {detected ? (
        <a className="button primary" href={detected.url}>
          <detected.icon aria-hidden="true" size={18} />
          {`${copy.for} ${detected.label}`}
        </a>
      ) : (
        <ExternalLink className="button primary" href={links.releases} icon={MonitorDown}>
          {copy.generic}
        </ExternalLink>
      )}

      <details className="os-menu">
        <summary>
          {copy.others}
          <ChevronDown aria-hidden="true" size={16} strokeWidth={2.4} />
        </summary>
        <div className="os-menu-list">
          {others.map((target) => (
            <a key={target.id} href={target.url}>
              <target.icon aria-hidden="true" size={16} />
              {target.label}
            </a>
          ))}
        </div>
      </details>
    </>
  );
}

export default function ExlserLanding() {
  const [language, setLanguage] = useState(getInitialLanguage);
  const copy = useMemo(() => translations[language] ?? translations.en, [language]);
  const selectedLanguage = languages.find((item) => item.code === language) ?? languages[0];
  const contactUrl =
    language === "it"
      ? "https://paolopietrelli.com/it/contact"
      : "https://paolopietrelli.com/en/contact";
  const demoUrl = getDemoPath();
  const channelLinks = [contactUrl, links.releases, demoUrl, links.github];

  useScrollReveal();
  usePointerGlow();

  useEffect(() => {
    document.documentElement.lang = language;

    const origin = window.location.origin;
    const canonicalHref = `${origin}/${language}/`;
    let canonicalLink = document.querySelector('link[rel="canonical"]');

    if (!canonicalLink) {
      canonicalLink = document.createElement("link");
      canonicalLink.setAttribute("rel", "canonical");
      document.head.appendChild(canonicalLink);
    }

    canonicalLink.setAttribute("href", canonicalHref);

    document
      .querySelectorAll('link[rel="alternate"][data-exlser-language]')
      .forEach((link) => link.remove());

    languages.forEach((item) => {
      const alternateLink = document.createElement("link");
      alternateLink.setAttribute("rel", "alternate");
      alternateLink.setAttribute("hreflang", item.code);
      alternateLink.setAttribute("href", `${origin}/${item.code}/`);
      alternateLink.dataset.exlserLanguage = item.code;
      document.head.appendChild(alternateLink);
    });

    const defaultLink = document.createElement("link");
    defaultLink.setAttribute("rel", "alternate");
    defaultLink.setAttribute("hreflang", "x-default");
    defaultLink.setAttribute("href", `${origin}/en/`);
    defaultLink.dataset.exlserLanguage = "x-default";
    document.head.appendChild(defaultLink);
  }, [language]);

  useEffect(() => {
    if (!getLanguageFromPath(window.location.pathname)) {
      window.history.replaceState(null, "", getLocalizedPath(language));
    }

    const handlePopState = () => {
      const pathLanguage = getLanguageFromPath(window.location.pathname);

      if (pathLanguage) {
        setLanguage(pathLanguage);
      }
    };

    window.addEventListener("popstate", handlePopState);

    return () => window.removeEventListener("popstate", handlePopState);
  }, [language]);

  const handleLanguageChange = (nextLanguage) => {
    if (nextLanguage === language) {
      return;
    }

    setLanguage(nextLanguage);
    window.history.pushState(null, "", getLocalizedPath(nextLanguage));
  };

  const videos = {
    preview: {
      poster: "/assets/preview_exlser_poster.jpg",
      src: "/assets/preview_exlser.mp4",
      title: copy.video.title,
    },
    trailer: {
      poster: "/assets/trailer_poster.jpg",
      src: "/assets/trailer.mp4",
      title: copy.trailer.title,
    },
  };
  const { previewVideoRef, trailerVideoRef } = useLandingVideoPreviews();

  return (
    <main className="landing">
      <header className="topbar">
        <a className="brand-link" href="#top" aria-label="Exlser home">
          <img src="/assets/Exlser_wordmark.png" alt="" />
        </a>

        <nav className="topnav" aria-label="Main navigation">
          <button type="button" onClick={() => scrollToSection("beta")}>
            {copy.trailer.eyebrow}
          </button>
          <button type="button" onClick={() => scrollToSection("features")}>
            {copy.nav.features}
          </button>
          <button type="button" onClick={() => scrollToSection("downloads")}>
            {copy.nav.downloads}
          </button>
          <button type="button" onClick={() => scrollToSection("contact")}>
            {copy.nav.contact}
          </button>
        </nav>

        <div className="topbar-actions">
          <ExternalLink className="nav-demo" href={demoUrl} icon={Globe2} newTab={false}>
            {copy.nav.demo}
          </ExternalLink>

          <label className="language-control">
            <span className="sr-only">{copy.nav.language}</span>
            <span className="language-flag" aria-hidden="true">
              {selectedLanguage.flag}
            </span>
            <select
              value={language}
              onChange={(event) => handleLanguageChange(event.target.value)}
              aria-label={`${copy.nav.language}: ${selectedLanguage.name}`}
              title={selectedLanguage.name}
            >
              {languages.map((item) => (
                <option key={item.code} value={item.code} aria-label={item.name}>
                  {item.flag}
                </option>
              ))}
            </select>
          </label>
        </div>
      </header>

      <section id="top" className="hero" aria-label={copy.hero.aria}>
        <div className="hero-inner">
          <div className="hero-copy-block" data-reveal>
            <a className="hero-badge" href="#beta">
              <span className="hero-badge-dot" aria-hidden="true" />
              {copy.hero.badge}
            </a>

            <Headline title={copy.hero.title} accent={copy.hero.titleAccent} />
            <p className="hero-copy">{copy.hero.copy}</p>

            <div className="hero-actions" aria-label={copy.hero.actions}>
              <ExternalLink className="button primary" href={contactUrl} icon={Smartphone}>
                {copy.hero.beta}
              </ExternalLink>
              <ExternalLink className="button secondary" href={demoUrl} icon={Globe2} newTab={false}>
                {copy.nav.demo}
              </ExternalLink>
            </div>
          </div>

          <div className="hero-visual" data-reveal data-reveal-delay="140">
            <div className="hero-phone">
              <span className="hero-phone-notch" aria-hidden="true" />
              <img src="/assets/data_analysis.jpeg" alt={copy.features[4].alt} loading="eager" />
            </div>
            <div className="hero-chips" aria-hidden="true">
              {heroInputFormats.map((format) => {
                const Icon = formatIcons[format] ?? FileText;
                return (
                  <span key={format}>
                    <Icon size={17} strokeWidth={2.2} />
                    {format}
                  </span>
                );
              })}
            </div>
          </div>
        </div>

        <div className="hero-strip" aria-label="Exlser strengths" data-reveal data-reveal-delay="240">
          {copy.hero.strengths.map((strength) => (
            <span key={strength}>{strength}</span>
          ))}
        </div>
      </section>

      <section className="section intro-band">
        <div className="section-copy compact" data-reveal>
          <p className="eyebrow">{copy.intro.eyebrow}</p>
          <h2>{copy.intro.title}</h2>
          <p>{copy.intro.text}</p>
        </div>

        <div className="metric-grid" aria-label={copy.intro.metricsLabel}>
          {copy.intro.metrics.map((metric, index) => (
            <div className="metric" key={metric.label} data-reveal data-reveal-delay={index * 90}>
              <strong>{metric.value}</strong>
              <span>{metric.label}</span>
            </div>
          ))}
        </div>
      </section>

      <section id="beta" className="section beta-section">
        <div className="beta-panel" data-reveal data-glow>
          <div className="section-copy">
            <p className="eyebrow">{copy.trailer.eyebrow}</p>
            <h2>{copy.trailer.title}</h2>
            <p>{copy.trailer.text}</p>

            <ol className="beta-steps" aria-label={copy.trailer.stepsLabel}>
              {copy.trailer.steps.map((step, index) => (
                <li className="beta-step" key={step.title}>
                  <span className="beta-step-index" aria-hidden="true">
                    {index + 1}
                  </span>
                  <div>
                    <h3>{step.title}</h3>
                    <p>{step.text}</p>
                  </div>
                </li>
              ))}
            </ol>

            <div className="section-actions">
              <ExternalLink className="button primary" href={contactUrl} icon={Smartphone}>
                {copy.trailer.betaCta}
              </ExternalLink>
            </div>

            <div className="beta-links">
              <h3>{copy.trailer.moreInfo}</h3>
              <div className="beta-links-row">
                <ExternalLink href={links.instagram} icon={FaInstagram}>
                  Instagram
                </ExternalLink>
                <ExternalLink href={links.linkedin} icon={FaLinkedin}>
                  LinkedIn
                </ExternalLink>
                <ExternalLink href={links.github} icon={FaGithub}>
                  GitHub
                </ExternalLink>
              </div>
            </div>
          </div>

          <div className="beta-phone">
            <span className="beta-phone-notch" aria-hidden="true" />
            <video
              ref={trailerVideoRef}
              controls
              disablePictureInPicture
              disableRemotePlayback
              muted
              loop
              playsInline
              preload="metadata"
              controlsList="nodownload noremoteplayback"
              poster={videos.trailer.poster}
              aria-label={copy.trailer.title}
            >
              <source src={videos.trailer.src} type="video/mp4" />
            </video>
          </div>

          <div className="beta-privacy">
            <div className="beta-privacy-icon" aria-hidden="true">
              <ShieldCheck size={20} strokeWidth={2.2} />
            </div>
            <div>
              <h3>{copy.trailer.privacyTitle}</h3>
              <p>{copy.trailer.privacyText}</p>
            </div>
          </div>
        </div>
      </section>

      <section className="section video-section">
        <div className="video-frame preview-frame" data-reveal>
          <video
            ref={previewVideoRef}
            controls
            disablePictureInPicture
            disableRemotePlayback
            muted
            loop
            playsInline
            preload="metadata"
            controlsList="nodownload noremoteplayback"
            poster={videos.preview.poster}
            aria-label={copy.video.title}
          >
            <source src={videos.preview.src} type="video/mp4" />
          </video>
        </div>

        <div className="section-copy" data-reveal data-reveal-delay="120">
          <p className="eyebrow">{copy.video.eyebrow}</p>
          <h2>{copy.video.title}</h2>
          <p>{copy.video.text}</p>
          <div className="section-actions">
            <ExternalLink className="button secondary" href={demoUrl} icon={Globe2} newTab={false}>
              {copy.video.demoCta}
            </ExternalLink>
            <DesktopDownload copy={copy.downloads.desktop} />
          </div>
          <div className="section-subactions">
            <ExternalLink className="text-link sm" href={links.releases}>
              {copy.downloads.desktop.all}
            </ExternalLink>
          </div>
        </div>
      </section>

      <section id="features" className="section feature-section">
        <div className="section-heading" data-reveal>
          <p className="eyebrow">{copy.featuresHeading.eyebrow}</p>
          <h2>{copy.featuresHeading.title}</h2>
          <p>{copy.featuresHeading.text}</p>
        </div>

        <div className="feature-grid">
          {copy.features.map((feature, index) => {
            const Icon = featureIcons[index];

            return (
              <article
                className="feature-card"
                key={feature.title}
                data-reveal
                data-reveal-delay={(index % 3) * 90}
                data-glow
              >
                <div className="feature-stage">
                  <img src={featureImages[index]} alt={feature.alt} loading="lazy" />
                </div>
                <div className="feature-body">
                  <h3>
                    <span className="feature-icon" aria-hidden="true">
                      <Icon size={17} strokeWidth={2.2} />
                    </span>
                    <span>{feature.title}</span>
                  </h3>
                  <p>{feature.text}</p>
                </div>
              </article>
            );
          })}
        </div>
      </section>

      <section className="section cross-platform-section" data-reveal>
        <div className="section-copy">
          <p className="eyebrow">{copy.crossPlatform.eyebrow}</p>
          <h2>{copy.crossPlatform.title}</h2>
          <p>{copy.crossPlatform.text}</p>
          <p className="ios-note">
            <FaApple aria-hidden="true" />
            <span>{copy.crossPlatform.iosNote}</span>
          </p>
        </div>

        <div className="device-stack" role="img" aria-label={copy.crossPlatform.alt}>
          <div className="device-window">
            <div className="device-window-bar" aria-hidden="true">
              <span className="device-dot" />
              <span className="device-dot" />
              <span className="device-dot" />
              <span className="device-url">exlser.com</span>
            </div>
            <img src="/assets/preview_exlser_poster.jpg" alt="" loading="lazy" />
          </div>
          <div className="device-phone" aria-hidden="true">
            <span className="device-phone-notch" />
            <img src="/assets/filtering.jpeg" alt="" loading="lazy" />
          </div>
        </div>
      </section>

      <section id="downloads" className="section download-section">
        <div className="section-heading" data-reveal>
          <p className="eyebrow">{copy.downloads.eyebrow}</p>
          <h2>{copy.downloads.title}</h2>
        </div>

        <div className="channel-grid">
          {copy.downloads.channels.map((channel, index) => {
            const Icon = channelIcons[index];

            return (
              <article
                className="channel-card"
                key={channel.title}
                data-reveal
                data-reveal-delay={index * 80}
                data-glow
              >
                <div className="channel-icon" aria-hidden="true">
                  <Icon size={22} strokeWidth={2.2} />
                </div>
                <h3>{channel.title}</h3>
                <p>{channel.text}</p>
                {index === 1 ? (
                  <ExternalLink className="text-link" href={links.releases} icon={Icon}>
                    {copy.downloads.desktop.all}
                  </ExternalLink>
                ) : (
                  <ExternalLink
                    className="text-link"
                    href={channelLinks[index]}
                    icon={index === 0 ? Globe2 : Icon}
                    newTab={channelLinks[index] !== demoUrl}
                  >
                    {channel.cta}
                  </ExternalLink>
                )}
              </article>
            );
          })}
        </div>
      </section>

      <section className="section export-band" data-reveal data-glow>
        <div>
          <p className="eyebrow">{copy.export.eyebrow}</p>
          <h2>{copy.export.title}</h2>
          <p>{copy.export.text}</p>
        </div>

        <div className="format-list" aria-label={copy.export.formatsLabel}>
          {copy.export.formats.map((format) => {
            const Icon = formatIcons[format] ?? FileText;
            return (
              <span key={format}>
                <Icon aria-hidden="true" size={18} strokeWidth={2.2} />
                {format}
              </span>
            );
          })}
        </div>
      </section>

      <section className="section legacy-section" data-reveal>
        <div className="legacy-icon" aria-hidden="true">
          <History size={24} strokeWidth={2.2} />
        </div>
        <div>
          <p className="eyebrow">{copy.legacy.eyebrow}</p>
          <h2>{copy.legacy.title}</h2>
          <p>{copy.legacy.text}</p>
        </div>
        <ExternalLink className="button secondary legacy-button" href={links.legacy}>
          {copy.legacy.cta}
        </ExternalLink>
      </section>

      <section id="contact" className="section final-section" data-reveal data-glow>
        <div>
          <p className="eyebrow">{copy.contact.eyebrow}</p>
          <h2>{copy.contact.title}</h2>
          <p>{copy.contact.text}</p>
        </div>

        <div className="final-actions">
          <ExternalLink className="button primary" href={contactUrl} icon={Globe2}>
            {copy.contact.developer}
          </ExternalLink>
          <ExternalLink className="button secondary" href={links.github} icon={FaGithub}>
            {copy.contact.github}
          </ExternalLink>
        </div>
      </section>

      <footer className="footer">
        <a className="footer-brand" href="#top" aria-label={copy.footer.top}>
          <img src="/assets/Exlser_wordmark.png" alt="Exlser" />
        </a>

        <nav aria-label={copy.footer.socials}>
          <ExternalLink href={links.developer} icon={Globe2}>
            paolopietrelli.com
          </ExternalLink>
          <ExternalLink href={links.github} icon={FaGithub}>
            GitHub
          </ExternalLink>
          <ExternalLink href={links.linkedin} icon={FaLinkedin}>
            LinkedIn
          </ExternalLink>
          <ExternalLink href={links.instagram} icon={FaInstagram}>
            Instagram
          </ExternalLink>
        </nav>
      </footer>
    </main>
  );
}
