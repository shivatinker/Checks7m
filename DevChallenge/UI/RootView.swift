//
//  RootView.swift
//  DevChallenge
//
//  Created by Andrii Zinoviev on 01.11.2024.
//

import SwiftUI

struct RootView<Model: RootViewModelProtocol>: View {
    @StateObject var model: Model
    
    init(_ model: Model) {
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        VStack {
            switch self.model.state {
            case .ready:
                Text("Ready")
                
            case let .progress(progress):
                if let progress {
                    ProgressView(value: progress)
                }
                else {
                    ProgressView()
                        .progressViewStyle(LinearProgressViewStyle())
                }
                
            case let .done(digest):
                Text(digest)
                
            case let .error(error):
                Text(error)
                    .foregroundStyle(.red)
            }
            
            Button("Open") {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                
                let response = panel.runModal()
                
                guard response == .OK, let url = panel.url else {
                    return
                }
                
                self.model.processFile(at: url)
            }
            .disabled(self.model.state.isStartDisabled)
        }
        .frame(width: 200)
        .frame(width: 600, height: 400)
    }
}

#if DEBUG

#Preview {
    RootView(MockRootViewModel())
}

final class MockRootViewModel: RootViewModelProtocol {
    let state: RootViewState = .progress(nil)
    func processFile(at url: URL) {}
}

#endif
