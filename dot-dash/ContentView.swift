import SwiftUI
import UIKit

// MARK: - Dot Dash (SwiftUI, iOS 16+)

enum AppearancePreference: String, CaseIterable {
    case light
    case dark
    case system

    static let storageKey = "dotdash_appearance_v1"

    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }

    var displayName: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .system: "System"
        }
    }

    var symbolName: String {
        switch self {
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        case .system: "laptopcomputer"
        }
    }

    var next: AppearancePreference {
        switch self {
        case .light: .dark
        case .dark: .system
        case .system: .light
        }
    }
}

struct ContentView: View {
    // Local enum for navigation to game with a chosen mode
    enum ModeSelection: String, Identifiable { case classic, advanced; var id: String { rawValue } }
    @State private var selection: ModeSelection? = nil
    @State private var chosenMode: ModeSelection = .classic
    @AppStorage(AppearancePreference.storageKey) private var appearanceRawValue = AppearancePreference.system.rawValue

    // Best scores are read from UserDefaults in refreshBests() on appear (initial load + returning from GameView).
    @State private var bestClassic: Int = 0
    @State private var bestAdvanced: Int = 0

    private var appearance: AppearancePreference {
        AppearancePreference(rawValue: appearanceRawValue) ?? .system
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                HomeView(
                    chosenMode: $chosenMode,
                    classicBest: bestClassic,
                    advancedBest: bestAdvanced,
                    appearance: appearance,
                    cycleAppearance: { appearanceRawValue = appearance.next.rawValue },
                    start: { selection = chosenMode }
                )
            }
            // Navigate to GameView with the chosen mode
            .navigationDestination(item: $selection) { sel in
                switch sel {
                case .classic:
                    GameView(initialMode: .classic)
                case .advanced:
                    GameView(initialMode: .advanced)
                }
            }
            .onAppear { refreshBests() }
        }
        .preferredColorScheme(appearance.colorScheme)
    }

    private func refreshBests() {
        bestClassic = UserDefaults.standard.integer(forKey: "dotdash_best_classic_v1")
        bestAdvanced = UserDefaults.standard.integer(forKey: "dotdash_best_advanced_v1")
    }

    private struct AppBackground: View {
        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            (colorScheme == .light ? Color.white : Color(red: 0.055, green: 0.059, blue: 0.075))
                .ignoresSafeArea()
        }
    }

    // MARK: - HomeView

    private struct HomeView: View {
        @Binding var chosenMode: ModeSelection
        let classicBest: Int
        let advancedBest: Int
        let appearance: AppearancePreference
        let cycleAppearance: () -> Void
        let start: () -> Void
        @Environment(\.colorScheme) var colorScheme

        private static let cornerButtonSize: CGFloat = 48

        /// The main content view for the Home screen of the app.
        /// Displays the title, best scores, and CTA buttons to start each game mode.
        var body: some View {
            ZStack {
                VStack(spacing: 28) {
                
                
                // Title
                Text("Dot • Dash")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(colorScheme == .light ? .black : .white)
                    .padding(.top, 8)
                
                
                // Toggle button to choose mode
                ModeTogglePill(isClassic: chosenMode == .classic) {
                    chosenMode = chosenMode == .classic ? .advanced : .classic
                }
                .accessibilityIdentifier("home.modePill")
                
                
                // Mode dropdown + single Play button
                VStack(spacing: 24) {
                    
                    ScorePill(title: "Best Score", value: chosenMode == .classic ? classicBest : advancedBest)
                    
                    // Single Play button that respects chosenMode
                    Button {
                        start()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill").imageScale(.large)
                            Text("Play")
                                .font(.title3.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .clipShape(.capsule)
                        .foregroundStyle(Color.white)
                        .glassEffect(.clear)
                    }
                    .accessibilityIdentifier("home.playButton")
                }
                .padding(24)
                .background(RoundedRectangle(cornerRadius: 48).fill(Color(chosenMode == .classic ? "ClassicMode" : "AdvancedMode")))
                
                
                Spacer()
                }
                .padding(24)
                .frame(maxWidth: 600)
                .padding(24)
                
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack {
                    Button(action: cycleAppearance) {
                        Image(systemName: appearance.symbolName)
                            .font(.title2)
                            .frame(width: Self.cornerButtonSize, height: Self.cornerButtonSize)
                    }
                    .accessibilityIdentifier("home.appearanceButton")
                    .accessibilityLabel("Appearance: \(appearance.displayName)")
                    .accessibilityHint("Cycles between Light, Dark, and System appearance")
                    .buttonStyle(.plain)
                    .glassEffect(.clear, in: .circle)

                    Spacer()

                    Menu {
                        Button("Support") {
                            if let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSc363RKRky1eFwkpDa4Eu2jDMwhBiBsOTacm03HsBZbZKctYQ/viewform?usp=dialog") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .accessibilityIdentifier("home.supportAction")
                    } label: {
                        Image(systemName: "questionmark")
                            .font(.title2)
                            .frame(width: Self.cornerButtonSize, height: Self.cornerButtonSize)
                    }
                    .accessibilityIdentifier("home.supportButton")
                    .accessibilityLabel("Help and support")
                    .buttonStyle(.plain)
                    .glassEffect(.clear, in: .circle)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 8)
            }
            .tint(colorScheme == .light ? .black : .white)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// Small score display component used on the Home screen
    private struct ScorePill: View {
        let title: String
        let value: Int
        var body: some View {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.25))
                    .frame(width: 150, height: 150)
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(Color(red: 150/255.0, green: 185/255.0, blue: 216/255.0))
                    Text("\(value)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(title) best score \(value)"))
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDisplayName("Dot Dash – ContentView (Home)")
    }
}
