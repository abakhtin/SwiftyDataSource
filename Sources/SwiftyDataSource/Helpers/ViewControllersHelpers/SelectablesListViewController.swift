//
//  SelectablesListViewController.swift
//  launchOptions
//
//  Created by Alexey Bakhtin on 10/1/18.
//  Copyright © 2018 launchOptions. All rights reserved.
//

#if os(iOS)
import UIKit

open class SelectablesListViewController<T>: UIViewController, UISearchResultsUpdating, UISearchBarDelegate, TableViewDataSourceDelegate where T: SelectableEntity {

    // MARK: Public
    
    public init(container: DataSourceContainer<T>? = nil,
                selected: [T]? = nil,
                multiselection: Bool = false,
                cellUsesCustomSelection: Bool = false) {
        super.init(nibName: nil, bundle: nil)
        self.container = container
        self.dataSource.container = container
        self.selectedEntries = selected ?? []
        self.multiselection = multiselection
        self.cellUsesCustomSelection = cellUsesCustomSelection
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public var container: DataSourceContainer<T>? {
        didSet {
            self.dataSource.container = container
        }
    }
    
    public var delegate: AnySelectablesListDelegate<T>?
    public var didSelectAction: ((T) -> ())?
    public var didSelectMultiAction: (([T]) -> ())?

    open func cellIdentifier() -> String {
        return SelectablesListCell.defaultReuseIdentifier
    }
    
    open func headerIdentifier() -> String? {
        return nil
    }

    open func headerHeight() -> CGFloat {
        return headerIdentifier() == nil ? 0.0 : 66.0
    }
    
    open func registerCell(in tableView: UITableView) {
        tableView.registerCellClassForDefaultIdentifier(SelectablesListCell.self)
    }

    // MARK: Actions
    
    @objc public func done(_ sender: AnyObject) {
        didSelectMultiAction?(selectedEntries)
        delegate?.listDidSelect(self, entities: selectedEntries)
    }

    @objc private func selectAllEntries(_ sender: AnyObject) {
        container?.enumerate({ (indexPath, entity) in
            select(object: entity, at: indexPath)
        })
    }
    
    @objc private func deselectAllEntries(_ sender: AnyObject) {
        container?.enumerate({ (indexPath, entity) in
            deselect(object: entity, at: indexPath)
        })
    }
    
    // MARK: View life cycle
    
    public private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.bounds)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // In this controller single selection is processed on didSelectAction,
        // as multiple selection of table view allows to deselect single choise
        tableView.allowsMultipleSelection = true
        
        registerCell(in: tableView)
        dataSource.tableView = tableView

