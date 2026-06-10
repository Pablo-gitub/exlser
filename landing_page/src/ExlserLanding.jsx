import { useEffect, useMemo, useState } from "react";
import {
  BarChart3,
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
  Smartphone,
  Table2,
} from "lucide-react";
import { FaGithub, FaInstagram, FaLinkedin } from "react-icons/fa";
import {
  getDemoPath,
  getInitialLanguage,
  getLanguageFromPath,
  getLocalizedPath,
  languages,
  translations,
} from "./i18n.js";
import { useLandingVideoPreviews } from "./useLandingVideoPreviews.js";

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
        <div className="hero-content">
          <div className="hero-copy-block">
            <p className="eyebrow">{copy.hero.eyebrow}</p>
            <h1>{copy.hero.title}</h1>
            <p className="hero-copy">{copy.hero.copy}</p>

            <div className="hero-actions" aria-label={copy.hero.actions}>
              <ExternalLink className="button primary" href={links.releases}>
                {copy.hero.desktop}
              </ExternalLink>
              <ExternalLink className="button secondary" href={contactUrl}>
                {copy.hero.beta}
              </ExternalLink>
            </div>
          </div>

          <img
            className="hero-logo"
            src="/assets/logo_full_tagline_high.png"
            alt="Exlser"
            fetchPriority="high"
          />
        </div>

        <div className="hero-strip" aria-label="Exlser strengths">
          {copy.hero.strengths.map((strength) => (
            <span key={strength}>{strength}</span>
          ))}
        </div>
      </section>

      <section className="section intro-band">
        <div className="section-copy compact">
          <p className="eyebrow">{copy.intro.eyebrow}</p>
          <h2>{copy.intro.title}</h2>
          <p>{copy.intro.text}</p>
        </div>

        <div className="metric-grid" aria-label={copy.intro.metricsLabel}>
          {copy.intro.metrics.map((metric) => (
            <div key={metric.label}>
              <strong>{metric.value}</strong>
              <span>{metric.label}</span>
            </div>
          ))}
        </div>
      </section>

      <section className="section video-section">
        <div className="video-frame preview-frame">
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

        <div className="section-copy">
          <p className="eyebrow">{copy.video.eyebrow}</p>
          <h2>{copy.video.title}</h2>
          <p>{copy.video.text}</p>
          <div className="section-actions">
            <ExternalLink className="button primary" href={demoUrl} icon={Globe2} newTab={false}>
              {copy.video.demoCta}
            </ExternalLink>
            <ExternalLink className="button secondary light" href={links.releases} icon={MonitorDown}>
              {copy.video.desktopCta}
            </ExternalLink>
          </div>
        </div>
      </section>

      <section className="section legacy-section">
        <div className="legacy-icon" aria-hidden="true">
          <History size={28} strokeWidth={2.2} />
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

      <section className="section trailer-section">
        <div className="section-copy">
          <p className="eyebrow">{copy.trailer.eyebrow}</p>
          <h2>{copy.trailer.title}</h2>
          <p>{copy.trailer.text}</p>
          <div className="section-actions">
            <ExternalLink className="button primary" href={contactUrl} icon={Smartphone}>
              {copy.trailer.betaCta}
            </ExternalLink>
          </div>
          <div className="trailer-more">
            <h3>{copy.trailer.moreInfo}</h3>
            <div className="trailer-links">
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

        <div className="video-frame trailer-frame">
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
      </section>

      <section id="features" className="section feature-section">
        <div className="section-heading">
          <p className="eyebrow">{copy.featuresHeading.eyebrow}</p>
          <h2>{copy.featuresHeading.title}</h2>
          <p>{copy.featuresHeading.text}</p>
        </div>

        <div className="feature-grid">
          {copy.features.map((feature, index) => {
            const Icon = featureIcons[index];

            return (
              <article className="feature-card" key={feature.title}>
                <img src={featureImages[index]} alt={feature.alt} loading="lazy" />
                <div>
                  <h3>
                    <Icon aria-hidden="true" size={22} strokeWidth={2.2} />
                    <span>{feature.title}</span>
                  </h3>
                  <p>{feature.text}</p>
                </div>
              </article>
            );
          })}
        </div>
      </section>

      <section className="section cross-platform-section">
        <div className="section-copy">
          <p className="eyebrow">{copy.crossPlatform.eyebrow}</p>
          <h2>{copy.crossPlatform.title}</h2>
          <p>{copy.crossPlatform.text}</p>
        </div>
        <img
          className="cross-platform-image"
          src="/assets/exlser_crossplatform.png"
          alt={copy.crossPlatform.alt}
          loading="lazy"
        />
      </section>

      <section id="downloads" className="section download-section">
        <div className="section-heading">
          <p className="eyebrow">{copy.downloads.eyebrow}</p>
          <h2>{copy.downloads.title}</h2>
        </div>

        <div className="channel-grid">
          {copy.downloads.channels.map((channel, index) => {
            const Icon = channelIcons[index];

            return (
              <article className="channel-card" key={channel.title}>
                <div className="channel-icon" aria-hidden="true">
                  <Icon size={24} strokeWidth={2.2} />
                </div>
                <h3>{channel.title}</h3>
                <p>{channel.text}</p>
                <ExternalLink
                  className="text-link"
                  href={channelLinks[index]}
                  icon={index === 0 ? Globe2 : Icon}
                  newTab={channelLinks[index] !== demoUrl}
                >
                  {channel.cta}
                </ExternalLink>
              </article>
            );
          })}
        </div>
      </section>

      <section className="section export-band">
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
                <Icon aria-hidden="true" size={20} strokeWidth={2.2} />
                {format}
              </span>
            );
          })}
        </div>
      </section>

      <section id="contact" className="section final-section">
        <div>
          <p className="eyebrow">{copy.contact.eyebrow}</p>
          <h2>{copy.contact.title}</h2>
          <p>{copy.contact.text}</p>
        </div>

        <div className="final-actions">
          <ExternalLink className="button primary" href={contactUrl} icon={Globe2}>
            {copy.contact.developer}
          </ExternalLink>
          <ExternalLink className="button secondary dark" href={links.github} icon={FaGithub}>
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
