//
//  NCBGRemoverUploadResponse.swift
//  NoCrop
//
//  Created by Debotosh Dey-3 on 10/12/24.
//

import Foundation

struct NCBGRemoverUploadResponse: Codable {
    let mask_image_url: String
    let success: Bool
}


struct NCBGRemoverUploadResponseV2: Codable {
    let mask_base64: String
    let segmented_base64: String?
}