        return tableView
    }()
    
    open override func loadView() {
        super.loadView()
        view = UIView(frame: CGRect.init(x: 0, y: 0, width: 320, height: 480))
        
        view.addSubview(tableView)
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        let applyButton = initApplyButton()
        view.addSubview(applyButton)
        let buttonInset = 16.0 as CGFloat
        applyButton.addTarget(self, action: #selector(done(_:)), for: .touchUpInside)
        applyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: buttonInset).isActive = true
        applyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -buttonInset).isActive = true
        applyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -buttonInset).isActive = true
        
        var insets = tableView.contentInset
        insets.bottom += applyButton.frame.height + 2*buttonInset
        tableView.contentInset = insets
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        if container is FilterableDataSourceContainer {
            definesPresentationContext = true
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        }

        updateNavigationItems()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        selectRowsForSelectedEntries()
    }
    
    open func initApplyButton() -> UIButton {
        let applyButton = UIButton(type: .custom)
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.setTitle(NSLocalizedString("DONE", comment: ""), for: .normal)
        applyButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return applyButton
    }

    // MARK: Navigation items
    
    private(set) lazy var selectAllButtonItem = UIBarButtonItem(title: NSLocalizedString("SELECT_ALL", comment: ""), style: .plain, target: self, action: #selector(selectAllEntries(_:)))
    
    private(set) lazy var deselectAllButtonItem = UIBarButtonItem(title: NSLocalizedString("DESELECT_ALL", comment: ""), style: .plain, target: self, action: #selector(deselectAllEntries(_:)))

    private func updateNavigationItems() {
        if self.multiselection {
            let isAllEntriesSelected = selectedEntries.count == container?.fetchedObjects?.count
            self.navigationItem.rightBarButtonItem = isAllEntriesSelected ? deselectAllButtonItem : selectAllButtonItem
        }
    }
    
    // MARK: DataSource
    
    public lazy var dataSource: TableViewDataSource<T> = {
        let dataSource = TableViewDataSource<T>(container: container, delegate: AnyTableViewDataSourceDelegate(self))
        dataSource.cellIdentifier = cellIdentifier()
        dataSource.headerIdentifier = headerIdentifier()
        dataSource.headerHeight = headerHeight()
        return dataSource
    }()
    
    
    // MARK: Private

    private var multiselection: Bool = false
    private var cellUsesCustomSelection: Bool = false
    private var selectedEntries: [T] = []
    private var allowTextSearch: Bool {
        return container is FilterableDataSourceContainer<T>
    }
    
    public private(set) lazy var searchController: UISearchController? = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("FIND", comment: "")
        searchController.searchBar.setImage(UIImage(named: "searchbar-icon"), for: .search, state: .normal)
        searchController.searchBar.delegate = self
        searchController.searchBar.showsCancelButton = false
        searchController.searchBar.showsSearchResultsButton = true
        return searchController
    }()

    // MARK: UISearchResultsUpdating
    
    open func updateSearchResults(for searchController: UISearchController) {
        (container as? FilterableDataSourceContainer)?.filterData(by: searchController.searchBar.text)
        tableView.reloadData()
        selectRowsForSelectedEntries()
    }

    fileprivate func selectRowsForSelectedEntries() {
        selectedEntries.forEach { entry in
            let indexPath = container?.search({ (indexPath, entity) -> Bool in
                return entity.selectableEntityIsEqual(to: entry)
            })
            if let indexPath = indexPath {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }
    }
    
    // MARK: UISearchBarDelegate

    open func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchController?.searchBar.endEditing(true)
    }
    
    open func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        searchController?.searchBar.endEditing(true)
    }

    // MARK: DataSource delegate
    
    open func dataSource(_ dataSource: DataSourceProtocol, didSelect object: T, at indexPath: IndexPath) {
        if !isObjectSelected(object) {
            didSelectAction?(object)
            selectedEntries.append(object)
            delegate?.listDidSelect(self, object)
        }

        if multiselection == false {
            selectedEntries = [object]
            if let indexPathsForSelectedRows = tableView.indexPathsForSelectedRows {
                for indexPathForSelectedRow in indexPathsForSelectedRows {
                    if indexPathForSelectedRow != indexPath {
                        tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
                    }
                }
            }
        }
        
        updateNavigationItems()
    }
    
    open func dataSource(_ dataSource: DataSourceProtocol, didDeselect object: T, at indexPath: IndexPath?) {
        if let index = selectedEntries.firstIndex(where: { $0.selectableEntityIsEqual(to: object)}) {
            selectedEntries.remove(at: index)
            delegate?.listDidDeselect(self, object)
        }
        updateNavigationItems()
    }
    
    public func isObjectSelected(_ object: T) -> Bool {
        return selectedEntries.contains(where: { $0.selectableEntityIsEqual(to: object) })
    }
    
    // MARK: Public methods for manual selecting
    
    public func select(object: T, at indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        dataSource(dataSource, didSelect: object, at: indexPath)
    }

    public func deselect(object: T, at indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        dataSource(dataSource, didDeselect: object, at: indexPath)
    }

}

// MARK: SelectablesListCell

open class SelectablesListCell: UITableViewCell, DataSourceConfigurable {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    public let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    open func setup() {
        contentView.addSubview(label)
        label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        label.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 15).isActive = true
        label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15).isActive = true
        label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15).isActive = true
    }
    
    public func configure(with object: Any) {
        self.entity = object as? SelectableEntity
    }
    
    open var entity: SelectableEntity? {
        didSet {
            label.attributedText = entity?.selectableEntityDescription
        }
    }
}
#endif
