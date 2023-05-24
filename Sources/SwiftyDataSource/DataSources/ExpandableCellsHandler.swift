//
//  ExpandableCellsHandler.swift
//  SwiftyDataSource
//
//  Created by Yauheni Fiadotau on 24.05.23.
//  Copyright © 2023 EffectiveSoft. All rights reserved.
//

import UIKit

protocol ExpandableCellsHandlerProtocol {
    func invertExpanding(at indexPath: IndexPath, animationDuration: Double)
    func isCellExpanded(at indexPath: IndexPath) -> Bool
    
    func handleInsertRow(at indexPath: IndexPath)
    func handleDeleteRow(at indexPath: IndexPath)
    func handleMoveRow(from indexPath: IndexPath, to newIndexPath: IndexPath)
    func handleInsertSection(at sectionIndex: Int)
    func handleDeleteSection(at sectionIndex: Int)
    func reset()
}

class ExpandableCellsHandler: ExpandableCellsHandlerProtocol {
    private var expandedCells = Set<IndexPath>()
    private weak var tableView: UITableView?
    
    init(tableView: UITableView) {
        self.tableView = tableView
    }
    
    func invertExpanding(at indexPath: IndexPath, animationDuration: Double) {
        guard let expandableCell = tableView?.cellForRow(at: indexPath) as? UITableViewCell & DataSourceExpandable else { return }
        tableView?.performBatchUpdates {
            UIView.animate(withDuration: animationDuration) {
                let isExpanded = self.expandedCells.contains(indexPath)
                expandableCell.setExpanded(value: !isExpanded)
                if isExpanded {
                    self.expandedCells.remove(indexPath)
                } else {
                    self.expandedCells.insert(indexPath)
                }
                expandableCell.layoutIfNeeded()
            }
        }
    }
    
    func isCellExpanded(at indexPath: IndexPath) -> Bool {
        expandedCells.contains(indexPath)
    }
    
    func handleInsertRow(at indexPath: IndexPath) {
        var indexPathForInsert: IndexPath?
        
        if expandedCells.contains(indexPath) {
            expandedCells.formSymmetricDifference([indexPath])
            indexPathForInsert = IndexPath(row: indexPath.row + 1, section: indexPath.section)
        }
        
        let expandedCellsAfterIndexPath = expandedCells.filter { $0.section == indexPath.section && $0.row > indexPath.row }
        expandedCells.formSymmetricDifference(expandedCellsAfterIndexPath)
        expandedCells.formUnion(expandedCellsAfterIndexPath.map { IndexPath(row: $0.row + 1, section: $0.section) })
        
        if let indexPathForInsert {
            expandedCells.formUnion([indexPathForInsert])
        }
    }
    
    func handleDeleteRow(at indexPath: IndexPath) {
        if expandedCells.contains(indexPath) {
            expandedCells.formSymmetricDifference([indexPath])
        }
        let expandedCellsAfterIndexPath = expandedCells.filter { $0.section == indexPath.section && $0.row > indexPath.row }
        expandedCells.formSymmetricDifference(expandedCellsAfterIndexPath)
        expandedCells.formUnion(expandedCellsAfterIndexPath.map { IndexPath(row: $0.row - 1, section: $0.section) })
    }
    
    func handleMoveRow(from indexPath: IndexPath, to newIndexPath: IndexPath) {
        var indexPathForInsert: IndexPath?
        
        if expandedCells.contains(newIndexPath) {
            expandedCells.formSymmetricDifference([newIndexPath])
            if indexPath.section == newIndexPath.section {
                indexPathForInsert = IndexPath(row: indexPath.row < newIndexPath.row ? newIndexPath.row - 1 : newIndexPath.row + 1, section: newIndexPath.section)
            } else {
                indexPathForInsert = IndexPath(row: newIndexPath.row + 1, section: newIndexPath.section)
            }
        }
        
        if expandedCells.contains(indexPath) {
            expandedCells.formSymmetricDifference([indexPath])
            expandedCells.formUnion([newIndexPath])
        }
        
        if indexPath.section != newIndexPath.section {
            let expandedCellsAfterIndexPath = expandedCells.filter { $0.section == indexPath.section && $0.row > indexPath.row }
            expandedCells.formSymmetricDifference(expandedCellsAfterIndexPath)
            expandedCells.formUnion(expandedCellsAfterIndexPath.map { IndexPath(row: $0.row - 1, section: $0.section) })
            
            let expandedCellsAfterNewIndexPath = expandedCells.filter { $0.section == newIndexPath.section && $0.row > newIndexPath.row }
            expandedCells.formSymmetricDifference(expandedCellsAfterNewIndexPath)
            expandedCells.formUnion(expandedCellsAfterNewIndexPath.map { IndexPath(row: $0.row + 1, section: $0.section) })
        } else if indexPath.section == newIndexPath.section, indexPath.row < newIndexPath.row {
            let expandedCellsAfterIndexPath = expandedCells.filter { $0.section == indexPath.section && $0.row > indexPath.row && $0.row < newIndexPath.row }
            expandedCells.formSymmetricDifference(expandedCellsAfterIndexPath)
            expandedCells.formUnion(expandedCellsAfterIndexPath.map { IndexPath(row: $0.row - 1, section: $0.section) })
        } else {
            let expandedCellsAfterIndexPath = expandedCells.filter { $0.section == indexPath.section && $0.row < indexPath.row && $0.row > newIndexPath.row }
            expandedCells.formSymmetricDifference(expandedCellsAfterIndexPath)
            expandedCells.formUnion(expandedCellsAfterIndexPath.map { IndexPath(row: $0.row + 1, section: $0.section) })
        }
        
        if let indexPathForInsert {
            expandedCells.formUnion([indexPathForInsert])
        }
    }
    
    func handleInsertSection(at sectionIndex: Int) {
        let expandedCellsAfterSection = expandedCells.filter { $0.section > sectionIndex }
        expandedCells.formSymmetricDifference(expandedCellsAfterSection)
        expandedCells.formUnion(expandedCellsAfterSection.map { IndexPath(row: $0.row, section: $0.section + 1) })
    }
    
    func handleDeleteSection(at sectionIndex: Int) {
        expandedCells.formSymmetricDifference(expandedCells.filter { $0.section == sectionIndex })
        let expandedCellsAfterSection = expandedCells.filter { $0.section > sectionIndex }
        expandedCells.formSymmetricDifference(expandedCellsAfterSection)
        expandedCells.formUnion(expandedCellsAfterSection.map { IndexPath(row: $0.row, section: $0.section - 1) })
    }
    
    func reset() {
        expandedCells.removeAll()
    }
}
