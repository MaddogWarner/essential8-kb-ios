//
//  HomeView.swift
//  Essential 8 Knowledge Base
//

import Charts
import SwiftUI

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let controlName: String
    let status: String
    let count: Int
    let color: Color
}

struct ComplianceRingView: View {
    let percentage: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 10)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(percentage / 100.0, 1.0)))
                .stroke(
                    LinearGradient(
                        colors: [.blue, .green, .teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentage)
            
            VStack(spacing: 0) {
                Text(String(format: "%.0f%%", percentage))
                    .font(.system(.title3, design: .rounded).bold())
                Text("Compliant")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
        }
        .frame(width: 80, height: 80)
    }
}

struct ComplianceBarChart: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Steps", item.count),
                y: .value("Control", item.controlName)
            )
            .foregroundStyle(item.color)
        }
        .chartXAxis {
            AxisMarks(position: .bottom, values: .automatic(desiredCount: 5))
        }
        .chartLegend(.hidden)
        .frame(height: 180)
        .padding(.vertical, 8)
    }
}

struct HomeView: View {
    private let controls = EssentialControlsData.all
    @EnvironmentObject private var progressStore: ProgressStore
    @State private var isShowingAbout = false
    @AppStorage("showSplashOnStartup") private var showSplashOnStartup = true
    @AppStorage("referenceOnlyMode") private var referenceOnlyMode = false
    @AppStorage("targetMaturityLevel") private var targetMaturityRawValue = MaturityLevel.ml3.rawValue
    @State private var isShowingSplash = false
    @State private var hasShownSplashThisSession = false

    private var targetLevel: MaturityLevel {
        MaturityLevel(rawValue: targetMaturityRawValue) ?? .ml3
    }

    private var inScopeSteps: [ImplementationStep] {
        controls.flatMap { $0.steps(upTo: targetLevel) }
    }

    private var overallTotalSteps: Int {
        inScopeSteps.count
    }

    private var overallImplementedSteps: Int {
        inScopeSteps.filter { progressStore.isCompleted($0.id) }.count
    }

    private var overallNASteps: Int {
        inScopeSteps.filter { progressStore.isNotApplicable($0.id) }.count
    }

    private var overallCompliancePercentage: Double {
        let total = overallTotalSteps
        let na = overallNASteps
        let comp = overallImplementedSteps
        let denom = total - na
        if denom <= 0 { return 100.0 }
        return Double(comp) / Double(denom) * 100.0
    }

    private var chartData: [ChartDataPoint] {
        var points: [ChartDataPoint] = []
        for control in controls {
            let allSteps = control.steps(upTo: targetLevel)
            
            let implemented = progressStore.completedCount(for: allSteps)
            let na = progressStore.notApplicableCount(for: allSteps)
            let pending = allSteps.count - implemented - na
            
            if implemented > 0 {
                points.append(ChartDataPoint(controlName: control.shortName, status: "Implemented", count: implemented, color: .green))
            }
            if na > 0 {
                points.append(ChartDataPoint(controlName: control.shortName, status: "Not Applicable", count: na, color: .orange))
            }
            if pending > 0 {
                points.append(ChartDataPoint(controlName: control.shortName, status: "Pending", count: pending, color: Color(uiColor: .systemGray5)))
            }
        }
        return points
    }

    var body: some View {
        List {
            if !referenceOnlyMode {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Target Maturity Level")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            Picker("Target maturity level", selection: $targetMaturityRawValue) {
                                ForEach(MaturityLevel.allCases) { level in
                                    Text(level.shortName).tag(level.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)
                            .accessibilityLabel("Target maturity level")
                        }

                        Divider()

                        HStack(spacing: 20) {
                            ComplianceRingView(percentage: overallCompliancePercentage)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Compliance Summary")
                                    .font(.subheadline.bold())
                                
                                HStack {
                                    Circle().fill(.green).frame(width: 8, height: 8)
                                    Text("Implemented: \(overallImplementedSteps)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                HStack {
                                    Circle().fill(.orange).frame(width: 8, height: 8)
                                    Text("Not Applicable: \(overallNASteps)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                HStack {
                                    Circle().fill(Color(uiColor: .systemGray4)).frame(width: 8, height: 8)
                                    Text("Pending: \(overallTotalSteps - overallImplementedSteps - overallNASteps)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Maturity Breakdown by Control")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            
                            ComplianceBarChart(data: chartData)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Maturity Dashboard")
                }
            }

            Section {
                ForEach(controls) { control in
                    NavigationLink(value: control) {
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(control.name)
                                        .font(.headline)
                                    Text("Mitigation \(control.id)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: control.iconSystemName)
                                    .foregroundStyle(.tint)
                                    .imageScale(.large)
                            }
                            .padding(.vertical, 4)
                            Spacer()
                            if progressStore.isControlComplete(control, upTo: targetLevel) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .imageScale(.medium)
                            }
                        }
                    }
                }
            } header: {
                Text("ASD Essential Eight")
            } footer: {
                Text("Content is scoped to controls achievable using built-in Windows OS tooling. Verify against the current ASD Essential Eight Maturity Model before implementation.")
                    .font(.footnote)
            }

            Section {
                NavigationLink {
                    WindowsAuditPolicyView()
                } label: {
                    Label("Windows Audit Policy", systemImage: "doc.text.magnifyingglass")
                }
            } header: {
                Text("Event Logging")
            } footer: {
                Text("ASD recommended minimum Windows Security Audit Policy settings for detection and response.")
                    .font(.footnote)
            }

            Section {
                NavigationLink {
                    Microsoft365SettingsView()
                } label: {
                    Label("M365 Additional Controls", systemImage: "gearshape.2")
                }

                Button {
                    isShowingAbout = true
                } label: {
                    Label("About & Privacy", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Essential 8 Knowledge Base")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Essential 8 Knowledge Base")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    GlobalSearchView()
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .navigationDestination(for: EssentialControl.self) { control in
            ControlDetailView(control: control)
        }
        .sheet(isPresented: $isShowingAbout) {
            AboutView()
        }
        .sheet(isPresented: $isShowingSplash) {
            SplashView(showSplashOnStartup: $showSplashOnStartup)
        }
        .onAppear {
            if showSplashOnStartup && !hasShownSplashThisSession {
                hasShownSplashThisSession = true
                isShowingSplash = true
            }
        }
    }
}

extension EssentialControl {
    var shortName: String {
        switch id {
        case 1: return "App Control"
        case 2: return "Patch Apps"
        case 3: return "Macros"
        case 4: return "Hardening"
        case 5: return "Admin Privs"
        case 6: return "Patch OS"
        case 7: return "MFA"
        case 8: return "Backups"
        default: return name
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(ProgressStore.shared)
}
