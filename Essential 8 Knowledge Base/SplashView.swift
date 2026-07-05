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
                        Text("What's New in Version 1.5")
                            .font(.headline)
                            .padding(.horizontal, 8)

                        // Feature list
                        VStack(alignment: .leading, spacing: 24) {
                            featureRow(
                                icon: "checkmark.seal",
                                color: .green,
                                title: "Technical Content Corrections",
                                description: "AppLocker deny paths, Office macro policy targets and Edge hardening guidance corrected and re-verified against Microsoft documentation."
                            )

                            featureRow(
                                icon: "target",
                                color: .indigo,
                                title: "Target Maturity Level",
                                description: "Set your organisation's target (ML1–ML3) and measure dashboard compliance against it instead of everything."
                            )

                            featureRow(
                                icon: "number",
                                color: .teal,
                                title: "ISM Control Mapping",
                                description: "Verified ISM control identifiers are visible on mapped implementation steps and searchable in Global Search."
                            )

                            featureRow(
                                icon: "chart.xyaxis.line",
                                color: .blue,
                                title: "Compliance Dashboard",
                                description: "Track maturity level progress on the home screen with animated charts and compliance rings."
                            )

                            featureRow(
                                icon: "magnifyingglass",
                                color: .purple,
                                title: "Global Search",
                                description: "Find specific Group Policies, registry keys, and commands instantly across all controls."
                            )

                            featureRow(
                                icon: "eye.slash",
                                color: .red,
                                title: "Reference Only Mode",
                                description: "Optionally hide the home screen compliance dashboard to use the app purely as a technical reference guide."
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
