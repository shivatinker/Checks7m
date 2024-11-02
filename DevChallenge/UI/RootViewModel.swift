//
//  RootViewModel.swift
//  DevChallenge
//
//  Created by Andrii Zinoviev on 01.11.2024.
//

import Foundation

enum RootViewState {
    case ready
    case progress(Double?)
    case done(String)
    case error(String)
    
    var isStartDisabled: Bool {
        switch self {
        case .ready: return false
        case .progress: return true
        case .done: return false
        case .error: return false
        }
    }
}

@MainActor
protocol RootViewModelProtocol: ObservableObject {
    var state: RootViewState { get }
    
    func processFiles(_ urls: [URL])
}

final class RootViewModel: RootViewModelProtocol {
    private let controller = ChecksumController()
    
    @Published private(set) var state: RootViewState = .ready
    
    func processFiles(_ urls: [URL]) {
        precondition(false == self.state.isStartDisabled)
        
        Task { @MainActor in
            do {
                self.state = .progress(nil)
                
                try await self.controller.generateChecksum(
                    for: urls,
                    type: .sha256
                ) { progress in
                    Task { @MainActor in
                        self.state = .progress(progress)
                    }
                }
                
                self.state = .done("Done")
            }
            catch {
                self.state = .error("\(error)")
            }
        }
    }
}
