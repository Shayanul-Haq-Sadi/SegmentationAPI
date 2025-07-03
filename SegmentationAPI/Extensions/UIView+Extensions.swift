//
//  UIView+Extensions.swift
//  SegmentationModels
//
//  Created by Debotosh Dey-3 on 13/1/25.
//

import UIKit

extension UIView {
    func asImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: self.bounds)
        return renderer.image { context in
            drawHierarchy(in: self.bounds, afterScreenUpdates: true)
            self.layer.render(in: context.cgContext)
        }
    }
    
}
