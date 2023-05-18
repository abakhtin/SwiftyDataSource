//
//  DataSourceContainerOperationsQueue.swift
//  SwiftyDataSource
//
//  Created by Yauheni Fiadotau on 16.05.23.
//  Copyright © 2023 EffectiveSoft. All rights reserved.
//

import Foundation

class DataSourceContainerOperationsQueue {
    func executeOperation(_ operation: @escaping () -> Void, onCompletion completion: (() -> Void)? = nil) {
        operationsQueue.async {
            operation()
            let semaphore = DispatchSemaphore(value: .zero)
            if let completion {
                DispatchQueue.main.async {
                    completion()
                    semaphore.signal()
                }
            } else {
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
    
    private lazy var operationsQueue = DispatchQueue(label: String(describing: Self.self) + UUID().uuidString, qos: .userInteractive)
}
