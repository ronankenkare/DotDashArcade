//
//  GameView.swift
//  dot-dash
//
//  Created by Ronan Kenkare on 8/8/25.
//


import SwiftUI
import UIKit
import Combine

// MARK: - GameView (Game screen only)

struct GameView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var game = GameState()

    /// Initialize the game with a starting mode
    init(initialMode: GameState.Mode) {
        _game = StateObject(wrappedValue: GameState())
        _initialMode = State(initialValue: initialMode)
    }

    @State private var initialMode: GameState.Mode

    var body: some View {
        ZStack {
            // Background adapts to light/dark mode
            (colorScheme == .light ? Color.white : game.theme.bg).ignoresSafeArea()

            VStack {
                ScoreBarView(game: game, colorScheme: colorScheme)
                    .padding(.top, 20)
                Spacer()
            }

            GameBarView(game: game, colorScheme: colorScheme)
            HelpOverlayView(game: game, colorScheme: colorScheme)
            ModeBadgeView(game: game)
        }
        .onAppear {
            game.changeMode(initialMode)
            game.running = false
            game.showHelp = true
            game.startLoop()
        }
        .onDisappear { game.stopLoop() }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active: game.startLoop()
            case .inactive, .background:
                game.pauseToHelp()
                game.stopLoop()
            @unknown default: break
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Dot • Dash")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(colorScheme == .light ? .black : .white)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared UI

/// Capsule-style "Mode: Classic/Advanced" pill used on both the Home screen and
/// during gameplay. Callers own the action (toggle behavior differs per screen)
/// but the visual styling is unified here.
struct ModeTogglePill: View {
    let isClassic: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3").imageScale(.medium)
                Text("Mode: \(isClassic ? "Classic" : "Advanced")")
                    .font(.title3.weight(.semibold))
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 24)
            .glassEffect(.clear)
            .clipShape(.capsule)
            .contentShape(.capsule)
            .foregroundStyle(colorScheme == .light ? Color.black : Color(isClassic ? "ClassicMode" : "AdvancedMode"))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Game subviews and model moved here from ContentView.swift

/// Main interactive game bar
private struct GameBarView: View {
    @ObservedObject var game: GameState
    let colorScheme: ColorScheme
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Canvas { ctx, size in
                    let W = size.width
                    let H = size.height
                    let padX = W * 0.1
                    let barX = padX
                    let barW = W - padX * 2
                    let barY = H * 0.4
                    // Removed flash overlay
                    let barRect = CGRect(x: barX, y: barY - 10, width: barW, height: 20)
                    let barColor = colorScheme == .light ? Color.gray.opacity(0.3) : game.theme.bar
                    ctx.fill(RoundedRectangle(cornerRadius: 12).path(in: barRect),
                             with: .color(barColor))
                    let half = barW * game.zoneWidth / 2
                    let zx = barX + (game.zoneCenter * barW) - half
                    let zw = barW * game.zoneWidth
                    let zoneRect = CGRect(
                        x: max(zx, barX),
                        y: barY - 12,
                        width: min(zw, barX + barW - max(zx, barX)),
                        height: 24
                    )
                    let zoneColor = (game.mode == .classic) ? Color("ClassicMode") : Color("AdvancedMode")
                    ctx.fill(RoundedRectangle(cornerRadius: 14).path(in: zoneRect),
                             with: .color(zoneColor.opacity(0.85)))
                    let innerRect = zoneRect.insetBy(dx: 4, dy: 4)
                    ctx.fill(RoundedRectangle(cornerRadius: 10).path(in: innerRect),
                             with: .color(.white.opacity(0.07)))
                    let mx = barX + (game.markerPos * barW)
                    let marker = Path(ellipseIn: CGRect(x: mx - 12, y: barY - 12, width: 24, height: 24))
                    let markerColor = colorScheme == .light ? Color.black : Color(red: 0.98, green: 0.98, blue: 0.98)
                    ctx.fill(marker, with: .color(markerColor))
                    for p in game.particles {
                        let dot = Path(ellipseIn: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5))
                        ctx.fill(dot, with: .color((p.good ? game.theme.good : game.theme.bad).opacity(p.alpha)))
                    }
                }
                .contentShape(Rectangle())
                Color.clear
                    .contentShape(Rectangle())
                    .onAppear { game.cachedBarY = geo.size.height * 0.4 }
                    .onChange(of: geo.size.height) { _, h in game.cachedBarY = h * 0.4 }
                    .onTapGesture { game.handleTap(screenWidth: geo.size.width) }
            }
        }
    }
}

