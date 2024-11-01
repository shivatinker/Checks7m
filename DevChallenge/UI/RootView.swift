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
            Text("Hello, World!")
            
            Button("Start", action: self.model.start)
                .disabled(self.model.isStarted)
        }
        .frame(width: 600, height: 400)
    }
}

#if DEBUG

#Preview {
    RootView(MockRootViewModel())
}

final class MockRootViewModel: RootViewModelProtocol {
    @Published private(set) var isStarted: Bool = false
    
    func start() {
        self.isStarted.toggle()
    }
}

#endif
