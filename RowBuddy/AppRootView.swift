import SwiftUI

struct RootView: View {
    @State private var isAuthenticated = false
    @State private var isCheckingAuth = true
    
    var body: some View {
        Group {
            if isCheckingAuth {
                // Loading screen while checking auth
                ZStack {
                    Color.blue.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "figure.rowing")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Row Buddy")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    }
                }
            } else if isAuthenticated {
                // Main app
                WorkoutLibraryView()
            } else {
                // Authentication screen
                AuthenticationView(onAuthenticated: {
                    isAuthenticated = true
                })
            }
        }
        .onAppear {
            checkAuthStatus()
        }
    }
    
    func checkAuthStatus() {
        Task {
            // Check if user is already signed in
            do {
                let user = try await SupabaseManager.shared.getCurrentUser()
                await MainActor.run {
                    isAuthenticated = (user != nil)
                    isCheckingAuth = false
                }
            } catch {
                await MainActor.run {
                    isAuthenticated = false
                    isCheckingAuth = false
                }
            }
        }
    }
}
