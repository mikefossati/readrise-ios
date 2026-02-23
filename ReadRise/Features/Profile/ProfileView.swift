import SwiftUI

struct ProfileView: View {
    @Environment(AuthService.self) private var auth
    @State private var displayName = ""
    @State private var isSaving = false
    @State private var isLoading = true
    @State private var showSignOutConfirm = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(hex: "#e8923a"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName.isEmpty ? "Reader" : displayName)
                                .font(.headline)
                            Text("ReadRise member")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Display name") {
                    TextField("Your name", text: $displayName)
                    Button {
                        Task { await saveName() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(isSaving || displayName.isEmpty)
                    .foregroundStyle(Color(hex: "#e8923a"))
                }

                Section {
                    Link("Manage subscription at readrise.app", destination: URL(string: "https://readrise.app/billing")!)
                        .foregroundStyle(Color(hex: "#e8923a"))
                }

                Section {
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign out")
                        }
                    }
                }

                if let err = errorMessage {
                    Section {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .task { await loadProfile() }
            .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Sign out", role: .destructive) {
                    Task { await auth.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func loadProfile() async {
        isLoading = true
        do {
            let resp: APIResponse<UserProfile> = try await APIClient.shared.get("/api/user/profile")
            displayName = resp.data.displayName ?? ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func saveName() async {
        isSaving = true
        errorMessage = nil
        do {
            struct NameBody: Encodable { let displayName: String }
            let _: APIResponse<UserProfile> = try await APIClient.shared.patch(
                "/api/user/profile",
                body: NameBody(displayName: displayName)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
