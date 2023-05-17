# SwiftyDataSource

### there are two main abstractions in library:

1. Container *helps work with information and can handle data*
2. Data Source *abstraction, which include **container** and displays data from container*

## Containers

1. ### ArrayDataSourceContainer
---
used with arrays data

```swift
func insert(object: ResultType, at indexPath: IndexPath) throws { }
func remove(at indexPath: IndexPath) throws { }
func replace(object: ResultType, at indexPath: IndexPath, reloadAction: Bool = false) throws { }
func removeAll() { }
```

2. ### FRCDataSourceContainer
---
used with data from fetch result controller

```swift
var fetchedObjects: [ResultType]
func object(at indexPath: IndexPath) -> ResultType? { }
func search(_ block:(IndexPath, ResultType) -> Bool) { }
func indexPath(for object: ResultType) -> IndexPath? { }
```

3. ### FilterableDataSourceContainer
---

```swift
func filterData(by searchText: String?) { }
func numberOfItems(in section: Int) -> Int? { }
func object(at indexPath: IndexPath) -> T? { }
```

4. ### HashableDataSourceContainer
---

A generic class that represents a container for `Hashable` objects. It inherits from the `DataSourceContainer` class and provides the same object interaction as in `NSDiffableDataSource`.

#### Initialization

```swift
public init(_ sections: [Section] = [])
```
*   Initializes a new instance of `HashableDataSourceContainer`.
*   `sections`: An optional array of sections to be added to the container during initialization.

#### Properties

*   `sections: [DataSourceSectionInfo]?`: Retrieves an array of section information in the container.
*   `fetchedObjects: [ObjectType]?`: Retrieves an array of objects fetched from the container.

#### `DataSourceContainer` interface 

*   `object(at indexPath: IndexPath) -> ObjectType?`: Retrieves the object at the specified index path.
*   `indexPath(for object: ObjectType) -> IndexPath?`: Retrieves the index path for the specified object.
*   `search(_ block: (IndexPath, ObjectType) -> Bool) -> IndexPath?`: Searches for an object in the container that satisfies the specified condition.
*   `enumerate(_ block: (IndexPath, ObjectType) -> Void)`: Enumerates through each object in the container and executes the specified closure.
*   `numberOfSections() -> Int?`: Retrieves the number of sections in the container.
*   `numberOfItems(in section: Int) -> Int?`: Retrieves the number of items in the specified section.

#### `HashableDataSourceContainer` Interface

*   `performAfterUpdates(_ block: @escaping (_ container: HashableDataSourceContainer<ObjectType>) -> Void)`: Performs the specified block of code after all pending updates have been applied to the container.
*   `objects(atSectionIndex sectionIndex: Int) -> [ObjectType]`: Retrieves the objects in the specified section.
*   `objects(atSection section: Section) -> [ObjectType]`: Retrieves the objects in the specified section.
*   `objects(atSectionContaining object: ObjectType) -> [ObjectType]`: Retrieves the objects in the section containing the specified object.
*   `section(containingObject object: ObjectType) -> Section?`: Retrieves the section that contains the specified object.
*   `firstObject(inSection section: Section?) -> ObjectType?`: Retrieves the first object in the specified section.
*   `lastObject(inSection section: Section?) -> ObjectType?`: Retrieves the last object in the specified section.
*   `contains(_ object: ObjectType) -> Bool`: Checks if the container contains the specified object.
*   `indexOfObject(_ object: ObjectType) -> Int?`: Retrieves the index of the specified object.
*   `indexOfSection(_ section: Section) -> Int?`: Retrieves the index of the specified section.
*   `appendObjects(_ objects: [ObjectType], to section: Section?)`: Appends the specified objects to the given section.
*   `insertObjects(_ objects: [ObjectType], beforeObject: ObjectType)`: Inserts the specified objects before the given object in the same section.
*   `insertObjects(_ objects: [ObjectType], afterObject: ObjectType)`: Inserts the specified objects after the given object in the same section.
*   `deleteObjects(_ objects: [ObjectType])`: Deletes the specified objects from the container.
*   `deleteAllObjects()`: Deletes all objects from the container.
*   `moveObject(_ object: ObjectType, beforeObject: ObjectType)`: Moves the specified object before another object in the same section.
*   `moveObject(_ object: ObjectType, afterObject: ObjectType)`: Moves the specified object after another object in the same section.
*   `replaceObject(_ object: ObjectType, with newObject: ObjectType)`: Replaces an object with a new object in the container.
*   `reloadObjects(_ objects: [ObjectType])`: Reloads the specified objects in the container.
*   `reconfigureObjects(_ objects: [ObjectType])`: Reconfigures the specified objects in the container.
*   `appendSections(_ sections: [Section])`: Appends the specified sections to the container.
*   `insertSections(_ sections: [Section], beforeSection: Section)`: Inserts the specified sections before the given section.
*   `insertSections(_ sections: [Section], afterSection: Section)`: Inserts the specified sections after the given section.
*   `deleteSections(_ sections: [Section])`: Deletes the specified sections from the container.
*   `moveSection(_ section: Section, beforeSection: Section)`: Moves a section before another section in the container.
*   `moveSection(_ section: Section, afterSection: Section)`: Moves a section after another section in the container.
*   `reloadSections(_ sections: [Section])`: Reloads the specified sections in the container.

