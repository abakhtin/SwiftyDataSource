//
//  DataSourceContainerOperationsQueue.swift
//  SwiftyDataSource
//
//  Created by Yauheni Fiadotau on 16.05.23.
//  Copyright © 2023 EffectiveSoft. All rights reserved.
//

import Foundation

class DataSourceContainerOperationsQueue {
    private lazy var operationsQueue = DispatchQueue(label: String(describing: Self.self) + UUID().uuidString)
    
    private var operations: [(operation: () -> Void, completion: (() -> Void)?)] = []
    
    private var isExecutingTask = false
    
    private func executeNextTask() {
        guard !isExecutingTask, !operations.isEmpty else { return }
        isExecutingTask = true
        let operation = operations.removeFirst()
        let task = DispatchWorkItem(block: operation.operation)
        let completion: DispatchWorkItem
        if let onCompletion = operation.completion {
            completion = .init(block: onCompletion)
            task.notify(queue: .main, execute: completion)
        } else {
            completion = task
        }
        completion.notify(queue: operationsQueue) {
            self.isExecutingTask = false
            self.executeNextTask()
        }
        DispatchQueue.global(qos: .userInteractive).async(execute: task)
    }
    
    func executeOperation(_ operation: @escaping () -> Void, onCompletion completion: (() -> Void)? = nil) {
        operationsQueue.async {
            self.operations.append((operation, completion))
            self.executeNextTask()
        }
    }
}
