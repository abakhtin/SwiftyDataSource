//
//  TableViewDataSource.swift
//  DPDataStorage
//
//  Created by Alexey Bakhtin on 11/16/17.
//  Copyright © 2018 launchOptions. All rights reserved.
//

#if os(iOS)
import UIKit

open class TableViewDataSource<ObjectType>: NSObject, DataSource, WithExpandableCells, UITableViewDataSource, UITableViewDelegate {

    // MARK: Initializer
    
    public init(tableView: UITableView? = nil,
                cellIdentifier: String? = nil,
                container: DataSourceContainer<ObjectType>? = nil,
                delegate: AnyTableViewDataSourceDelegate<ObjectType>?) {
        self.container = container
        self.delegate = delegate
        self.tableView = tableView
        self.cellIdentifier = cellIdentifier
        super.init()
        self.tableView?.dataSource = self
        self.tableView?.delegate = self
        self.container?.delegate = self
    }

    // MARK: Public properties
    
    private var expandableCellsHandler: ExpandableCellsHandlerProtocol?
    
    public var container: DataSourceContainer<ObjectType>? {
        didSet {
            container?.delegate = self
            tableView?.reloadData()
            showNoDataViewIfNeeded()
        }
    }
    
    public var tableView: UITableView? {
        didSet {
            guard let tableView else { return }
            tableView.dataSource = self
            tableView.delegate = self
            expandableCellsHandler = ExpandableCellsHandler(tableView: tableView)
            showNoDataViewIfNeeded()
        }
    }
    
    public var cellIdentifier: String?
    // If you use header and footer identifiers - provide information about height
    // Autolayout does not work correctly for this views
    public var headerIdentifier: String?
    public var footerIdentifier: String?
    public var headerHeight: CGFloat?
    public var removeEmptyHeaders: Bool = true
    public var footerHeight: CGFloat = 0.0

    public var delegate: AnyTableViewDataSourceDelegate<ObjectType>?

    // MARK: Implementing of datasource methods
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        guard let numberOfSections = numberOfSections else {
            return 0
        }
        return numberOfSections
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let numberOfItems = numberOfItems(in: section) else {
            return 0
        }
        return numberOfItems
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let object = object(at: indexPath) else {
            fatalError("Could not retrieve object at \(indexPath)")
        }
        guard let cellIdentifier = delegate?.dataSource(self, cellIdentifierFor: object, at: indexPath) ?? cellIdentifier else {
            fatalError("Cell identifier is empty")
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) else {
            fatalError("Cell is nil after dequeuring for identifier: \(cellIdentifier)")
        }
        guard let configurableCell = cell as? DataSourceConfigurable else {
            fatalError("Cell is not implementing DataSourceConfigurable protocol")
        }
        configurableCell.configure(with: object)
        if let positionHandler = cell as? DataSourcePositionHandler,
           let position = position(of: indexPath) {
            positionHandler.configure(for: position)
        }
        if let delegate = delegate,
           let accessoryType = delegate.dataSource(self, accessoryTypeFor: object, at: indexPath) {
            cell.accessoryType = accessoryType
        }
        if let expandableCell = cell as? DataSourceExpandable {
            expandableCell.setExpanded(value: expandableCellsHandler?.isCellExpanded(at: indexPath) == true)
        }
        delegate?.dataSource(self, setupCell: cell, at: indexPath)
        return cell
    }

    // MARK: NoDataView & RefreshingView processing
    
    public var noDataView: UIView? {
        didSet {
            showNoDataViewIfNeeded()
        }
    }

    public var refreshingView: UIView? {
        didSet {
            showNoDataViewIfNeeded()
        }
    }
    
    public private(set) var isRefreshing: Bool = false
    
    public func beginRefreshing() {
        isRefreshing = true
        showNoDataViewIfNeeded()
    }
    
    public func endRefreshing() {
        tableView?.refreshControl?.endRefreshing()
        isRefreshing = false
        showNoDataViewIfNeeded()
    }
    
    open func setNoDataView(hidden: Bool) {
        setNoDataView(hidden: hidden, isRefreshing: isRefreshing, containerView: tableView)
    }
    
    // MARK: Expanding
    
    public func invertExpanding(at indexPath: IndexPath, animationDuration: Double = 0.3) {
        expandableCellsHandler?.invertExpanding(at: indexPath, animationDuration: animationDuration)
    }
    
    // MARK: Need to implement all methods here to allow overriding in subclasses
    // In the other way it does not visible to iOS SDK and methods in subclass are not called
    
    // UITableViewDataSource:
    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard headerIdentifier == nil else {
            return nil
        }
        return sectionInfo(at: section)?.name
    }
    
    open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? { return nil }
    
    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { return true }
    open func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { return false }

    open func sectionIndexTitles(for tableView: UITableView) -> [String]? { return nil }
    open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int { return index }

    open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) { }
    open func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) { }

    // UITableViewDelegate:
    
    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) { }
    open func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) { }
    open func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) { }
    
    open func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) { }
    open func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) { }
    open func tableView(_ tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int) { }
    
    // Variable height support
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return UITableView.automaticDimension }
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if removeEmptyHeaders, let sectionInfo = sectionInfo(at: section), sectionInfo.name.isEmpty, sectionInfo.sender == nil {
            return .zero
        } else if container?.hasData == false {
            return .zero
        } else if let headerHeight = headerHeight {
            return headerHeight
        } else {
            return UITableView.automaticDimension
        }
    }
    
    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { return footerHeight }
    
    open func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { return UITableView.automaticDimension }
    
    // DO not use automatic height because it is broken in SDK
    // Section header & footer information. Views are preferred over title should you decide to provide both
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerFooterView(with: headerIdentifier, in: section)
    }
    
    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return headerFooterView(with: footerIdentifier, in: section)
    }
    
    private func headerFooterView(with identifier: String?, in section: Int) -> UITableViewHeaderFooterView? {
        guard let identifier = identifier, let sectionInfo = sectionInfo(at: section) else {
            return nil
        }
        guard let view = tableView?.dequeueReusableHeaderFooterView(withIdentifier: identifier) else {
            fatalError("View is nil after dequeuring")
        }
        guard let configurableView = view as? DataSourceConfigurable else {
            fatalError("\(identifier) is not implementing DataSourceConfigurable protocol")
        }
        configurableView.configure(with: sectionInfo)
        return view
    }

    // Don't use automatic dimension because it is set as 0
    open func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat { return 20.0 }
