import { useCallback, useEffect, useRef } from "react";

export function useLandingVideoPreviews() {
  const previewVideoRef = useRef(null);
  const trailerVideoRef = useRef(null);
  const visibleVideosRef = useRef(new Set());

  const pauseInlineVideos = useCallback(() => {
    [previewVideoRef.current, trailerVideoRef.current].forEach((video) => {
      video?.pause();
    });
  }, []);

  const playInlineVideo = useCallback((video) => {
    if (!video || document.hidden) {
      return;
    }

    video.defaultMuted = true;
    video.muted = true;
    video.loop = true;
    video.playsInline = true;

    if (video.paused) {
      video.play().catch(() => {});
    }
  }, []);

  useEffect(() => {
    const inlineVideos = [previewVideoRef.current, trailerVideoRef.current].filter(Boolean);

    if (inlineVideos.length === 0) {
      return undefined;
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          const video = entry.target;

          if (entry.intersectionRatio >= 0.9) {
            visibleVideosRef.current.add(video);
            playInlineVideo(video);
          } else {
            visibleVideosRef.current.delete(video);
            video.pause();
          }
        });
      },
      { threshold: [0, 0.9] },
    );

    const handleCanPlay = (event) => {
      const video = event.currentTarget;
      if (visibleVideosRef.current.has(video)) {
        playInlineVideo(video);
      }
    };

    inlineVideos.forEach((video) => {
      video.defaultMuted = true;
      video.muted = true;
      video.loop = true;
      video.playsInline = true;
      video.addEventListener("canplay", handleCanPlay);
      observer.observe(video);
    });

    const handleVisibilityChange = () => {
      if (document.hidden) {
        pauseInlineVideos();
        return;
      }

      visibleVideosRef.current.forEach((video) => playInlineVideo(video));
    };

    document.addEventListener("visibilitychange", handleVisibilityChange);

    return () => {
      observer.disconnect();
      inlineVideos.forEach((video) => {
        video.removeEventListener("canplay", handleCanPlay);
      });
      document.removeEventListener("visibilitychange", handleVisibilityChange);
      visibleVideosRef.current.clear();
      pauseInlineVideos();
    };
  }, [pauseInlineVideos, playInlineVideo]);

  return {
    previewVideoRef,
    trailerVideoRef,
  };
}
