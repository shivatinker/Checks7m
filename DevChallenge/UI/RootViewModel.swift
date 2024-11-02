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
    
    func processFile(at url: URL)
}

final class RootViewModel: RootViewModelProtocol {
    private let controller = ChecksumController()
    
    @Published private(set) var state: RootViewState = .ready
    
    func processFile(at url: URL) {
        precondition(false == self.state.isStartDisabled)
        
        Task { @MainActor in
            do {
                self.state = .progress(nil)
                
                let data = try await self.controller.generateChecksum(
                    forFileAt: url,
                    type: .sha256
                ) { progress in
                    Task { @MainActor in
                        self.state = .progress(progress)
                    }
                }
                
                let hexDigest = data.map { String(format: "%02hhx", $0) }.joined()
                self.state = .done(hexDigest)
            }
            catch {
                self.state = .error("\(error)")
            }
        }
    }
}
