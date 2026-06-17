(function () {
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function revealSections() {
    const nodes = Array.from(document.querySelectorAll(".reveal"));
    if (reduceMotion || !("IntersectionObserver" in window)) {
      nodes.forEach((node) => node.classList.add("is-visible"));
      return;
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.18, rootMargin: "0px 0px -10% 0px" }
    );

    nodes.forEach((node) => observer.observe(node));
  }

  function animateCounters() {
    const counters = Array.from(document.querySelectorAll("[data-count]"));
    if (counters.length === 0) return;

    const runCounter = (node) => {
      const target = Number(node.getAttribute("data-count")) || 0;
      const started = node.dataset.started === "true";
      if (started) return;
      node.dataset.started = "true";

      if (reduceMotion) {
        node.textContent = String(target);
        return;
      }

      const start = performance.now();
      const duration = 900;

      function tick(now) {
        const progress = Math.min((now - start) / duration, 1);
        const eased = 1 - Math.pow(1 - progress, 3);
        node.textContent = String(Math.round(target * eased));
        if (progress < 1) {
          requestAnimationFrame(tick);
        }
      }

      requestAnimationFrame(tick);
    };

    if (!("IntersectionObserver" in window) || reduceMotion) {
      counters.forEach(runCounter);
      return;
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            runCounter(entry.target);
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.55 }
    );

    counters.forEach((counter) => observer.observe(counter));
  }

  function enableTilt() {
    if (reduceMotion) return;

    document.querySelectorAll("[data-tilt]").forEach((node) => {
      const maxAngle = 5;

      node.addEventListener("pointermove", (event) => {
        const rect = node.getBoundingClientRect();
        const x = (event.clientX - rect.left) / rect.width - 0.5;
        const y = (event.clientY - rect.top) / rect.height - 0.5;
        const rotateY = x * maxAngle * 2;
        const rotateX = y * maxAngle * -2;
        node.style.transform = `perspective(1200px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-2px)`;
      });

      node.addEventListener("pointerleave", function () {
        this.style.transform = "";
      });
    });
  }

  revealSections();
  animateCounters();
  enableTilt();
})();
