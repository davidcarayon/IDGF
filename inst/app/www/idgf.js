// IDGF – animations et interactions de l'interface
// Apparition au défilement, compteurs, particules de diatomées, parallaxe,
// halo sur les cartes, navigation par boutons, dépôt de fichier, copie de citation.
(function () {
  "use strict";

  const reduit = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // ── Diatomées dessinées en SVG (pennée et centrique) ─────────────────────
  function svgPennee() {
    let stries = "";
    for (let y = -34; y <= 34; y += 4.5) {
      const d = 9.5 * Math.sqrt(Math.max(0, 1 - (y / 40) ** 2));
      stries += `<line x1="${-d}" y1="${y}" x2="-2.2" y2="${y}"/><line x1="2.2" y1="${y}" x2="${d}" y2="${y}"/>`;
    }
    return `<svg class="idgf-diatomee" viewBox="-16 -46 32 92"><ellipse cx="0" cy="0" rx="12" ry="42" class="valve"/>` +
      `<g class="stries">${stries}</g><line x1="0" y1="-36" x2="0" y2="36" class="raphe"/>` +
      `<circle cx="0" cy="0" r="2.4" class="nodule"/></svg>`;
  }
  function svgCentrique() {
    let rayons = "";
    for (let a = 0; a < 360; a += 15) {
      const r = a * Math.PI / 180;
      rayons += `<line x1="${14 * Math.cos(r)}" y1="${14 * Math.sin(r)}" x2="${34 * Math.cos(r)}" y2="${34 * Math.sin(r)}"/>`;
    }
    return `<svg class="idgf-diatomee" viewBox="-42 -42 84 84"><circle cx="0" cy="0" r="38" class="valve"/>` +
      `<g class="stries">${rayons}</g><circle cx="0" cy="0" r="11" class="anneau"/></svg>`;
  }

  function semerParticules(racine) {
    racine.querySelectorAll(".idgf-diatomees:not([data-seme])").forEach(function (zone) {
      zone.setAttribute("data-seme", "1");
      if (reduit) return;
      const n = parseInt(zone.getAttribute("data-particules") || "12", 10);
      for (let i = 0; i < n; i++) {
        const p = document.createElement("span");
        const pennee = Math.random() < 0.6;
        const taille = pennee ? 14 + Math.random() * 22 : 22 + Math.random() * 34;
        p.className = "particule";
        p.innerHTML = pennee ? svgPennee() : svgCentrique();
        p.style.left = (Math.random() * 100) + "%";
        p.style.width = taille + "px";
        p.style.setProperty("--duree", (16 + Math.random() * 22) + "s");
        p.style.setProperty("--delai", (-Math.random() * 30) + "s");
        p.style.setProperty("--rot", (10 + Math.random() * 20) + "s");
        p.style.setProperty("--balancement", ((Math.random() - 0.5) * 140) + "px");
        p.style.setProperty("--opacite", (0.25 + Math.random() * 0.45).toFixed(2));
        zone.appendChild(p);
      }
    });
  }

  // ── Compteurs animés ─────────────────────────────────────────────────────
  function compter(el) {
    if (el.dataset.compte === undefined || el.dataset.fait) return;
    el.dataset.fait = "1";
    const cible = parseFloat(el.dataset.compte);
    const dec = parseInt(el.dataset.decimales || "0", 10);
    const fmt = new Intl.NumberFormat("fr-FR", { minimumFractionDigits: dec, maximumFractionDigits: dec });
    if (reduit || isNaN(cible)) { el.textContent = fmt.format(cible); return; }
    const duree = 1600, debut = performance.now();
    function pas(t) {
      const k = Math.min(1, (t - debut) / duree);
      const e = 1 - Math.pow(1 - k, 4);
      el.textContent = fmt.format(cible * e);
      if (k < 1) requestAnimationFrame(pas);
    }
    requestAnimationFrame(pas);
  }

  // ── Apparition au défilement ─────────────────────────────────────────────
  const observateur = new IntersectionObserver(function (entrees) {
    entrees.forEach(function (e) {
      if (!e.isIntersecting) return;
      e.target.classList.add("visible");
      e.target.querySelectorAll("[data-compte]").forEach(compter);
      observateur.unobserve(e.target);
    });
  }, { threshold: 0.12 });

  function observer(racine) {
    racine.querySelectorAll(".reveal:not([data-observe])").forEach(function (el) {
      el.setAttribute("data-observe", "1");
      // Décalage en cascade entre éléments voisins
      const freres = Array.from(el.parentElement ? el.parentElement.children : []).filter(x => x.classList.contains("reveal"));
      el.style.setProperty("--retard", (Math.max(0, freres.indexOf(el)) * 90) + "ms");
      observateur.observe(el);
    });
    // Compteurs hors .reveal (tuiles de résultats)
    racine.querySelectorAll(".idgf-tuile [data-compte]").forEach(compter);
  }

  // ── Halo qui suit la souris ──────────────────────────────────────────────
  document.addEventListener("pointermove", function (ev) {
    const carte = ev.target.closest && ev.target.closest(".carte-lumiere");
    if (carte) {
      const r = carte.getBoundingClientRect();
      carte.style.setProperty("--x", (ev.clientX - r.left) + "px");
      carte.style.setProperty("--y", (ev.clientY - r.top) + "px");
    }
    const hero = ev.target.closest && ev.target.closest(".idgf-hero");
    if (hero && !reduit) {
      const r = hero.getBoundingClientRect();
      hero.style.setProperty("--mx", (((ev.clientX - r.left) / r.width) - 0.5).toFixed(3));
      hero.style.setProperty("--my", (((ev.clientY - r.top) / r.height) - 0.5).toFixed(3));
    }
  }, { passive: true });

  // ── Boutons de navigation entre onglets (data-goto) ──────────────────────
  document.addEventListener("click", function (ev) {
    const lien = ev.target.closest && ev.target.closest("[data-goto]");
    if (lien) {
      ev.preventDefault();
      const onglet = document.querySelector('.navbar a[data-value="' + lien.dataset.goto + '"]');
      if (onglet) {
        onglet.click();
        window.scrollTo({ top: 0, behavior: reduit ? "auto" : "smooth" });
      }
      return;
    }
    // Copie d'une citation
    const copier = ev.target.closest && ev.target.closest(".idgf-copier");
    if (copier) {
      const texte = copier.parentElement.querySelector(".idgf-citation-texte").textContent;
      navigator.clipboard.writeText(texte).then(function () {
        copier.classList.add("copie");
        setTimeout(function () { copier.classList.remove("copie"); }, 1600);
      });
    }
  });

  // ── Zone de dépôt : glisser-déposer sur toute la carte ───────────────────
  function brancherDepot(racine) {
    racine.querySelectorAll(".idgf-depot:not([data-branche])").forEach(function (zone) {
      zone.setAttribute("data-branche", "1");
      const champ = zone.querySelector('input[type="file"]');
      ["dragenter", "dragover"].forEach(function (t) {
        zone.addEventListener(t, function (e) { e.preventDefault(); zone.classList.add("survol"); });
      });
      ["dragleave", "drop"].forEach(function (t) {
        zone.addEventListener(t, function (e) { e.preventDefault(); zone.classList.remove("survol"); });
      });
      zone.addEventListener("drop", function (e) {
        if (!champ || !e.dataTransfer.files.length) return;
        champ.files = e.dataTransfer.files;
        champ.dispatchEvent(new Event("change", { bubbles: true }));
      });
    });
  }

  function initialiser(racine) {
    semerParticules(racine);
    observer(racine);
    brancherDepot(racine);
  }

  document.addEventListener("DOMContentLoaded", function () { initialiser(document); });

  // Contenu rendu par Shiny (renderUI) : on initialise ce qui vient d'arriver
  if (window.jQuery) {
    jQuery(document).on("shiny:value", function (e) {
      setTimeout(function () {
        const cible = document.getElementById(e.target.id);
        if (cible) initialiser(cible);
      }, 30);
    });
  }
})();
