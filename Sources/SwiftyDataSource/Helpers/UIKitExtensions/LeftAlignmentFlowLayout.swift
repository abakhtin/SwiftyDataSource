//
//  LeftAlignmentFlowLayout.swift
//  SwiftyDataSource
//
//  Created by Dima Shelkov on 1/16/20.
//  Copyright © 2020 EffectiveSoft. All rights reserved.
//

#if os(iOS)
import UIKit

public class LeftAlignmentFlowLayout: UICollectionViewFlowLayout {
    
    public required init(_ minimumInteritemSpacing: CGFloat = 0, _ minimumLineSpacing: CGFloat = 0, _ sectionInset: UIEdgeInsets = .zero, _ scrollDirection: UICollectionView.ScrollDirection = .vertical) {
        super.init()
        
        estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
        sectionInsetReference = .fromSafeArea
        self.scrollDirection = scrollDirection
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let layoutAttributes = super.layoutAttributesForElements(in: rect)!.map { $0.copy() as! UICollectionViewLayoutAttributes }
        guard scrollDirection == .vertical else { return layoutAttributes }
        
        // Filter attributes to compute only cell attributes
        let cellAttributes = layoutAttributes.filter({ $0.representedElementCategory == .cell })
        
        // Group cell attributes by row (cells with same vertical center) and loop on those groups
        for (_, attributes) in Dictionary(grouping: cellAttributes, by: { ($0.center.y / 10).rounded(.up) * 10 }) {
            // Set the initial left inset
            var leftInset = sectionInset.left
            
            // Loop on cells to adjust each cell's origin and prepare leftInset for the next cell
            for attribute in attributes {
                attribute.frame.origin.x = leftInset
                if let collectionView = collectionView {
                    attribute.frame.size.width = min(attribute.frame.width, collectionView.frame.width - sectionInset.left - sectionInset.right - collectionView.contentInset.left - collectionView.contentInset.right - 1)
                }
                leftInset = attribute.frame.maxX + minimumInteritemSpacing
            }
        }
        
        return layoutAttributes
    }
}
#endif
