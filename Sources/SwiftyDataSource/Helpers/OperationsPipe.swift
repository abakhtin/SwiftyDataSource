//
//  OperationsPipe.swift
//  SwiftyDataSource
//
//  Created by Yauheni Fiadotau on 16.05.23.
//  Copyright © 2023 EffectiveSoft. All rights reserved.
//

import Foundation

protocol OperationsPipeProtocol {
    func executeOperation(_ operation: OperationsPipeOperation)
}

struct OperationsPipeOperation {
    var operation: () -> Void
    var operationQueue: DispatchQueue = .global()
    var completion: (() -> Void)? = nil
    var completionQueue: DispatchQueue = .global()
}

class OperationsPipe: OperationsPipeProtocol {
    private lazy var pipeQueue = DispatchQueue(label: String(describing: Self.self) + UUID().uuidString)
    
    private var operations: [OperationsPipeOperation] = []
    
    private var isExecutingTask = false
    
    private func executeNextTask() {
        if !isExecutingTask {
            if let operation = operations.first {
                isExecutingTask = true
                operations.removeFirst()
                let task = DispatchWorkItem(block: operation.operation)
                let completion: DispatchWorkItem
                if let onCompletion = operation.completion {
                    completion = .init(block: onCompletion)
                    task.notify(queue: operation.completionQueue, execute: completion)
                } else {
                    completion = task
                }
                completion.notify(queue: pipeQueue) {
                    self.isExecutingTask = false
                    self.executeNextTask()
                }
                operation.operationQueue.async(execute: task)
            }
        }
    }
    
    func executeOperation(_ operation: OperationsPipeOperation) {
        pipeQueue.async {
            self.operations.append(operation)
            self.executeNextTask()
        }
    }
}
