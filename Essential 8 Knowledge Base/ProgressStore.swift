//
//  ProgressStore.swift
//  Essential 8 Knowledge Base
//

import Combine
import Foundation

final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    private let key = "e8kb.stepProgress"

    @Published private(set) var completedIDs: Set<String>

    private init() {
        let saved = UserDefaults.standard.stringArray(forKey: key) ?? []
        completedIDs = Set(saved)
    }

    func toggle(_ stepID: String) {
        if completedIDs.contains(stepID) {
            completedIDs.remove(stepID)
        } else {
            completedIDs.insert(stepID)
        }

        UserDefaults.standard.set(Array(completedIDs), forKey: key)
    }

    func isCompleted(_ stepID: String) -> Bool {
        completedIDs.contains(stepID)
    }

    func completedCount(for steps: [ImplementationStep]) -> Int {
        steps.filter { completedIDs.contains($0.id) }.count
    }

    func isControlComplete(_ control: EssentialControl) -> Bool {
        let allSteps = MaturityLevel.allCases.flatMap { control.content(for: $0).steps }
        return !allSteps.isEmpty && allSteps.allSatisfy { completedIDs.contains($0.id) }
    }
}
