//
//  OnboardingView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 26/07/25.
//

import SwiftUI

/// Onboarding Cart
struct OnboardingCard: Identifiable {
    var id: String = UUID().uuidString
    var symbol: String
    var title: String
    var subTitle: String
}

/// Onboarding card result builder
@resultBuilder
struct OnboardingCardResultBuilder {
    static func buildBlock(_ components: OnboardingCard...) -> [OnboardingCard] {
        components.compactMap{ $0 }
    }
}

struct OnboardingView: View {
    var tint: Color
    var onContinue: () -> ()
    
    init(tint: Color, onContinue: @escaping () -> Void) {
        self.tint = tint
        self.onContinue = onContinue
        
        // Setup the animateCards property to match with the number of cards
        self._animateCards = .init(initialValue: Array(repeating: false, count: self.cards.count))
    }
    
    // View properties
    @State private var animateIcon: Bool = false
    @State private var animateTitle: Bool = false
    @State private var animateCards: [Bool]
    @State private var animateFooter: Bool = false
    
    @State private var showPrivacyPolicy: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    Image("PresentationIcon")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(.rect(cornerRadius: 22))
                        .padding(.trailing, 15)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)
                        .blurSlide(animateIcon)
                    
                    Text("Welcome to Digipin Manager")
                        .font(.title2.bold())
                        .blurSlide(animateTitle)
                    
                    CardsBuilder()
                }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            
            VStack(spacing: 0, content: {
                Text("By using Digipin Manager, you agree to")
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 15)
                Text("Privacy Policy")
                    .font(.footnote)
                    .foregroundStyle(Color.accentColor)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 15)
                    .onTapGesture {
                        showPrivacyPolicy = true
                    }
                
                // Continue btn
                Button(action: onContinue) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
#if os(macOS)
                        .padding(.vertical, 8)
#else
                        .padding(.vertical, 4)
#endif
                }
                .tint(tint)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            })
            .blurSlide(animateFooter)
        }
        // Limiting the width
        .frame(maxWidth: 330)
        // Disable interactive dismiss
        .interactiveDismissDisabled()
        // Disabling interation until footer is animated
        .allowsHitTesting(animateFooter)
        .task {
            guard !animateIcon else { return }
            
            await delayedAnimation(0.35) {
                animateIcon = true
            }
            
            await delayedAnimation(0.2) {
                animateTitle = true
            }
            
            try? await Task.sleep(for: .seconds(0.2))
            
            for index in animateCards.indices {
                let delay = Double(index) * 0.1
                await delayedAnimation(delay) {
                    animateCards[index] = true
                }
            }
            
            await delayedAnimation(0.2) {
                animateFooter = true
            }
        }
        .presentationCornerRadius(45)
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyViewBuilder()
        }
    }
    
    @ViewBuilder
    private func CardsBuilder() -> some View {
        Group {
            ForEach(cards.indices, id: \.self) { index in
                let card = cards[index]
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: card.symbol)
                        .font(.title2)
                        .foregroundStyle(tint)
                        .frame(width: 45)
                        .offset(y: 10)
                    
                    VStack(alignment: .leading) {
                        Text(card.title)
                            .font(.title3)
                            .lineLimit(1)
                        
                        Text(card.subTitle)
                            .lineLimit(2)
                    }
                }
                .blurSlide(animateCards[index])
            }
        }
    }
    
    @ViewBuilder
    private func PrivacyPolicyViewBuilder() -> some View {
        NavigationView {
            PrivacyPolicyView()
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Done") {
                            showPrivacyPolicy = false
                        }
                    }
                }
        }
    }
    
    private func delayedAnimation(_ delay: Double, action: @escaping () -> ()) async {
        try? await Task.sleep(for: .seconds(delay))
        
        withAnimation(.smooth) {
            action()
        }
    }
    
    
    // Constants
    let cards: [OnboardingCard] = [
        OnboardingCard(
            symbol: "pin",
            title: "Pinned list",
            subTitle: "Pin your commonly used digipins."
        ),
        
        OnboardingCard(
            symbol: "magnifyingglass",
            title: "Search DIGIPIN",
            subTitle: "Search for digipins and get results on map."
        ),
        
        OnboardingCard(
            symbol: "map",
            title: "Interactive Map",
            subTitle: "Interactive map to get digipin of any location."
        ),
    ]
}

#Preview {
    @Previewable @State var showOnboarding: Bool = false
    List {
        Button("Show Onboarding") {
            showOnboarding = true
        }
    }
    .sheet(isPresented: $showOnboarding) {
        OnboardingView(tint: .accentColor) {
            showOnboarding = false
        }
    }
}
