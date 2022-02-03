//
//  UIDocumentInteractionControllerPresenter.swift
//  SwiftyDataSource
//
//  Created by Alexey Bakhtin on 03/09/2019.
//  Copyright © 2019 EffectiveSoft. All rights reserved.
//

#if os(iOS)
import UIKit

public class UIDocumentInteractionControllerPresenter: NSObject, UIDocumentInteractionControllerDelegate {
    
    private static let defaultPresenter = UIDocumentInteractionControllerPresenter()
    
    public static func showDocumentInteractionController(for url: URL, from viewController: UIViewController, with name: String? = nil) {
        defaultPresenter.viewControllerForPreview = viewController
        defaultPresenter.documentInteractionController.url = url
        if let name = name {
            defaultPresenter.documentInteractionController.name = name
        }
        let presented = defaultPresenter.documentInteractionController.presentPreview(animated: true)
        if !presented {
            // If UIDocumentInteractionController do not support file, show UIActivityViewController to allow user to choose 
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = viewController.navigationController?.navigationBar
            viewController.present(activityViewController, animated: true)
        }
    }
    
    private lazy var documentInteractionController: UIDocumentInteractionController = {
        let controller = UIDocumentInteractionController()
        controller.delegate = self
        return controller
    }()
    
    private weak var viewControllerForPreview: UIViewController!
    
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return viewControllerForPreview
    }
}
#endif