/// Help overlay
private struct HelpOverlayView: View {
    @ObservedObject var game: GameState
    let colorScheme: ColorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    var body: some View {
        if game.showHelp {
            VStack(alignment: .center, spacing: 16) {
                Text(game.gameOver ? "Game Over" : "How To Play")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(colorScheme == .light ? Color.black : Color.white)
                if game.gameOver {
                    HStack (alignment: .center, spacing: 10) {
                        VStack (alignment: .trailing) {
                            Text("Game Mode: ")
                            Text("Your Score: ")
                            Text("Best Score: ")
                        }
                        VStack (alignment: .leading) {
                            Text("\(game.mode.title)")
                            Text("\(game.score)")
                            Text("\(game.bestCurrent)")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.secondary)
                } else {
                    VStack (alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "smallcircle.filled.circle")
                                .foregroundStyle(Color("ClassicMode"))
                                .frame(width: 16, height: 16)
                                .padding(.horizontal, 8)
                            Text("Tap the screen when the dot is inside the highlighted target")
                        }
                        HStack {
                            Image(systemName: "dot.scope")
                                .foregroundStyle(Color.gray)
                                .frame(width: 16, height: 16)
                                .padding(.horizontal, 8)
                            Text("Hit the target area to score a point")
                        }
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.red)
                                .frame(width: 16, height: 16)
                                .padding(.horizontal, 8)
                            Text("Miss the target and it's Game Over")
                        }
                    }
                    .multilineTextAlignment(.leading)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                }
                Button(action: { game.reset() }) {
                    Text(game.gameOver ? "Play Again" : "Start")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        // Dark halo when Increase Contrast is on — the mode-color
                        // background is a fixed asset, so the text needs its own
                        // contrast boost rather than relying on the backdrop.
                        .shadow(color: contrast == .increased ? Color.black.opacity(0.55) : .clear,
                                radius: 1, x: 0, y: 1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(game.mode == .classic ? "ClassicMode" : "AdvancedMode"))
                        .clipShape(.rect(cornerRadius: 12))
                        .contentShape(Rectangle())
                        .glassEffect(.clear)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("game.startButton")
            }
            .padding(16)
            .frame(maxWidth: 480)
            .glassEffect(.regular, in: .rect(cornerRadius: 28))
            .padding(16)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("game.helpOverlay")
        }
    }
}

/// Mode badge + toggle button
private struct ModeBadgeView: View {
    @ObservedObject var game: GameState
    var body: some View {
        VStack {
            Spacer()
            ModeTogglePill(isClassic: game.mode == .classic) {
                let newMode: GameState.Mode = game.mode == .classic ? .advanced : .classic
                game.changeMode(newMode)
            }
            .accessibilityIdentifier("game.modePill")
        }
    }
}

