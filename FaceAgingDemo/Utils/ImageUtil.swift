//
//  ImageUtil.swift
//  Predictor
//
//  Created by Jason Wu on 2019/4/16.
//

import UIKit
import Photos

class ImageUtil {
    
    static func shareImage(parent: UIViewController, image: UIImage) {
        let imageToShare = [image]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = parent.view
        parent.present(activityViewController, animated: true, completion: nil)
    }
    
}
