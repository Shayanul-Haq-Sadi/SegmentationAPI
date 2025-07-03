//
//  NCBGRemoverConstants.swift
//  NoCrop
//
//  Created by Debotosh Dey-3 on 16/1/25.
//

import Foundation

class NCBGRemoverConstants {
    static let featureName = "BG Remover"
    
    //API V1
    static let TOKEN = "ra34rf8dfnlefodilsld"
    static let BASE_URL_DEV = "http://213.180.0.76:47930"
    static let END_POINT_DEV = "/segment"
    static let API_URL_DEV = "\(BASE_URL_DEV)\(END_POINT_DEV)"
    
    //API V2
    static let BEARER_TOKEN = "c8aca83933b1773122ba65ed6429f6f13c61yu8aacecdfff0bfa9bb714f01de6"
    static let BASE_URL_PROD = "http://segmentationv3.interlinkapi.com"
    static let END_POINT_PROD = "/segment-image"
    static let MASK_FLAG = "1" // 1 - True (Only Mask will be returned) 0 - False (Both images) // (default 1)
    static let API_URL_PROD = "\(BASE_URL_PROD)\(END_POINT_PROD)?mask_only=\(MASK_FLAG)"
    
    static let SEGMENTATION_MAX_SIZE = 2048.0 //1024.0
    static let SEGMENTATION_MIN_SIZE = 512.0
    static let BG_REMOVER_FREE_USAGE_COUNT = "BGRemoverFreeUsageCount"
    static let BG_REMOVER_FREE_LIMIT = 3
}
