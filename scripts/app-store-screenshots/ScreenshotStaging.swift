// App Store screenshot staging. Copied into dot-dash/ by
// scripts/capture-app-store-screenshots.sh for a Debug build and removed
// afterward; it is never part of the shipped app.
#if DEBUG
import SwiftUI
import UIKit

enum ScreenshotStaging {
    /// Set with the `-screenshotScene <name>` launch argument.
    static var scene: String? { UserDefaults.standard.string(forKey: "screenshotScene") }

    static var modeToOpen: GameState.Mode? {
        guard let s = scene else { return nil }
        return s.hasPrefix("advanced") ? .advanced : .classic
    }

    /// Width of the safe-area region the game bar is laid out in.
    static var gameAreaWidth: CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        guard let window else { return 400 }
        return window.bounds.width - window.safeAreaInsets.left - window.safeAreaInsets.right
    }
}

extension GameState {
    func applyScreenshotScene() {
        guard let scene = ScreenshotStaging.scene, scene != "help" else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [self] in
            stopLoop()
            showHelp = false
            running = false
            particles.removeAll()
            switch scene {
            case "hit":
                score = 9; themeIdx = 0
                zoneCenter = 0.62; zoneWidth = 0.36; markerPos = 0.64
                burst(good: true)
            case "theme40":
                score = 42; themeIdx = 3
                zoneCenter = 0.30; zoneWidth = 0.36; markerPos = 0.27
                burst(good: true)
            case "advanced":
                score = 18; themeIdx = 1
                zoneCenter = 0.71; zoneWidth = 0.11; markerPos = 0.42
            case "gameover":
                score = 31; themeIdx = 2
                zoneCenter = 0.66; zoneWidth = 0.36; markerPos = 0.22
                gameOver = true; showHelp = true
            default: break
            }
        }
    }

    private func burst(good: Bool) {
        let w = ScreenshotStaging.gameAreaWidth
        let x = w * 0.1 + markerPos * w * 0.8
        for i in 0..<18 {
            let a = CGFloat(i) / 18 * .pi * 2 + CGFloat.random(in: 0...0.2)
            let s = good ? (2 + CGFloat.random(in: 0...3)) : (1 + CGFloat.random(in: 0...2))
            particles.append(Particle(x: x, y: cachedBarY, vx: cos(a) * s, vy: sin(a) * s,
                                      life: 0.6 + CGFloat.random(in: 0...0.4), age: 0, good: good))
        }
        updateParticles(0.14)
        // Freeze the burst so a restarted display link can't fade it out.
        for i in particles.indices { particles[i].vx = 0; particles[i].vy = 0; particles[i].life = 1_000_000 }
    }
}
#endif
