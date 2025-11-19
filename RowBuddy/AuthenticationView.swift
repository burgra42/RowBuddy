import SwiftUI

struct AuthenticationView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var onAuthenticated: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Logo/Title
                    VStack(spacing: 10) {
                        Image(systemName: "figure.rowing")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("Row Buddy")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Your Rowing Training Companion")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Auth Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("", text: $email)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            SecureField("", text: $password)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .textContentType(isSignUp ? .newPassword : .password)
                        }
                        
                        if isSignUp {
                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // Sign In/Up Button
                        Button(action: handleAuth) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isSignUp ? "Sign Up" : "Sign In")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(10)
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        
                        // Toggle Sign Up/Sign In
                        Button(action: {
                            isSignUp.toggle()
                            errorMessage = nil
                        }) {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .underline()
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    func handleAuth() {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        // Basic validation
        if isSignUp && password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if isSignUp {
                    try await SupabaseManager.shared.signUp(email: email, password: password)
                    // After sign up, automatically sign in
                    try await SupabaseManager.shared.signIn(email: email, password: password)
                } else {
                    try await SupabaseManager.shared.signIn(email: email, password: password)
                }
                
                // Success!
                await MainActor.run {
                    isLoading = false
                    onAuthenticated()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
