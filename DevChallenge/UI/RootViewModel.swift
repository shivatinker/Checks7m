//
//  RootViewModel.swift
//  DevChallenge
//
//  Created by Andrii Zinoviev on 01.11.2024.
//

import DevChallengeXPC
import Foundation

@MainActor
protocol RootViewModelProtocol: ObservableObject {
    var isStarted: Bool { get }
    
    func start()
}

final class RootViewModel: RootViewModelProtocol {
    @Published private(set) var isStarted: Bool = false
    
    func start() {
        self.isStarted.toggle()
        
        let connectionToService = NSXPCConnection(serviceName: "com.shivatinker.DevChallengeXPC")
        connectionToService.remoteObjectInterface = NSXPCInterface(with: DevChallengeXPCProtocol.self)
        connectionToService.resume()
        
        if let proxy = connectionToService.remoteObjectProxy as? DevChallengeXPCProtocol {
            proxy.performCalculation(firstNumber: 23, secondNumber: 19) { result in
                NSLog("Result of calculation is: \(result)")
            }
        }
        else {
            print("Could not connect to service")
        }
    }
}
