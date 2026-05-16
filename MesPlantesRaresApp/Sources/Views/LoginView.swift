import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var auth

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 20) {
            // Tabs
            HStack(spacing: 0) {
                Button(action: { withAnimation { isRegistering = false } }) {
                    Text("Connexion")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundColor(!isRegistering ? .green600 : .gray400)
                }
                .background(
                    VStack { Spacer(); Rectangle().frame(height: 2).foregroundColor(!isRegistering ? .green600 : .clear) }
                )

                Button(action: { withAnimation { isRegistering = true } }) {
                    Text("Inscription")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundColor(isRegistering ? .green600 : .gray400)
                }
                .background(
                    VStack { Spacer(); Rectangle().frame(height: 2).foregroundColor(isRegistering ? .green600 : .clear) }
                )
            }
            .padding(.horizontal, 32)

            // Form
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nom d'utilisateur")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray600)
                    TextField("", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                if isRegistering {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray600)
                        TextField("", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Mot de passe")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray600)
                    SecureField("", text: $password)
                        .textFieldStyle(.roundedBorder)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red500)
                        .multilineTextAlignment(.center)
                }

                if showSuccess {
                    Text("✅ Compte créé ! Redirection...")
                        .font(.caption)
                        .foregroundColor(.green600)
                }

                Button(action: submit) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(isRegistering ? "S'inscrire" : "Se connecter")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green600)
                .disabled(isLoading || username.isEmpty || password.isEmpty || (isRegistering && email.isEmpty))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding(.top, 40)
        .navigationTitle("")
    }

    private func submit() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Task {
            let success: Bool
            if isRegistering {
                success = await auth.register(username: username, email: email, password: password)
                if success {
                    showSuccess = true
                    try? await Task.sleep(for: .seconds(1))
                }
            } else {
                success = await auth.login(username: username, password: password)
            }
            isLoading = false
            if !success {
                errorMessage = auth.errorMessage ?? "Erreur"
            }
        }
    }
}
