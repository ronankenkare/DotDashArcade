import SwiftUI
import UIKit

// MARK: - Dot Dash (SwiftUI, iOS 16+)

struct ContentView: View {
    // Local enum for navigation to game with a chosen mode
    enum ModeSelection: String, Identifiable { case classic, advanced; var id: String { rawValue } }
    @State private var selection: ModeSelection? = nil
    @State private var chosenMode: ModeSelection = .classic
    @Environment(\.colorScheme) var colorScheme

    // Best scores are read from UserDefaults in refreshBests() on appear (initial load + returning from GameView).
    @State private var bestClassic: Int = 0
    @State private var bestAdvanced: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background adapts to light/dark mode
                (colorScheme == .light ? Color.white : Color(red: 0.055, green: 0.059, blue: 0.075)).ignoresSafeArea()

                HomeView(
                    chosenMode: $chosenMode,
                    classicBest: bestClassic,
                    advancedBest: bestAdvanced,
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
    }

    private func refreshBests() {
        bestClassic = UserDefaults.standard.integer(forKey: "dotdash_best_classic_v1")
        bestAdvanced = UserDefaults.standard.integer(forKey: "dotdash_best_advanced_v1")
    }

    // MARK: - HomeView (unchanged UI, now self-contained in ContentView)

    private struct HomeView: View {
        @Binding var chosenMode: ModeSelection
        let classicBest: Int
        let advancedBest: Int
        let start: () -> Void
        @State private var showMenu: Bool = false
        @Environment(\.colorScheme) var colorScheme

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
                
                // Background overlay to dismiss menu when tapping outside
                if showMenu {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showMenu = false
                            }
                        }
                }
                
                // Question mark button and menu overlay in bottom right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack(alignment: .bottomTrailing) {
                            // Dropdown menu
                            if showMenu {
                                VStack(alignment: .trailing, spacing: 8) {
                                    Button(action: {
                                        if let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSc363RKRky1eFwkpDa4Eu2jDMwhBiBsOTacm03HsBZbZKctYQ/viewform?usp=dialog") {
                                            UIApplication.shared.open(url)
                                        }
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            showMenu = false
                                        }
                                    }) {
                                        Text("Support")
                                            .font(.body.weight(.medium))
                                            .foregroundColor(colorScheme == .light ? .black : .white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .glassEffect(.clear)
                                            .clipShape(.rect(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.bottom, 60)
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Question mark button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showMenu.toggle()
                                }
                            }) {
                                Image(systemName: "questionmark")
                                    .font(.title2)
                                    .foregroundColor(colorScheme == .light ? .black : .white)
                                    .padding(12)
                                    .glassEffect(.clear)
                                    .clipShape(.circle)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.bottom, 22)
                        .padding(.trailing, 22)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            }
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
