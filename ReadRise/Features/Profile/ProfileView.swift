import Kingfisher
import SwiftUI

struct ProfileView: View {
    @Environment(AuthService.self) private var auth
    @State private var displayName = ""
    @State private var avatarUrl: String?
    @State private var isSaving = false
    @State private var isLoading = true
    @State private var showSignOutConfirm = false
    @State private var errorMessage: String?
    @State private var showSaveSuccess = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Group {
                            if let urlStr = avatarUrl, let url = URL(string: urlStr) {
                                KFImage(url)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Color.rrAmber)
                            }
                        }
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
                        .onSubmit { Task { await saveName() } }
                        .accessibilityIdentifier("profile.nameField")
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
                    .foregroundStyle(Color.rrAmber)
                    .accessibilityIdentifier("profile.saveName")
                }

                Section {
                    Link("Manage subscription at readrise.app", destination: URL(string: "https://readrise.app/billing")!)
                        .foregroundStyle(Color.rrAmber)
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
                    .accessibilityIdentifier("profile.signOut")
                }

                if let err = errorMessage {
                    Section {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Profile")
            .task { await loadProfile() }
            .safeAreaInset(edge: .top) {
                if showSaveSuccess {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Name saved")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.rrAmber)
                    .clipShape(Capsule())
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
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
            avatarUrl = resp.data.avatarUrl
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
            withAnimation { showSaveSuccess = true }
            try? await Task.sleep(for: .seconds(2))
            withAnimation { showSaveSuccess = false }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