/// Score bar at the top
private struct ScoreBarView: View {
    @ObservedObject var game: GameState
    let colorScheme: ColorScheme
    var body: some View {
        HStack {
            Text("SCORE: \(game.score)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .accessibilityIdentifier("game.scoreLabel")
            Spacer()
            Text("BEST: \(game.bestCurrent)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .accessibilityIdentifier("game.bestLabel")
        }
        .padding(.horizontal, 12)
        .foregroundColor(colorScheme == .light ? .black.opacity(0.95) : .white.opacity(0.95))
        .shadow(color: colorScheme == .light ? .clear : .black.opacity(0.6), radius: 6, x: 0, y: 2)
        .allowsHitTesting(false)
    }
}

// MARK: - GameState model (moved from ContentView.swift)

@MainActor
final class GameState: ObservableObject {
    enum Mode { case classic, advanced; var title: String { self == .classic ? "Classic" : "Advanced" } }

    struct ModeSettings {
        let startZoneWidth: CGFloat
        let startSpeed: CGFloat
        let perfectZoneFrac: CGFloat
        let speedMulPerfect: CGFloat
        let speedMulGood: CGFloat
        let zoneShrinkPerfect: CGFloat
        let zoneShrinkGood: CGFloat
        let minZoneWidth: CGFloat
    }

    // Output
    @Published var mode: Mode = .classic
    @Published var score: Int = 0
    @Published var bestClassic: Int = UserDefaults.standard.integer(forKey: "dotdash_best_classic_v1")
    @Published var bestAdvanced: Int = UserDefaults.standard.integer(forKey: "dotdash_best_advanced_v1")
    var bestCurrent: Int { mode == .classic ? bestClassic : bestAdvanced }
    @Published var showHelp: Bool = true
    @Published var gameOver: Bool = false
    @Published var flash: CGFloat = 0

    // World
    @Published var markerPos: CGFloat = 0.5   // 0..1
    var markerDir: CGFloat = 1
    @Published var zoneCenter: CGFloat = 0.5  // 0..1
    @Published var zoneWidth: CGFloat = 0.32  // fraction of bar
    var perfectZoneFrac: CGFloat = 0.35
    var speed: CGFloat = 0.65                 // units per second
    var running: Bool = false
    var themeIdx: Int = 0
    var cachedBarY: CGFloat = 0               // non-published on purpose

    // Particles
    struct Particle {
        var x: CGFloat; var y: CGFloat
        var vx: CGFloat; var vy: CGFloat
        var life: CGFloat; var age: CGFloat
        var good: Bool
        var alpha: CGFloat { max(0, 1 - age / life) }
        var alive: Bool { alpha > 0 }
    }
    @Published var particles: [Particle] = []

    // Timing
    private var link: CADisplayLink?
    private var lastTs: CFTimeInterval = CACurrentMediaTime()

    // Haptics
    private let successHap = UINotificationFeedbackGenerator()
    private let impactHap = UIImpactFeedbackGenerator(style: .rigid)

    // Themes
    struct Theme { let bg: Color; let bar: Color; let zone: Color; let mark: Color; let good: Color; let bad: Color }
    private let themes: [Theme] = [
        .init(bg: Color(red: 0.055, green: 0.059, blue: 0.075),
              bar: Color(red: 0.121, green: 0.161, blue: 0.215),
              zone: Color(red: 0.38, green: 0.65, blue: 0.98),
              mark: Color(red: 0.898, green: 0.905, blue: 0.922),
              good: Color(red: 0.133, green: 0.773, blue: 0.369),
              bad:  Color(red: 0.937, green: 0.267, blue: 0.267)),
        .init(bg: Color(red: 0.043, green: 0.055, blue: 0.071),
              bar: Color(red: 0.121, green: 0.161, blue: 0.215),
              zone: Color(red: 0.96, green: 0.62, blue: 0.043),
              mark: Color(red: 0.99, green: 0.90, blue: 0.54),
              good: Color(red: 0.52, green: 0.80, blue: 0.09),
              bad:  Color(red: 0.96, green: 0.25, blue: 0.37)),
        .init(bg: Color(red: 0.043, green: 0.043, blue: 0.067),
              bar: Color(red: 0.153, green: 0.153, blue: 0.165),
              zone: Color(red: 0.66, green: 0.55, blue: 0.98),
              mark: Color(red: 0.98, green: 0.98, blue: 0.98),
              good: Color(red: 0.20, green: 0.83, blue: 0.61),
              bad:  Color(red: 0.98, green: 0.44, blue: 0.52)),
        .init(bg: Color(red: 0.02, green: 0.04, blue: 0.04),
              bar: Color(red: 0.06, green: 0.09, blue: 0.165),
              zone: Color(red: 0.20, green: 0.82, blue: 0.61),
              mark: Color(red: 0.97, green: 0.98, blue: 1.00),
              good: Color(red: 0.13, green: 0.83, blue: 0.93),
              bad:  Color(red: 0.98, green: 0.45, blue: 0.09))
    ]
    var theme: Theme { themes[max(0, min(themeIdx, themes.count - 1))] }

    // MARK: - Lifecycle

    init() {
        successHap.prepare(); impactHap.prepare()
        // Migrate legacy single-best (if present) to Classic
        let legacy = UserDefaults.standard.integer(forKey: "dotdash_best_v1")
        if legacy > 0 && UserDefaults.standard.integer(forKey: "dotdash_best_classic_v1") == 0 {
            bestClassic = legacy
            UserDefaults.standard.set(legacy, forKey: "dotdash_best_classic_v1")
        }
    }
    deinit { link?.invalidate() }

    func startLoop() {
        guard link == nil else { return }
        lastTs = CACurrentMediaTime()
        let l = CADisplayLink(target: self, selector: #selector(step))
        l.add(to: .main, forMode: .common)
        link = l
    }

    func stopLoop() {
        guard let l = link else { return }
        l.invalidate(); link = nil
    }

    func reset() {
        running = true
        gameOver = false
        showHelp = false
        score = 0
        let s = currentSettings()
        speed = s.startSpeed
        markerPos = CGFloat.random(in: 0...1)
        markerDir = Bool.random() ? 1 : -1
        zoneCenter = 0.5
        zoneWidth = s.startZoneWidth
        perfectZoneFrac = s.perfectZoneFrac
        particles.removeAll()
        flash = 0
        themeIdx = 0 // ensure theme resets each run
    }

    func pauseToHelp() {
        if running { running = false; showHelp = true; gameOver = false }
    }

    // MARK: - Loop

    @objc private func step(_ link: CADisplayLink) {
        let now = link.timestamp
        var dt = now - lastTs
        lastTs = now
        dt = min(dt, 0.05)

        // Fade flash
        if flash > 0 { flash = max(0, flash - CGFloat(dt) * 1.6) }

        guard running else { updateParticles(CGFloat(dt)); return }

        // Move marker
        (markerPos, markerDir) = Self.advanceMarker(pos: markerPos, dir: markerDir, speed: speed, dt: CGFloat(dt))

        updateParticles(CGFloat(dt))
    }

    /// Pure marker movement + edge bounce. Extracted from step(_:) for testability.
    nonisolated static func advanceMarker(pos: CGFloat, dir: CGFloat, speed: CGFloat, dt: CGFloat) -> (pos: CGFloat, dir: CGFloat) {
        var pos = pos
        var dir = dir
        pos += dir * speed * dt
        if pos >= 1 { pos = 1; dir = -1 }
        if pos <= 0 { pos = 0; dir = 1 }
        return (pos, dir)
    }

    func updateParticles(_ dt: CGFloat) {
        for i in particles.indices {
            particles[i].age += dt
            particles[i].x += particles[i].vx
            particles[i].y += particles[i].vy
        }
        particles.removeAll(where: { !$0.alive })
    }

    // MARK: - Input

    func handleTap(screenWidth: CGFloat) {
        guard running else { reset(); return }
        if inZone(markerPos) {
            let wasPerfect = inPerfect(markerPos)
            score += 1
            // Feedback
            flash = min(1, flash + (wasPerfect ? 0.5 : 0.35))
            successHap.notificationOccurred(wasPerfect ? .success : .warning)
            impactHap.impactOccurred(intensity: wasPerfect ? 1.0 : 0.6)
            successHap.prepare(); impactHap.prepare()
            // Particles
            spawnBurst(at: CGPoint(x: markerScreenX(screenWidth: screenWidth), y: cachedBarY), good: true)
            // Difficulty (mode-aware)
            let s = currentSettings()
            speed *= wasPerfect ? s.speedMulPerfect : s.speedMulGood
            zoneWidth = clamp(zoneWidth * (wasPerfect ? s.zoneShrinkPerfect : s.zoneShrinkGood), s.minZoneWidth, 0.5)
            // Move zone with guaranteed minimum movement
            zoneCenter = pickNewZoneCenter(prevCenter: zoneCenter, zoneWidth: zoneWidth)
            // Theme progression
            themeIdx = pickThemeIndex(for: score)
        } else {
            // Miss -> game over
            spawnBurst(at: CGPoint(x: markerScreenX(screenWidth: screenWidth), y: cachedBarY), good: false)
            running = false
            gameOver = true
            if mode == .classic {
                bestClassic = max(bestClassic, score)
                UserDefaults.standard.set(bestClassic, forKey: "dotdash_best_classic_v1")
            } else {
                bestAdvanced = max(bestAdvanced, score)
                UserDefaults.standard.set(bestAdvanced, forKey: "dotdash_best_advanced_v1")
            }
            showHelp = true
        }
    }

    func currentSettings() -> ModeSettings {
        switch mode {
        case .classic:
            return ModeSettings(
                startZoneWidth: 0.36,
                startSpeed: 0.55,
                perfectZoneFrac: 0.45,
                speedMulPerfect: 1.10,
                speedMulGood: 1.05,
                zoneShrinkPerfect: 1.0,
                zoneShrinkGood: 1.0,
                minZoneWidth: 0.10
            )
        case .advanced:
            return ModeSettings(
                startZoneWidth: 0.26,
                startSpeed: 0.80,
                perfectZoneFrac: 0.30,
                speedMulPerfect: 1.15,
                speedMulGood: 1.10,
                zoneShrinkPerfect: 0.90,
                zoneShrinkGood: 0.94,
                minZoneWidth: 0.06
            )
        }
    }

    func changeMode(_ newMode: Mode) {
        guard mode != newMode else { return }
        
        // Pause the game if it's running
        let wasRunning = running
        if wasRunning {
            running = false
        }
        
        // Update mode first so reset() uses the new mode's settings
        mode = newMode
        
        // Reset game state with new mode settings
        score = 0
        let s = currentSettings()
        speed = s.startSpeed
        markerPos = CGFloat.random(in: 0...1)
        markerDir = Bool.random() ? 1 : -1
        zoneCenter = 0.5
        zoneWidth = s.startZoneWidth
        perfectZoneFrac = s.perfectZoneFrac
        particles.removeAll()
        flash = 0
        themeIdx = 0
        
        // Reset UI state - pause and show help
        running = false
        showHelp = true
        gameOver = false
    }

    // MARK: - Helpers

    func inZone(_ pos: CGFloat) -> Bool {
        let half = zoneWidth / 2
        return pos >= (zoneCenter - half) && pos <= (zoneCenter + half)
    }

    func inPerfect(_ pos: CGFloat) -> Bool {
        let half = zoneWidth / 2
        let inner = half * perfectZoneFrac
        return pos >= (zoneCenter - inner) && pos <= (zoneCenter + inner)
    }

    private func clamp<T: Comparable>(_ v: T, _ lo: T, _ hi: T) -> T { min(max(v, lo), hi) }

    func pickThemeIndex(for score: Int) -> Int {
        if score >= 40 { return 3 }
        if score >= 25 { return 2 }
        if score >= 12 { return 1 }
        return 0
    }

    private func markerScreenX(screenWidth: CGFloat) -> CGFloat {
        let W = screenWidth
        let padX = W * 0.1
        let barW = W - padX * 2
        return padX + markerPos * barW
    }

    private func spawnBurst(at p: CGPoint, good: Bool) {
        let N = 18
        var newParts: [Particle] = []
        for i in 0..<N {
            let base = CGFloat(i) / CGFloat(N) * .pi * 2
            let a = base + CGFloat.random(in: 0...0.2)
            let s = good ? (2 + CGFloat.random(in: 0...3)) : (1 + CGFloat.random(in: 0...2))
            newParts.append(Particle(
                x: p.x, y: p.y,
                vx: cos(a) * s, vy: sin(a) * s,
                life: 0.6 + CGFloat.random(in: 0...0.4),
                age: 0,
                good: good
            ))
        }
        particles.append(contentsOf: newParts)
    }

    func pickNewZoneCenter(prevCenter: CGFloat, zoneWidth: CGFloat) -> CGFloat {
        let minEdge: CGFloat = 0.15
        let maxEdge: CGFloat = 0.85
        // Minimum movement scales with zone size but never below 0.08
        let minMove = max(0.08, min(0.22, zoneWidth * 0.9 + 0.06))
        // Rejection sample for a candidate that moves at least `minMove` from the
        // previous center. Capped at 16 tries so we never block the game loop —
        // if the constraint is unsatisfiable (e.g. prevCenter near an edge with a
        // large minMove) we accept the last candidate and let the player feel the
        // smaller jump rather than stall the frame.
        var tries = 0
        var candidate = prevCenter
        while tries < 16 && abs(candidate - prevCenter) < minMove {
            candidate = .random(in: minEdge...maxEdge)
            tries += 1
        }
        return clamp(candidate, minEdge, maxEdge)
    }
}

// MARK: - Preview

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GameView(initialMode: .classic)
        }
        .previewDisplayName("Dot Dash – GameView")
    }
}
