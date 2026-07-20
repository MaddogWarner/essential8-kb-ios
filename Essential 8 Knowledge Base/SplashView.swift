//
//  SplashView.swift
//  Essential 8 Knowledge Base
//

import SwiftUI

struct SplashView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showSplashOnStartup: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    // Header Icon & Title
                    VStack(spacing: 12) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .green, .teal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 40)
                            .accessibilityHidden(true)

                        Text("Essential 8")
                            .font(.system(.largeTitle, design: .rounded).bold())
                        Text("Knowledge Base")
                            .font(.system(.title3, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    // App Overview Section
                    Text(AppInformation.aboutDescription)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .foregroundStyle(.secondary)

                    Divider()
                        .padding(.horizontal, 24)

                    // What's New Section Title
                    VStack(alignment: .leading, spacing: 20) {
                        Text("What's New in Version 1.7")
                            .font(.headline)
                            .padding(.horizontal, 8)

                        // Feature list
                        VStack(alignment: .leading, spacing: 24) {
                            featureRow(
                                icon: "person.2",
                                color: .blue,
                                title: "Multiple Profiles",
                                description: "Track separate environments or organisations, each with its own progress, settings and audit history. Turn it on in About."
                            )

                            featureRow(
                                icon: "clock.arrow.circlepath",
                                color: .green,
                                title: "Deep Audit Mode",
                                description: "Record a timestamped history of every status change, with an optional note — the evidence auditors ask for. Turn it on in About."
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }

            // Bottom Actions (Sticky)
            VStack(spacing: 20) {
                Divider()

                // Checkbox for startup showing
                Button {
                    showSplashOnStartup.toggle()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: showSplashOnStartup ? "checkmark.square.fill" : "square")
                            .font(.title2)
                            .foregroundStyle(showSplashOnStartup ? Color.accentColor : Color.secondary)
                        
                        Text("Always show on startup")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Always show on startup")
                .accessibilityValue(showSplashOnStartup ? "Checked" : "Unchecked")

                // Get Started Button
                Button {
                    dismiss()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color(uiColor: .systemBackground))
        }
    }

    private func featureRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32, alignment: .center)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

#Preview {
    SplashView(showSplashOnStartup: .constant(true))
}
