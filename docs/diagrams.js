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

    const preview = document.querySelector("#state-preview-panel");
    const layout = document.querySelector("#state-diagram-layout");
    const sidePanelToggle = document.querySelector("#state-side-panel-toggle");
    const annotationsToggle = document.querySelector("#state-annotations-toggle");
    if (!preview || !layout || !sidePanelToggle || !annotationsToggle) return;
    const annotationsOption = annotationsToggle.closest(".state-view-option");

    const controls = Array.from(document.querySelectorAll("[data-state-preview]"));
    const stateNodes = new Map();
    let activeStateName = null;

    const syncPanelHeight = () => {
      if (preview.parentNode !== layout) return;
      const diagramHeight = Math.ceil(stage.getBoundingClientRect().height);
      if (diagramHeight <= 0) return;
      preview.style.height = `${diagramHeight}px`;
      preview.style.maxHeight = `${diagramHeight}px`;
    };

    controls.forEach((button) => button.setAttribute("aria-pressed", "false"));

    const setPressedState = (stateName) => {
      controls.forEach((button) => {
        button.setAttribute("aria-pressed", String(button.dataset.statePreview === stateName));
      });
    };

    const setHighlightedState = (stateName) => {
      stateNodes.forEach((nodes, name) => {
        nodes.forEach((node) => node.classList.toggle("is-preview-active", name === stateName));
      });
    };

    const showPanelPrompt = () => {
      const prompt = document.createElement("div");
      prompt.className = "state-preview-prompt";
      const title = document.createElement("strong");
      title.textContent = "Hover over a game state";
      const instructions = document.createElement("p");
      instructions.textContent = "Move over a named state in the diagram to see the matching app screen here. You can also use the preview buttons below.";
      prompt.append(title, instructions);
      preview.classList.add("is-empty");
      preview.replaceChildren(prompt);
    };

    const showPreview = (stateName) => {
      const state = states[stateName];
      if (!state || !sidePanelToggle.checked) return;
      activeStateName = stateName;

      const header = document.createElement("header");
      header.className = "state-preview-header";
      const kicker = document.createElement("span");
      kicker.className = "state-preview-kicker";
      kicker.textContent = "Actual app state";
      const title = document.createElement("strong");
      title.className = "state-preview-title";
      title.textContent = state.title;
      const description = document.createElement("p");
      description.className = "state-preview-description";
      description.textContent = state.description;
      header.append(kicker, title, description);

      const media = document.createElement("div");
      media.className = "state-preview-media";
      const image = document.createElement("img");
      image.src = state.image;
      image.alt = state.alt;
      media.append(image);

      if (annotationsToggle.checked) {
        const pins = document.createElement("div");
        pins.className = "state-preview-pins";
        pins.setAttribute("aria-hidden", "true");
        pins.replaceChildren(...state.pins.map((pin) => {
          const marker = document.createElement("span");
          marker.className = "state-preview-pin";
          marker.textContent = pin.label;
          Object.entries(pin).forEach(([property, value]) => {
            if (property !== "label") marker.style[property] = value;
          });
          return marker;
        }));
        media.append(pins);
      }

      const source = document.createElement("p");
      source.className = "state-preview-source";
      source.textContent = "iPhone 17 Pro simulator capture · iOS 27";
      preview.classList.remove("is-empty");
      preview.replaceChildren(header, media, source);
      setPressedState(stateName);
      setHighlightedState(stateName);
    };

    const syncSidePanel = () => {
      const enabled = sidePanelToggle.checked;
      preview.hidden = !enabled;
      if (annotationsOption) annotationsOption.hidden = !enabled;
      layout.classList.toggle("has-side-panel", enabled && preview.parentNode === layout);
      if (!enabled) {
        activeStateName = null;
        preview.classList.remove("is-empty");
        preview.replaceChildren();
        setPressedState("");
        setHighlightedState("");
      } else if (!activeStateName) {
        showPanelPrompt();
      }
      document.dispatchEvent(new CustomEvent("statepanelchange", { detail: { enabled } }));
      if (enabled) window.requestAnimationFrame(syncPanelHeight);
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
      const nodes = findStateNodes(stateName);
      stateNodes.set(stateName, nodes);
      nodes.forEach((node) => {
        node.classList.add("state-preview-target");
        node.addEventListener("pointerenter", () => showPreview(stateName));
        node.addEventListener("click", () => showPreview(stateName));
      });
    });

    controls.forEach((button) => {
      button.addEventListener("pointerenter", () => showPreview(button.dataset.statePreview));
      button.addEventListener("focus", () => showPreview(button.dataset.statePreview));
      button.addEventListener("click", () => showPreview(button.dataset.statePreview));
    });

    sidePanelToggle.addEventListener("change", syncSidePanel);
    annotationsToggle.addEventListener("change", () => {
      if (activeStateName) showPreview(activeStateName);
    });
    if (typeof ResizeObserver !== "undefined") {
      const diagramObserver = new ResizeObserver(syncPanelHeight);
      diagramObserver.observe(stage);
    }
    document.addEventListener("statepanelrestored", () => {
      window.requestAnimationFrame(syncPanelHeight);
    });
    syncSidePanel();
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
        <div class="diagram-dialog-content">
          <div class="diagram-viewport" role="region" aria-label="Pannable and zoomable diagram">
            <div class="diagram-canvas"></div>
          </div>
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
    const toolbar = dialog.querySelector(".diagram-toolbar");
    const content = dialog.querySelector(".diagram-dialog-content");
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
    let previewNextSibling = null;
    let optionsHome = null;
    let optionsNextSibling = null;
    let activeStage = null;

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
      const statePreview = content.querySelector(".state-preview-panel");
      if (statePreview && previewHome) {
        if (previewNextSibling && previewNextSibling.parentNode === previewHome) {
          previewHome.insertBefore(statePreview, previewNextSibling);
        } else {
          previewHome.append(statePreview);
        }
        statePreview.classList.remove("is-expanded");
        previewHome.classList.toggle("has-side-panel", !statePreview.hidden);
        document.dispatchEvent(new CustomEvent("statepanelrestored"));
      }
      content.classList.remove("has-state-panel");
      previewHome = null;
      previewNextSibling = null;
      const stateOptions = toolbar.querySelector(".state-view-options");
      if (stateOptions && optionsHome) {
        if (optionsNextSibling && optionsNextSibling.parentNode === optionsHome) {
          optionsHome.insertBefore(stateOptions, optionsNextSibling);
        } else {
          optionsHome.append(stateOptions);
        }
        stateOptions.classList.remove("is-expanded");
      }
      optionsHome = null;
      optionsNextSibling = null;
      activeStage = null;
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
      activeStage = stage;
      canvas.replaceChildren(svg);
      const statePreview = document.querySelector("#state-preview-panel");
      if (stage.id === "game-state-diagram" && statePreview) {
        const stateOptions = document.querySelector(".state-view-options");
        if (stateOptions) {
          optionsHome = stateOptions.parentNode;
          optionsNextSibling = stateOptions.nextSibling;
          stateOptions.classList.add("is-expanded");
          toolbar.append(stateOptions);
        }
        previewHome = statePreview.parentNode;
        previewNextSibling = statePreview.nextSibling;
        previewHome.classList.remove("has-side-panel");
        statePreview.classList.add("is-expanded");
        statePreview.style.removeProperty("height");
        statePreview.style.removeProperty("max-height");
        content.append(statePreview);
        content.classList.toggle("has-state-panel", !statePreview.hidden);
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

    document.addEventListener("statepanelchange", (event) => {
      if (!dialog.open || activeStage?.id !== "game-state-diagram") return;
      content.classList.toggle("has-state-panel", Boolean(event.detail?.enabled));
    });

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
