//
//  HashableDataSourceContainerTests.swift
//  SwiftyDataSourceTests
//
//  Created by Yauheni Fiadotau on 15.05.23.
//  Copyright © 2023 EffectiveSoft. All rights reserved.
//

import XCTest
@testable import SwiftyDataSource

class HashableDataSourceContainerTests: XCTestCase {
    typealias HashableSection = HashableDataSourceContainer<Int>.Section<Int>
    var sut: HashableDataSourceContainer<Int>!
    
    override func setUp() {
        super.setUp()
        sut = HashableDataSourceContainer<Int>()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testAppendObjects() {
        // Given
        let section = HashableSection(objects: [1, 2, 3])
        
        // When
        sut.appendSections([section])
        sut.appendObjects([4, 5], to: section)
        
        // Then
        XCTAssertEqual(sut.numberOfItems(in: 0), 5)
        XCTAssertEqual(sut.numberOfSections(), 1)
        XCTAssertEqual(sut.objects(atSectionIndex: 0), [1, 2, 3, 4, 5])
    }
    
    func testInsertObjectsBefore() {
        // Given
        let section = HashableSection(objects: [1, 3, 4])
        
        // When
        sut.appendSections([section])
        sut.insertObjects([2], beforeObject: 3)
        
        // Then
        XCTAssertEqual(sut.numberOfItems(in: 0), 4)
        XCTAssertEqual(sut.numberOfSections(), 1)
        XCTAssertEqual(sut.objects(atSectionIndex: 0), [1, 2, 3, 4])
    }
    
    func testInsertObjectsAfter() {
        // Given
        let section = HashableSection(objects: [1, 2, 4])
        
        // When
        sut.appendSections([section])
        sut.insertObjects([3], afterObject: 2)
        
        // Then
        XCTAssertEqual(sut.numberOfItems(in: 0), 4)
        XCTAssertEqual(sut.numberOfSections(), 1)
        XCTAssertEqual(sut.objects(atSectionIndex: 0), [1, 2, 3, 4])
    }
    
    func testDeleteObjects() {
        // Given
        let section = HashableSection(objects: [1, 2, 3, 4, 5])
        
        // When
        sut.appendSections([section])
        sut.deleteObjects([2, 4])
        
        // Then
        XCTAssertEqual(sut.numberOfItems(in: 0), 3)
        XCTAssertEqual(sut.numberOfSections(), 1)
        XCTAssertEqual(sut.objects(atSectionIndex: 0), [1, 3, 5])
    }
    
    func testDeleteAllObjects() {
        // Given
        let section1 = HashableSection(objects: [1, 2, 3])
        let section2 = HashableSection(objects: [4, 5])
        
        // When
        sut.appendSections([section1, section2])
        sut.deleteAllObjects()
        
        // Then
        XCTAssertEqual(sut.numberOfItems(in: 0), nil)
        XCTAssertEqual(sut.numberOfItems(in: 1), nil)
        XCTAssertEqual(sut.numberOfSections(), 0)
        XCTAssertEqual(sut.objects(atSectionIndex: 0), [])
        XCTAssertEqual(sut.objects(atSectionIndex: 1), [])
    }
    
    func testMoveObjectBefore() {
        // Given
        let section = HashableSection(objects: [1, 2, 3, 4, 5])
        
        // When
        sut.appendSections([section])
        sut.moveObject(4, beforeObject: 2)
        
        // Then
        XCTAssertEqual(sut.numberOfItems(in: 0), 5)
        XCTAssertEqual(sut.numberOfSections(), 1)
        XCTAssertEqual(sut.objects(atSectionIndex: 0), [1, 4, 2, 3, 5])
    }

    func testMoveObjectAfter() {
        // Given
        let section = HashableSection(objects: [1, 2, 3, 4, 5])
        
        // When
        sut.appendSections([section])
        sut.moveObject(2, afterObject: 4)
        
        // Then
        XCTAssertEqual(sut.numberOfItems(in: 0), 5)
        XCTAssertEqual(sut.numberOfSections(), 1)
        XCTAssertEqual(sut.objects(atSectionIndex: 0), [1, 3, 4, 2, 5])
    }

    func testReplaceObject() {
        // Given
        let section = HashableSection(objects: [1, 2, 3, 4, 5])
        
        // When
        sut.appendSections([section])
        sut.replaceObject(3, with: 6)
        
        // Then
        XCTAssertEqual(sut.numberOfItems(in: 0), 5)
        XCTAssertEqual(sut.numberOfSections(), 1)
        XCTAssertEqual(sut.objects(atSectionIndex: 0), [1, 2, 6, 4, 5])
    }
    
    func testMultipleSections() {
        // Given
        let section1 = HashableSection(objects: [1, 2, 3])
        let section2 = HashableSection(objects: [4, 5, 6])
        
        // When
        sut.appendSections([section1, section2])
        
        // Then
        XCTAssertEqual(sut.numberOfItems(in: 0), 3)
        XCTAssertEqual(sut.numberOfItems(in: 1), 3)
        XCTAssertEqual(sut.numberOfSections(), 2)
        XCTAssertEqual(sut.objects(atSectionIndex: 0), [1, 2, 3])
        XCTAssertEqual(sut.objects(atSectionIndex: 1), [4, 5, 6])
    }
    
    func testRemoveSection() {
        // Given
        let section1 = HashableSection(objects: [1, 2, 3])
        let section2 = HashableSection(objects: [4, 5, 6])
        sut.appendSections([section1, section2])
        
        // When
        sut.deleteSections([section1])
        
        // Then

        XCTAssertEqual(sut.numberOfItems(in: 0), 3)
        XCTAssertEqual(sut.numberOfItems(in: 1), nil)
        XCTAssertEqual(sut.numberOfSections(), 1)
        XCTAssertEqual(sut.objects(atSectionIndex: 0), [4, 5, 6])
    }

    func testMoveSectionBefore() {
        // Given
        let section1 = HashableSection(objects: [1, 2, 3])
        let section2 = HashableSection(objects: [4, 5, 6])
        sut.appendSections([section1, section2])
        
        // When
        sut.moveSection(section2, beforeSection: section1)
        
        // Then
        XCTAssertEqual(sut.numberOfItems(in: 0), 3)
        XCTAssertEqual(sut.numberOfItems(in: 1), 3)
        XCTAssertEqual(sut.numberOfSections(), 2)
        XCTAssertEqual(sut.objects(atSectionIndex: 0), [4, 5, 6])
        XCTAssertEqual(sut.objects(atSectionIndex: 1), [1, 2, 3])
    }
    
    func testMoveSectionAfter() {
        // Given
        let section1 = HashableSection(objects: [1, 2, 3])
        let section2 = HashableSection(objects: [4, 5, 6])
        sut.appendSections([section1, section2])
        
        // When
        sut.moveSection(section1, afterSection: section2)
        
        // Then
        XCTAssertEqual(sut.numberOfItems(in: 0), 3)
        XCTAssertEqual(sut.numberOfItems(in: 1), 3)
        XCTAssertEqual(sut.numberOfSections(), 2)
        XCTAssertEqual(sut.objects(atSectionIndex: 0), [4, 5, 6])
        XCTAssertEqual(sut.objects(atSectionIndex: 1), [1, 2, 3])
    }
    
    func testItemIndexPath() {
        // Given
        let section1 = HashableSection(objects: [1, 2, 3])
        let section2 = HashableSection(objects: [4, 5, 6])
        sut.appendSections([section1, section2])
        
        // When
        let indexPath1 = sut.indexPath(for: 3)
        let indexPath2 = sut.indexPath(for: 5)
        let indexPath3 = sut.indexPath(for: 7)
        
        // Then
        XCTAssertEqual(indexPath1, IndexPath(item: 2, section: 0))
        XCTAssertEqual(indexPath2, IndexPath(item: 1, section: 1))
        XCTAssertNil(indexPath3)
    }

    func testObjectAtIndexPath() {
        // Given
        let section1 = HashableSection(objects: [1, 2, 3])
        let section2 = HashableSection(objects: [4, 5, 6])
        sut.appendSections([section1, section2])
        
        // When
        let object1 = sut.object(at: IndexPath(item: 2, section: 0))
        let object2 = sut.object(at: IndexPath(item: 1, section: 1))
        let object3 = sut.object(at: IndexPath(item: 3, section: 0))
        let object4 = sut.object(at: IndexPath(item: 0, section: 2))
        
        // Then
        XCTAssertEqual(object1, 3)
        XCTAssertEqual(object2, 5)
        XCTAssertNil(object3)
        XCTAssertNil(object4)
    }
}
