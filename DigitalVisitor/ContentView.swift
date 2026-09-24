
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.95, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 25) {

                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 55))
                                .foregroundStyle(.white)
                                .frame(width: 100, height: 100)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color.blue,
                                            Color.indigo
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 28)
                                )

                            Text("Digital Visitor")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)

                            Text("Management System")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)

                            Text("Smart • Secure • Connected")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 35)

                        // Role selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Welcome!")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Select your role to continue")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            NavigationLink {
                                RoleDashboard(role: "Security")
                            } label: {
                                RoleCard(
                                    title: "Security",
                                    subtitle: "Verify identities and manage entry",
                                    icon: "shield.checkered",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                RoleDashboard(role: "Teacher")
                            } label: {
                                RoleCard(
                                    title: "Teacher",
                                    subtitle: "Create and manage appointments",
                                    icon: "person.crop.rectangle",
                                    color: .purple
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                RoleDashboard(role: "Visitor")
                            } label: {
                                RoleCard(
                                    title: "Visitor",
                                    subtitle: "Register and receive a digital pass",
                                    icon: "person.badge.plus",
                                    color: .green
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(22)
                        .background(.white)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 24)
                        )
                        .padding(.horizontal)

                        // Technology information
                        VStack(spacing: 8) {
                            Label(
                                "Machine Learning Based Verification",
                                systemImage: "brain.head.profile"
                            )
                            .font(.subheadline)
                            .fontWeight(.medium)

                            Text("Apple Ecosystem • SwiftUI")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("Prototype Version 1.0")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Role Card

struct RoleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 25))
                .foregroundStyle(color)
                .frame(width: 55, height: 55)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        }
    }
}

// MARK: - Role Dashboard

struct RoleDashboard: View {
    let role: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 65))
                .foregroundStyle(.blue)

            Text("\(role) Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Welcome to the Digital Visitor Management System")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Text("Your \(role.lowercased()) workspace is ready.")
                .font(.subheadline)

            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.95, green: 0.97, blue: 1.0))
        .navigationTitle(role)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
