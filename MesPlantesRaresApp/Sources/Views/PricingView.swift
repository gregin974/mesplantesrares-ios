import SwiftUI

// Simple placeholder for Pricing (mirrors PWA page)
struct PricingView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Tarifs")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green800)
                    Text("Gratuit pour 10 plantes · Sans engagement")
                        .font(.subheadline)
                        .foregroundColor(.gray500)
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    Text("💰")
                        .font(.system(size: 48))
                    Text("Gratuit pour commencer")
                        .font(.headline)
                    Text("Jusqu'à 10 plantes dans votre collection, fonctionnalités de base incluses.")
                        .font(.subheadline)
                        .foregroundColor(.gray600)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Tarifs")
    }
}

// Simple placeholder for About
struct AboutView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("🌿")
                        .font(.system(size: 48))
                    Text("Mes Plantes Rares")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green800)
                    Text("Votre collection de plantes rares")
                        .font(.subheadline)
                        .foregroundColor(.gray500)
                }
                .padding(.top, 32)

                if !auth.isAuthenticated {
                    NavigationLink("Se connecter", destination: LoginView())
                        .buttonStyle(.borderedProminent)
                        .tint(.green600)
                }
            }
        }
        .navigationTitle("À propos")
    }
}
