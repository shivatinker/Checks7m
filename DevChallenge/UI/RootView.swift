//
//  RootView.swift
//  DevChallenge
//
//  Created by Andrii Zinoviev on 01.11.2024.
//

import ChecksumKit
import SwiftUI

struct RootView<Model: RootViewModelProtocol>: View {
    @State var selection: Set<URL> = []
    @StateObject var model: Model
    
    init(_ model: Model) {
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text("Input files")
                        .bold()
                        .padding(4)
                    
                    Divider()
                    
                    List(
                        self.model.files.sorted(using: KeyPathComparator(\.absoluteString)),
                        id: \.self,
                        selection: self.$selection
                    ) { url in
                        Text(url.lastPathComponent)
                    }
                    .listStyle(.plain)
                    
                    Divider()
                    
                    HStack {
                        Button("Add") {
                            self.model.addFiles()
                        }
                        
                        Button("Remove") {
                            self.model.removeFiles(self.selection)
                        }
                        .disabled(self.selection.isEmpty)
                        
                        Spacer()
                    }
                    .padding(4)
                }
                .frame(width: 300)
                
                Divider()
                
                self.makeControlPanel()
                    .frame(width: 300)
            }
            
            Divider()
            
            self.makeStatusBar()
        }
        .frame(height: 400)
    }
    
    @ViewBuilder
    private func makeControlPanel() -> some View {
        VStack {
            Divider()
            
            Text("Generate")
                .bold()
            
            Picker("Checksum Type", selection: self.$model.checksumType) {
                ForEach(ChecksumType.allCases, id: \.self) { type in
                    switch type {
                    case .md5:
                        Text("MD5")
                        
                    case .sha256:
                        Text("SHA256")
                    }
                }
            }
            .pickerStyle(RadioGroupPickerStyle())
            .disabled(false == self.model.isGenerateEnabled)
            
            Button("Generate Checksums") {
                self.model.generateChecksums()
            }
            .disabled(false == self.model.isGenerateEnabled)
            
            Divider()
            
            Text("Validate")
                .bold()
            
            Text("Loaded checksum: \(self.model.loadedChecksumFile ?? "<nil>")")
                .foregroundStyle(.secondary)
            
            HStack {
                Button("Load...") {
                    self.model.loadChecksums()
                }
                
                Button("View") {
                    self.model.viewChecksums()
                }
                .disabled(self.model.loadedChecksumFile == nil)
            }
            
            Button("Validate Checksums") {
                self.model.validateChecksums()
            }
            .disabled(false == self.model.isValidateEnabled)
            
            Divider()
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func makeStatusBar() -> some View {
        HStack {
            switch self.model.state {
            case .ready:
                Text("Ready")
                
            case let .progress(progress):
                HStack {
                    Text("Processing...")
                    
                    if let progress {
                        ProgressView(value: progress)
                    }
                    else {
                        ProgressView()
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                .frame(width: 250)
                
            case let .done(digest):
                Text(digest)
                
            case let .error(error):
                Text(error)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .frame(height: 25)
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
}

#if DEBUG

#Preview {
    RootView(MockRootViewModel())
}

#endif
