import { useEffect } from "react";

const REVEAL_SELECTOR = "[data-reveal]";
const GLOW_SELECTOR = "[data-glow]";

function prefersReducedMotion() {
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

/**
 * Fades sections in as they enter the viewport. Elements opt in with
 * `data-reveal`; an optional `data-reveal-delay` staggers siblings.
 */
export function useScrollReveal() {
  useEffect(() => {
    const targets = Array.from(document.querySelectorAll(REVEAL_SELECTOR));

    if (targets.length === 0) {
      return undefined;
    }

    if (prefersReducedMotion()) {
      targets.forEach((target) => target.classList.add("is-visible"));
      return undefined;
    }

    targets.forEach((target) => {
      target.classList.add("reveal");

      if (target.dataset.revealDelay) {
        target.style.setProperty("--reveal-delay", `${target.dataset.revealDelay}ms`);
      }
    });

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -8% 0px" },
    );

    targets.forEach((target) => observer.observe(target));

    return () => observer.disconnect();
  }, []);
}

/**
 * Tracks the pointer over `data-glow` cards and exposes its position as CSS
 * custom properties, which drives the radial sheen in `.glow-card::after`.
 */
export function usePointerGlow() {
  useEffect(() => {
    if (prefersReducedMotion() || !window.matchMedia("(hover: hover)").matches) {
      return undefined;
    }

    const cards = Array.from(document.querySelectorAll(GLOW_SELECTOR));

    if (cards.length === 0) {
      return undefined;
    }

    const handlePointerMove = (event) => {
      const card = event.currentTarget;
      const bounds = card.getBoundingClientRect();

      card.style.setProperty("--pointer-x", `${event.clientX - bounds.left}px`);
      card.style.setProperty("--pointer-y", `${event.clientY - bounds.top}px`);
    };

    cards.forEach((card) => {
      card.classList.add("glow-card");
      card.addEventListener("pointermove", handlePointerMove);
    });

    return () => {
      cards.forEach((card) => card.removeEventListener("pointermove", handlePointerMove));
    };
  }, []);
}
