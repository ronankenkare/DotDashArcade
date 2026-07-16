(() => {
  const dark = window.matchMedia("(prefers-color-scheme: dark)").matches;
  const palette = dark
    ? {
        background: "#0e0f13",
        surface: "#24262d",
        surfaceAlt: "#172f49",
        surfaceWarn: "#46201f",
        text: "#f9fafb",
        muted: "#a7b0c0",
        line: "#6f7787",
        classic: "#459af7",
        advanced: "#ff5a50"
      }
    : {
        background: "#ffffff",
        surface: "#f1f3f6",
        surfaceAlt: "#e5f1ff",
        surfaceWarn: "#ffeae8",
        text: "#0f172a",
        muted: "#596579",
        line: "#7b8493",
        classic: "#247fd9",
        advanced: "#d92d25"
      };

  if (typeof mermaid === "undefined") {
    window.addEventListener("DOMContentLoaded", () => {
      document.querySelectorAll(".mermaid").forEach((diagram) => {
        diagram.classList.add("diagram-error");
      });
    });
    return;
  }

  mermaid.initialize({
    startOnLoad: false,
    securityLevel: "strict",
    theme: "base",
    themeVariables: {
      background: palette.background,
      primaryColor: palette.surfaceAlt,
      primaryTextColor: palette.text,
      primaryBorderColor: palette.classic,
      secondaryColor: palette.surface,
      secondaryTextColor: palette.text,
      secondaryBorderColor: palette.line,
      tertiaryColor: palette.surfaceWarn,
      tertiaryTextColor: palette.text,
      tertiaryBorderColor: palette.advanced,
      lineColor: palette.line,
      textColor: palette.text,
      mainBkg: palette.surface,
      nodeBorder: palette.line,
      clusterBkg: palette.background,
      clusterBorder: palette.line,
      edgeLabelBackground: palette.background,
      actorBkg: palette.surface,
      actorBorder: palette.line,
      actorTextColor: palette.text,
      actorLineColor: palette.line,
      signalColor: palette.classic,
      signalTextColor: palette.text,
      labelBoxBkgColor: palette.surface,
      labelBoxBorderColor: palette.line,
      labelTextColor: palette.text,
      loopTextColor: palette.text,
      noteBkgColor: palette.surfaceAlt,
      noteBorderColor: palette.classic,
      noteTextColor: palette.text,
      fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Rounded", system-ui, sans-serif',
      fontSize: "15px"
    },
    flowchart: {
      curve: "basis",
      htmlLabels: true,
      useMaxWidth: true,
      nodeSpacing: 38,
      rankSpacing: 48
    },
    sequence: {
      useMaxWidth: true,
      mirrorActors: false,
      messageAlign: "center",
      diagramMarginX: 12,
      diagramMarginY: 12,
      actorMargin: 30,
      width: 150,
      height: 52,
      boxMargin: 10,
      noteMargin: 12,
      messageMargin: 28
    },
    state: {
      useMaxWidth: true
    }
  });

  const initializeStatePreviews = () => {
    const stage = document.querySelector("#game-state-diagram");
    if (!stage) return;

    const states = {
      Home: {
        title: "Home · Choose a mode",
        description: "The run has not started. The player selects Classic or Advanced, then presses Play.",
        image: "assets/game-states/home.png",
        alt: "Dot Dash home screen with Classic mode selected and the Play button visible.",
        pins: [
          { label: "Choose the run mode", top: "21%", left: "5%" },
          { label: "Play enters Ready", top: "57%", right: "4%" }
        ]
      },
      Ready: {
        title: "Ready · Instructions shown",
        description: "Gameplay is paused behind the help overlay until the player explicitly starts the run.",
        image: "assets/game-states/ready.png",
        alt: "Dot Dash instructions overlay with a Start button above the game board.",
        pins: [
          { label: "running = false", top: "26%", left: "4%" },
          { label: "Start calls reset()", top: "61%", right: "4%" }
        ]
      },
      Running: {
        title: "Running · Frame updates active",
        description: "The display link advances the marker every frame while the target zone waits for a tap.",
        image: "assets/game-states/running.png",
        alt: "Active Dot Dash game board showing score zero, a moving marker, and a blue target zone.",
        pins: [
          { label: "Current score", top: "12%", left: "3%" },
          { label: "Marker advances each frame", top: "39%", left: "3%" },
          { label: "Target zone", top: "34%", right: "5%" }
        ]
      },
      TapDecision: {
        title: "Tap decision · Position evaluated",
        description: "This is a logic-only state: the current marker position is tested against the perfect and good hit regions.",
        image: "assets/game-states/running.png",
        alt: "Dot Dash game board at the instant a tap is evaluated against the target zone.",
        pins: [
          { label: "Tap samples this marker position", top: "39%", left: "3%" },
          { label: "Compared with this target", top: "34%", right: "5%" }
        ]
      },
      PerfectHit: {
        title: "Perfect hit · Strong feedback",
        description: "The score increments, green particles confirm the hit, and progression prepares the next target.",
        image: "assets/game-states/hit.png",
        alt: "Dot Dash game board immediately after a hit, showing score one and green feedback particles.",
        pins: [
          { label: "Score increments", top: "12%", left: "3%" },
          { label: "Hit feedback particles", top: "31%", left: "3%" },
          { label: "Target relocates", top: "41%", right: "4%" }
        ]
      },
      GoodHit: {
        title: "Good hit · Normal feedback",
        description: "The same visible success feedback appears, with a smaller speed increase than a perfect hit.",
        image: "assets/game-states/hit.png",
        alt: "Dot Dash game board immediately after a successful hit with green feedback particles.",
        pins: [
          { label: "Score increments", top: "12%", left: "3%" },
          { label: "Normal hit feedback", top: "31%", left: "3%" },
          { label: "Next target", top: "41%", right: "4%" }
        ]
      },
      Progression: {
        title: "Progression · Next challenge prepared",
        description: "Speed, target size, target position, and theme are updated before control returns to Running.",
        image: "assets/game-states/hit.png",
        alt: "Dot Dash board after progression has moved the target and increased the score.",
        pins: [
          { label: "New score", top: "12%", left: "3%" },
          { label: "Feedback marks the transition", top: "31%", left: "3%" },
          { label: "Resized + relocated target", top: "41%", right: "4%" }
        ]
      },
      GameOver: {
        title: "Game over · Result saved",
        description: "A miss stops frame-driven play, saves the mode-specific best, and presents the replay choice.",
        image: "assets/game-states/game-over.png",
        alt: "Dot Dash game-over overlay showing score one, best one, and a Play Again button.",
        pins: [
          { label: "Run stopped + best saved", top: "13%", left: "3%" },
          { label: "Miss feedback", top: "31%", right: "2%" },
          { label: "Play Again calls reset()", top: "55%", left: "18%" }
        ]
      }
    };

    const preview = document.createElement("aside");
    preview.className = "state-preview";
    preview.hidden = true;
    preview.setAttribute("aria-live", "polite");
    preview.innerHTML = `
      <header class="state-preview-header">
        <div>
          <span class="state-preview-kicker">Actual app state</span>
          <strong class="state-preview-title"></strong>
        </div>
        <button class="state-preview-close" type="button" aria-label="Close app-state preview">×</button>
        <p class="state-preview-description"></p>
      </header>
      <div class="state-preview-media">
        <img alt="">
        <div class="state-preview-pins" aria-hidden="true"></div>
      </div>
      <p class="state-preview-source">iPhone 17 Pro simulator capture · iOS 27</p>
    `;
    document.body.append(preview);

    const previewTitle = preview.querySelector(".state-preview-title");
    const previewDescription = preview.querySelector(".state-preview-description");
    const previewImage = preview.querySelector("img");
    const previewPins = preview.querySelector(".state-preview-pins");
    const closeButton = preview.querySelector(".state-preview-close");
    const controls = Array.from(document.querySelectorAll("[data-state-preview]"));
    let locked = false;
    let hideTimer = null;

    controls.forEach((button) => button.setAttribute("aria-pressed", "false"));

    const setPressedState = (stateName) => {
      controls.forEach((button) => {
        button.setAttribute("aria-pressed", String(button.dataset.statePreview === stateName && locked));
      });
    };

    const showPreview = (stateName, shouldLock = false) => {
      const state = states[stateName];
      if (!state) return;
      window.clearTimeout(hideTimer);
      locked = shouldLock;
      previewTitle.textContent = state.title;
      previewDescription.textContent = state.description;
      previewImage.src = state.image;
      previewImage.alt = state.alt;
      previewPins.replaceChildren(...state.pins.map((pin) => {
        const marker = document.createElement("span");
        marker.className = "state-preview-pin";
        marker.textContent = pin.label;
        Object.entries(pin).forEach(([property, value]) => {
          if (property !== "label") marker.style[property] = value;
        });
        return marker;
      }));
      preview.hidden = false;
      window.requestAnimationFrame(() => preview.classList.add("is-visible"));
      setPressedState(stateName);
    };

    const hidePreview = (force = false) => {
      if (locked && !force) return;
      locked = false;
      preview.classList.remove("is-visible");
      setPressedState("");
      window.clearTimeout(hideTimer);
      hideTimer = window.setTimeout(() => {
        if (!preview.classList.contains("is-visible")) preview.hidden = true;
      }, 160);
    };

    const scheduleHide = () => {
      window.clearTimeout(hideTimer);
      hideTimer = window.setTimeout(() => hidePreview(), 120);
    };

    const findStateNodes = (stateName) => {
      const groups = Array.from(stage.querySelectorAll("svg g[id], svg g.node"));
      return groups.filter((group) => {
        const identifier = group.id || "";
        const text = group.textContent?.replace(/\s+/g, " ").trim() || "";
        return identifier.includes(`state-${stateName}-`) || identifier === stateName || text === stateName;
      });
    };

    Object.keys(states).forEach((stateName) => {
      findStateNodes(stateName).forEach((node) => {
        node.classList.add("state-preview-target");
        node.addEventListener("pointerenter", () => showPreview(stateName));
        node.addEventListener("pointerleave", scheduleHide);
        node.addEventListener("click", () => showPreview(stateName, true));
      });
    });

    controls.forEach((button) => {
      button.addEventListener("pointerenter", () => showPreview(button.dataset.statePreview));
      button.addEventListener("pointerleave", scheduleHide);
      button.addEventListener("focus", () => showPreview(button.dataset.statePreview));
      button.addEventListener("blur", scheduleHide);
      button.addEventListener("click", () => showPreview(button.dataset.statePreview, true));
    });

    preview.addEventListener("pointerenter", () => window.clearTimeout(hideTimer));
    preview.addEventListener("pointerleave", scheduleHide);
    closeButton.addEventListener("click", () => hidePreview(true));
    document.addEventListener("diagramviewerclose", () => hidePreview(true));
  };

  const initializeDiagramViewer = () => {
    const stages = Array.from(document.querySelectorAll(".mermaid-stage"));
    if (stages.length === 0) return;

    const dialog = document.createElement("dialog");
    dialog.className = "diagram-dialog";
    dialog.setAttribute("aria-labelledby", "diagram-dialog-title");
    dialog.innerHTML = `
      <div class="diagram-dialog-shell">
        <header class="diagram-dialog-header">
          <div>
            <span class="diagram-dialog-kicker">Expanded system view</span>
            <h2 id="diagram-dialog-title">System diagram</h2>
          </div>
          <button class="diagram-button diagram-close" type="button">Close</button>
        </header>
        <div class="diagram-toolbar">
          <span>Drag or use arrow keys to pan · Scroll to zoom</span>
          <div class="diagram-toolbar-controls" aria-label="Diagram zoom controls">
            <button class="diagram-button diagram-zoom-out" type="button" aria-label="Zoom out">−</button>
            <output class="diagram-zoom-value" aria-live="polite">100%</output>
            <button class="diagram-button diagram-zoom-in" type="button" aria-label="Zoom in">+</button>
            <button class="diagram-button diagram-reset" type="button">Reset</button>
          </div>
        </div>
        <div class="diagram-viewport" role="region" aria-label="Pannable and zoomable diagram">
          <div class="diagram-canvas"></div>
        </div>
      </div>
    `;
    document.body.append(dialog);

    const title = dialog.querySelector("#diagram-dialog-title");
    const closeButton = dialog.querySelector(".diagram-close");
    const zoomOutButton = dialog.querySelector(".diagram-zoom-out");
    const zoomInButton = dialog.querySelector(".diagram-zoom-in");
    const resetButton = dialog.querySelector(".diagram-reset");
    const zoomValue = dialog.querySelector(".diagram-zoom-value");
    const viewport = dialog.querySelector(".diagram-viewport");
    const canvas = dialog.querySelector(".diagram-canvas");

    let sourceParent = null;
    let sourceNextSibling = null;
    let activeSvg = null;
    let scale = 1;
    let offsetX = 0;
    let offsetY = 0;
    let dragging = false;
    let pointerX = 0;
    let pointerY = 0;
    let previewHome = null;

    const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

    const applyTransform = () => {
      canvas.style.transform = `translate(${offsetX}px, ${offsetY}px) scale(${scale})`;
      zoomValue.textContent = `${Math.round(scale * 100)}%`;
    };

    const resetView = () => {
      scale = 1;
      offsetX = 0;
      offsetY = 0;
      applyTransform();
    };

    const zoomBy = (amount) => {
      scale = clamp(scale + amount, 0.5, 3);
      applyTransform();
    };

    const restoreDiagram = () => {
      document.dispatchEvent(new CustomEvent("diagramviewerclose"));
      const statePreview = dialog.querySelector(".state-preview");
      if (statePreview && previewHome) previewHome.append(statePreview);
      previewHome = null;
      if (!activeSvg || !sourceParent) return;
      if (sourceNextSibling && sourceNextSibling.parentNode === sourceParent) {
        sourceParent.insertBefore(activeSvg, sourceNextSibling);
      } else {
        sourceParent.append(activeSvg);
      }
      activeSvg = null;
      sourceParent = null;
      sourceNextSibling = null;
      canvas.replaceChildren();
      resetView();
    };

    const openDiagram = (stage) => {
      const svg = stage.querySelector("svg");
      if (!svg) return;

      const section = stage.closest("section");
      const pageHeading = section?.querySelector("h2")?.textContent?.trim();
      title.textContent = pageHeading || "System diagram";

      sourceParent = svg.parentNode;
      sourceNextSibling = svg.nextSibling;
      activeSvg = svg;
      canvas.replaceChildren(svg);
      const statePreview = document.querySelector(".state-preview");
      if (stage.id === "game-state-diagram" && statePreview) {
        previewHome = statePreview.parentNode;
        dialog.append(statePreview);
      }
      resetView();
      dialog.showModal();
    };

    stages.forEach((stage) => {
      if (!stage.querySelector("svg")) return;
      const row = document.createElement("div");
      row.className = "diagram-expand-row";
      const button = document.createElement("button");
      button.className = "diagram-button";
      button.type = "button";
      button.textContent = "Expand diagram ↗";
      button.addEventListener("click", () => openDiagram(stage));
      row.append(button);
      stage.prepend(row);
    });

    closeButton.addEventListener("click", () => dialog.close());
    zoomOutButton.addEventListener("click", () => zoomBy(-0.2));
    zoomInButton.addEventListener("click", () => zoomBy(0.2));
    resetButton.addEventListener("click", resetView);

    dialog.addEventListener("click", (event) => {
      if (event.target === dialog) dialog.close();
    });

    dialog.addEventListener("close", restoreDiagram);

    viewport.addEventListener("wheel", (event) => {
      event.preventDefault();
      zoomBy(event.deltaY < 0 ? 0.12 : -0.12);
    }, { passive: false });

    viewport.addEventListener("pointerdown", (event) => {
      if (event.button !== 0) return;
      dragging = true;
      pointerX = event.clientX;
      pointerY = event.clientY;
      viewport.classList.add("is-dragging");
      viewport.setPointerCapture(event.pointerId);
    });

    viewport.addEventListener("pointermove", (event) => {
      if (!dragging) return;
      offsetX += event.clientX - pointerX;
      offsetY += event.clientY - pointerY;
      pointerX = event.clientX;
      pointerY = event.clientY;
      applyTransform();
    });

    const stopDragging = (event) => {
      if (!dragging) return;
      dragging = false;
      viewport.classList.remove("is-dragging");
      if (viewport.hasPointerCapture(event.pointerId)) {
        viewport.releasePointerCapture(event.pointerId);
      }
    };

    viewport.addEventListener("pointerup", stopDragging);
    viewport.addEventListener("pointercancel", stopDragging);

    document.addEventListener("keydown", (event) => {
      if (!dialog.open) return;
      const step = event.shiftKey ? 60 : 24;
      if (event.key === "ArrowLeft") offsetX -= step;
      else if (event.key === "ArrowRight") offsetX += step;
      else if (event.key === "ArrowUp") offsetY -= step;
      else if (event.key === "ArrowDown") offsetY += step;
      else return;
      event.preventDefault();
      applyTransform();
    });
  };

  window.addEventListener("DOMContentLoaded", async () => {
    try {
      await mermaid.run({ querySelector: ".mermaid" });
      initializeStatePreviews();
      initializeDiagramViewer();
    } catch (error) {
      document.querySelectorAll(".mermaid").forEach((diagram) => {
        diagram.classList.add("diagram-error");
      });
      console.error("Dot Dash diagram rendering failed", error);
    }
  });
})();
