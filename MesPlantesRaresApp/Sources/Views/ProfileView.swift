import SwiftUI

struct ProfileView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.green600)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(auth.currentUser?.username ?? "Utilisateur")
                            .font(.headline)
                            .foregroundColor(.green800)
                        Text(auth.currentUser?.email ?? "")
                            .font(.caption)
                            .foregroundColor(.gray500)
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                Button(role: .destructive) {
                    auth.logout()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Se déconnecter")
                    }
                }
            }
        }
        .navigationTitle("Profil")
    }
}