#### Usage Examples

Here are some examples of how to use the `HashableDataSourceContainer` class:

* **Initializing a Container**

```swift
// Initialize an empty container 
let container = HashableDataSourceContainer<MyObject>()  

// Initialize a container with pre-defined sections 
let section1 = HashableDataSourceContainer<MyObject>.Section(name: "Section1", items: [object1, object2]) 
let section2 = HashableDataSourceContainer<MyObject>.Section(name: "Section2", items: [object3, object4]) 
let container = HashableDataSourceContainer<MyObject>([section1, section2])`
```

* **Accessing Objects**

```swift
// Retrieve the object at a specific index path 
if let object = container.object(at: IndexPath(item: 2, section: 1)) {     
    // Use the object 
}  

// Retrieve the index path for a specific object 
if let indexPath = container.indexPath(for: object2) {     
    // Use the index path 
}  

// Check if the container contains a specific object 
if container.contains(object3) {     
    // Object exists in the container 
}
```

* **Modifying the Container**

```swift
// Append objects to a specific section 
let newObjects = [object5, object6] 
container.appendObjects(newObjects, to: section1)  

// Insert objects before a specific object 
container.insertObjects(newObjects, beforeObject: object2)  

// Delete specific objects from the container 
container.deleteObjects([object1, object4])  

// Delete all objects from the container 
container.deleteAllObjects()  

// Move an object before another object in the same section
container.moveObject(object3, beforeObject: object2)
```

* **Performing Updates**

> ****Important Note****: The `HashableDataSourceContainer` executes all operations on a background thread. As a result, when calling retrieval methods, there is a possibility of receiving outdated information. To ensure you have the most up-to-date data, it is recommended to use the `performAfterUpdates(_ block: )` method. This method allows you to perform actions that depend on the updated container and ensures that the closure is executed after all pending updates have been applied.

```swift
container.performAfterUpdates { updatedContainer in     
    // Perform actions that depend on the updated container     
    // This closure is called after all pending updates have been applied 
}
```
---

## DataSources

1. ### CollectionViewDataSource (use with **CollectionViewDataSourceDelegate**)

2. ### TableViewDataSource (use with **TableViewDataSourceDelegate**)

```swift
func dataSource(_ dataSource: DataSourceProtocol, cellIdentifierFor object: ObjectType, at indexPath: IndexPath) -> String?
func dataSource(_ dataSource: DataSourceProtocol, accessoryTypeFor object: ObjectType, at indexPath: IndexPath) -> UITableViewCell.AccessoryType?
func dataSource(_ dataSource: DataSourceProtocol, didSelect object: ObjectType, at indexPath: IndexPath)
func dataSource(_ dataSource: DataSourceProtocol, didDeselect object: ObjectType, at indexPath: IndexPath?)
```

3. ### MapViewDataSource (use with **MapViewDataSourceDelegate**)
```swift
func dataSource(_ dataSource: DataSourceProtocol, didSelect object: ObjectType) { }
```

**all DataSources have property noDataView which is show, when there are no data in containers**


## code example with FRCDataSourceContainer and tableView

> View Controller properties

```swift
var container: FRCDataSourceContainer<ClassType>?

@IBOutlet weak var tableView: UITableView! {
didSet {
    dataSource.tableView = tableView
    tableView.registerCellNibForDefaultIdentifier(TableViewCell.self)
    dataSource.noDataView = NoDataView()
}

private lazy var dataSource: TableViewDataSource<ClassType> = {
    let dataSource = TableViewDataSource<ClassType>(delegate: AnyTableViewDataSourceDelegate(self))
    dataSource.cellIdentifier = TableViewCell.defaultReuseIdentifier
    return dataSource
}()
```
> View Controller methods

```swift
extension ViewController: TableViewDataSourceDelegate {
    typealias ObjectType = ClassType
    func dataSource(_ dataSource: DataSourceProtocol, didSelect object: ClassType, at indexPath: IndexPath) { }
}
```
