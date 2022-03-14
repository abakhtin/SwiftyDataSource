//
//  ChildConfigurable+SetChildViewController.swift
//  LKM
//
//  Created by Alex Rybchinskiy on 2.08.21.
//  Copyright © 2021 LLC Topcase. All rights reserved.
//

#if os(iOS)

import Foundation
import UIKit

protocol ChildConfigurable: UIViewController {
    var childViewController: UIViewController? { get set }
}

extension ChildConfigurable {
    func setChildViewController(_ childViewController: UIViewController?) {
        guard childViewController != self.childViewController else { return }
        
        if let childViewController = self.childViewController {
            childViewController.willMove(toParent: nil)
            childViewController.view.removeFromSuperview()
            childViewController.removeFromParent()
        }
        self.childViewController = childViewController
        
        guard let childViewController = childViewController else { return }
        addChildViewController(childViewController, to: view)
    }
}

extension UIViewController {
    func addChildViewController(_ childViewController: UIViewController, to view: UIView) {
        addChild(childViewController)
        view.addSubview(childViewController.view)
        childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            childViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            childViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        childViewController.didMove(toParent: self)
    }
}

#endif
