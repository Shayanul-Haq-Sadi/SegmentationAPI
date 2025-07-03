//
//  NCBGRemoverImageModel.swift
//  NoCrop
//
//  Created by Debotosh Dey-3 on 5/1/25.
//

import UIKit

@objcMembers
class NCBGRemoverImageModel: NSObject {
    var maskImage: UIImage? = nil
    var segmentedImage: UIImage? = nil
    
    init(maskImage: UIImage? = nil, segmentedImage: UIImage? = nil) {
        self.maskImage = maskImage
        self.segmentedImage = segmentedImage
    }
}