//    open func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat { return UITableViewAutomaticDimension }

    open func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) { }
    
    
    // Selection
    open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool { return true }
    open func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) { }
    open func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) { }
    open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? { return indexPath }
    open func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? { return indexPath }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let object = object(at: indexPath) else { return }
        self.delegate?.dataSource(self, didSelect: object, at: indexPath)
    }
    open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let object = object(at: indexPath) else { return }
        self.delegate?.dataSource(self, didDeselect: object, at: indexPath)
    }
    
    // Editing
    open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle { return .none }
    open func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? { return nil }
    open func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? { return nil }
    
    @available(iOS 11.0, *)
    open func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let object = object(at: indexPath) else { return nil }
        return self.delegate?.dataSourceLeadingSwipeActions(self, didSwipe: object, at: indexPath)
    }
    @available(iOS 11.0, *)
    open func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let object = object(at: indexPath) else { return nil }
        return self.delegate?.dataSourceTrailingSwipeActions(self, didSwipe: object, at: indexPath)
    }
    
    open func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool { return true }
    open func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) { }
    open func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) { }
    
    
    open func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        return proposedDestinationIndexPath
    }
    open func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int { return 0 }
    
    // Copy/Paste.  All three methods must be implemented by the delegate.
    open func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool { return false }
    open func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool { return true }
    open func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {  }
    
    // Focus
    open func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool { return true }
    open func tableView(_ tableView: UITableView, shouldUpdateFocusIn context: UITableViewFocusUpdateContext) -> Bool { return true }
    open func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) { }
    open func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath? { return nil }
   
    // Spring Loading
    @available(iOS 11.0, *)
    open func tableView(_ tableView: UITableView, shouldSpringLoadRowAt indexPath: IndexPath, with context: UISpringLoadedInteractionContext) -> Bool {
        return true
    }
    
    // Scroll view methods
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let tableViewHeight = tableView?.frame.size.height else { return }
        if scrollView.contentOffset.y + (1.5 * tableViewHeight) >= scrollView.contentSize.height {
            delegate?.dataSourceDidScrollToLastElement(self)
        }
    }
}

extension TableViewDataSource: DataSourceContainerDelegate {
    public func containerWillChangeContent(_ container: DataSourceContainerProtocol) {
        tableView?.beginUpdates()
    }
    
    public func container(_ container: DataSourceContainerProtocol, didChange anObject: Any, at indexPath: IndexPath?, for type: DataSourceObjectChangeType, newIndexPath: IndexPath?) {
        print("\(self) \(type) \(String(describing: indexPath)) \(String(describing: newIndexPath))")
        switch (type) {
        case .insert:
            if let newIndexPath = newIndexPath {
                expandableCellsHandler?.handleInsertRow(at: newIndexPath)
                tableView?.insertRows(at: [newIndexPath], with: .fade)
            }
        case .delete:
            if let indexPath = indexPath {
                expandableCellsHandler?.handleDeleteRow(at: indexPath)
                tableView?.deleteRows(at: [indexPath], with: .fade)
            }
        case .move:
            if let indexPath, let newIndexPath, indexPath != newIndexPath {
                expandableCellsHandler?.handleMoveRow(from: indexPath, to: newIndexPath)
                
                tableView?.deleteRows(at: [indexPath], with: .fade)
                tableView?.insertRows(at: [newIndexPath], with: .fade)
            } else if let indexPath {
                tableView?.reloadRows(at: [indexPath], with: .fade)
            }
        case .update:
            if let indexPath = indexPath, let cell = tableView?.cellForRow(at: indexPath) as? DataSourceConfigurable, let object = object(at: indexPath) {
                cell.configure(with: object)
            }
        case .reload:
            if let indexPath = indexPath {
                tableView?.reloadRows(at: [indexPath], with: .fade)
            }
        case .reloadAll:
            expandableCellsHandler?.reset()
            tableView?.reloadData()
        }
    }
    
    public func container(_ container: DataSourceContainerProtocol, didChange sectionInfo: DataSourceSectionInfo, atSectionIndex sectionIndex: Int, for type: DataSourceObjectChangeType) {
        switch (type) {
        case .insert:
            expandableCellsHandler?.handleInsertSection(at: sectionIndex)
            tableView?.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            expandableCellsHandler?.handleDeleteSection(at: sectionIndex)
            tableView?.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .update:
            tableView?.reloadSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            expandableCellsHandler?.reset()
            tableView?.reloadData()
        }
    }
    
    public func container(_ container: DataSourceContainerProtocol, sectionIndexTitleForSectionName sectionName: String) -> String? {
        fatalError()
    }
    
    public func containerDidChangeContent(_ container: DataSourceContainerProtocol) {
        tableView?.endUpdates()
        showNoDataViewIfNeeded()
    }
    
}
#endif
