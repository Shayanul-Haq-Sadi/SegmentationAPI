//
//  NCBGRemoverAPIManager.swift
//  NoCrop
//
//  Created by Debotosh Dey-3 on 4/12/24.
//

import Foundation
import Alamofire

class NCBGRemoverAPIManager {
    
    static let shared = NCBGRemoverAPIManager()
    
//    var request: Request?
    
    private var ongoingRequests = [Alamofire.Request]()
    
//    let queue = DispatchQueue(label: "com.test.com", qos: .background, attributes: .concurrent)
    
    func cancelOngoingRequests() {
        for request in ongoingRequests {
            request.cancel()
        }
        ongoingRequests.removeAll()
        print("all ongoingRequests request cancel")
    }
    
    func uploadImage(image: UIImage,
                     uploadProgressHandler: @escaping (Double, String) -> Void,
                     downloadProgressHandler: @escaping (Double, String) -> Void,
                     completion: @escaping (Result<UIImage, Error>) -> Void) {
        
        // type check
        
        
        // convert
//        let image = image.resizeImage(targetSize: NCBGRemoverConstants.SEGMENTATION_MAX_SIZE)

        print("image.size ", image.size)
        
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            print("Failed to convert image to data")
            return
        }
        
        let headers: HTTPHeaders = [
            "token": "\(NCBGRemoverConstants.TOKEN)",
            "Content-Type": "multipart/form-data",
            "Accept": "application/json"
        ]
        
        let request = AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(imageData, withName: "image", fileName: "image\(UUID()).jpg", mimeType: "image/jpg")
            
        }, to: NCBGRemoverConstants.API_URL_DEV, method: .post, headers: headers)
        .uploadProgress(closure: { progress in
            let percentage = progress.fractionCompleted * 100
            uploadProgressHandler(percentage, "Uploading")
        })
        .validate()
        .responseDecodable(of: NCBGRemoverUploadResponse.self) {[weak self] response in
            switch response.result {
            case .success(let value):
                uploadProgressHandler(100, "Uploading Completed")
                
                self?.downloadImage(urlString: "\(value.mask_image_url)", progressHandler: { progress, state in
                    print( "\(state)")
                    let percentage = progress //* 100.0
                    downloadProgressHandler(percentage, "Downloading")
                    
                }, completion: { response in
                    switch response {
                    case .success(let value):
                        if let image = UIImage(data: value) {
                            completion(.success(image))
                        }
                    case .failure(let error):
                        completion(.failure(error))

                    }
                })

            case .failure(let error):
                completion(.failure(error))
            }
        }

        ongoingRequests.append(request)
    }
    
    
    func uploadImageV2(image: UIImage,
                     uploadProgressHandler: @escaping (Double, String) -> Void,
                     downloadProgressHandler: @escaping (Double, String) -> Void,
                     completion: @escaping (Result<NCBGRemoverImageModel, Error>) -> Void) {
        
        // type check
        
        
        // convert
//        let image = image.resizeImage(targetSize: NCBGRemoverConstants.SEGMENTATION_MAX_SIZE)


        print("image.size ", image.size)
        
        let newImg = image.replacingTransparentWithBlack() ?? image // added for api, required to have black in transparent areas.
        
        guard let imageData = newImg.jpegData(compressionQuality: 1.0) else {
            print("Failed to convert image to data")
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(NCBGRemoverConstants.BEARER_TOKEN)",
            "Content-Type": "multipart/form-data",
            "Accept": "application/json"
        ]
        
        let request = AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(imageData, withName: "image", fileName: "image\(UUID()).jpg", mimeType: "image/jpg")
            
        }, to: NCBGRemoverConstants.API_URL_PROD, method: .post, headers: headers)
//        {
//            $0.timeoutInterval = 9999
//        }
        .uploadProgress(closure: { progress in
            let percentage = progress.fractionCompleted * 100
            uploadProgressHandler(percentage, "Uploading")
        })
        .downloadProgress(closure: { progress in
            let percentage = progress.fractionCompleted * 100
            downloadProgressHandler(percentage, "Downloading")
        })
        .validate()
        .responseDecodable(of: NCBGRemoverUploadResponseV2.self) { response in
            switch response.result {
            case .success(let result):
                
                let model = NCBGRemoverImageModel()
                
                if let segmented_base64 = result.segmented_base64 {
                    if let segmentedData = Data(base64Encoded: segmented_base64, options: .ignoreUnknownCharacters),
                       let segmentedImage = UIImage(data: segmentedData) {
                        model.segmentedImage = segmentedImage
                    }
                }
                
                if let maskData = Data(base64Encoded: result.mask_base64, options: .ignoreUnknownCharacters),
                   let maskImage = UIImage(data: maskData) {
                    model.maskImage = maskImage
                }
                
                completion(.success(model))
                

            case .failure(let error):
                print("ERROR FOUND")
                completion(.failure(error))
            }
        }

        ongoingRequests.append(request)
    }
    
    
    private func downloadImage(urlString: String, progressHandler: @escaping (Double, String) -> Void, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: urlString) else { return }
        
        let request = AF.download(url).responseData { response in
            switch response.result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }.downloadProgress(closure: { progress in
            let percentage = progress.fractionCompleted * 100
            progressHandler(percentage, "Downloading")
        })
        ongoingRequests.append(request)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    enum ProcessintStatus {
        case processing
        case uploading
        case completed
    }
    
//    @objc class NCAiEditVariantModel : NSObject {
//        @objc var imageUrl: URL
//        @objc var uiImage: UIImage
//
//        init(imageUrl: URL!, image:UIImage) {
//            self.imageUrl = imageUrl
//            self.uiImage = image
//        }
//    }
//
//    struct AIEditResponse{
//        var variants:[NCAiEditVariantModel]
//        var status:ProcessintStatus
//    }
//
//    var urlSessionManager : AFURLSessionManager?
//        var task:Task<Void, Error>?
//        var colorProfile: CFDictionary?
//        var iccData: Data?
//
//
//
//    func generateImageRequestBody(binaryData: Data)->Data{
//
//        let parameters = [
//            "key": "image",
//            "src": UUID().uuidString,
//            "type": "file"
//          ] as [String: Any]
//
////        let boundary = AiEditApiConstants.BOUNDARY
//        let boundary = "Boundary-\(UUID().uuidString)"
//        var body = Data()
//        let paramName = parameters["key"]!
//        body += Data("--\(boundary)\r\n".utf8)
//        body += Data("Content-Disposition:form-data; name=\"\(paramName)\"".utf8)
//
//        let paramSrc = parameters["src"] as! String
//        body += Data("; filename=\"\(paramSrc)\"\r\n".utf8)
//        body += Data("Content-Type: \"content-type header\"\r\n".utf8)
//        body += Data("\r\n".utf8)
//        body += binaryData
//        body += Data("\r\n".utf8)
//        body += Data("--\(boundary)--\r\n".utf8);
//        return body
//    }
//

    
    
//    func post(url:URL,binaryData:Data,applyUpsacle:Bool,scaleFactor:Int,fromUpscale:Bool = false,completion:@escaping(Result<AIEditResponse,Error>)->Void){
//        let configuration = URLSessionConfiguration.default
//        configuration.timeoutIntervalForResource = 60
//        let urlSessionManager = AFURLSessionManager(sessionConfiguration:configuration );
//        let startTime = Date()
//        var urlWithQuarry = url.appending([
//            URLQueryItem(name: "format", value: "png")
//        ])!
//
//        if !fromUpscale{
//            urlWithQuarry = urlWithQuarry.appending([
//                URLQueryItem(name: "scale_factor", value: "\(scaleFactor)"),URLQueryItem(name: "upscale_result", value: applyUpsacle ? "1":"0")])!
//
//
//        }
//        print("variantList url",urlWithQuarry.absoluteString)
//
//        urlSessionManager.securityPolicy = AFSecurityPolicy.default();
//        var request = URLRequest(url: urlWithQuarry,timeoutInterval: Double.infinity)
//        request.addValue(AiEditApiConstants.AUTHORIZATION_VALUE, forHTTPHeaderField: "Authorization")
//        request.addValue("multipart/form-data; boundary=\(AiEditApiConstants.BOUNDARY)", forHTTPHeaderField: "Content-Type")
//        request.httpMethod = "POST"
//        let postData = generateImageRequestBody(binaryData: binaryData)
//        request.httpBody = postData
//
//        let serializer = AFHTTPResponseSerializer()
//        serializer.acceptableContentTypes = ["application/zip"]
//        urlSessionManager.responseSerializer = serializer
//        completion(.success(AIEditResponse(variants: [], status: .uploading)))
//        var uploadCompletedTime = Date()
//        urlSessionManager.uploadTask(with: request, from: postData) { progress in
//            print("progress" ,progress.fractionCompleted)
//            if progress.fractionCompleted == 1.0{
//                uploadCompletedTime = Date()
//                completion(.success(AIEditResponse(variants: [], status: .processing)))
//            }
//        } completionHandler: { [weak self] response, responseObject, error in
//            guard error == nil else{
//                print(error)
//                completion(.failure(error!))
//                return
//            }
//            print(response,error)
//            guard let dataObject = responseObject as? Data else {
////                continuation.resume(throwing: error as! Never)
//                return
//            }
//            let uploadTime =  uploadCompletedTime.timeIntervalSinceNow - startTime.timeIntervalSinceNow
//
//            let processingTime = Date().timeIntervalSinceNow - uploadCompletedTime.timeIntervalSinceNow
//            let totalTime = Date().timeIntervalSinceNow - startTime.timeIntervalSinceNow
//            let message = "Upload - \(String(format: "%.2f", uploadTime)). processing - \(String(format: "%.2f", processingTime)). total - \(String(format: "%.2f", totalTime))"
////            BFToast.showMessage(message, after: 0, delay: 10) { s in
////            }
//            print(message)
//
////            Task{
////                let urls:[URL]? = try await NCAiEditHelpers.zipFileToFileUrls(data: dataObject)
////
////                var variantList:[NCAiEditVariantModel] = []
////                _ = urls?.map { url in
////                    //self?.addColorProfileToImage(inputURL: url, outputURL: url)
//////                    self?.addICCProfileToImage(sourceImageURL: url, iccData: self!.iccData!, outputImageURL: url)
////                    var imageName = ""
////                    if #available(iOS 16.0, *) {
////                        imageName = url.path()
////                    } else {
////                        imageName = url.path
////                    }
////
////                    var image = UIImage(contentsOfFile: imageName)
//////                    image = self!.saveColoredImage(image: image ?? UIImage())
////                    print("variantList",image?.size,Date())
////                    variantList.append(NCAiEditVariantModel(imageUrl: url, image: image!))
////
////                }
////                completion(.success(AIEditResponse(variants: variantList, status: .completed)))
////            }
//
//        }.resume()
//
//        self.urlSessionManager = urlSessionManager
//    }
    
}





// can be done "heic", "heix", "hevc", "hevx"
enum ImageFormat: String {
    case png, jpg, gif, tiff, webp, heic, unknown
}

extension ImageFormat {
    static func get(from data: Data) -> ImageFormat {
        switch data[0] {
        case 0x89:
            return .png
        case 0xFF:
            return .jpg
        case 0x47:
            return .gif
        case 0x49, 0x4D:
            return .tiff
        case 0x52 where data.count >= 12:
            let subdata = data[0...11]

            if let dataString = String(data: subdata, encoding: .ascii),
                dataString.hasPrefix("RIFF"),
                dataString.hasSuffix("WEBP")
            {
                return .webp
            }

        case 0x00 where data.count >= 12 :
            let subdata = data[8...11]

            if let dataString = String(data: subdata, encoding: .ascii),
                Set(["heic", "heix", "hevc", "hevx"]).contains(dataString)
                ///OLD: "ftypheic", "ftypheix", "ftyphevc", "ftyphevx"
            {
                return .heic
            }
        default:
            break
        }
        return .unknown
    }

    var contentType: String {
        return "image/\(rawValue)"
    }
}



//struct ImageHeaderData{
//    static var PNG: [UInt8] = [0x89]
//    static var JPEG: [UInt8] = [0xFF]
//    static var GIF: [UInt8] = [0x47]
//    static var TIFF_01: [UInt8] = [0x49]
//    static var TIFF_02: [UInt8] = [0x4D]
//}

//enum ImageFormat{
//    case Unknown, PNG, JPEG, GIF, TIFF
//}


//extension NSData{
//    var imageFormat: ImageFormat{
//        var buffer = [UInt8](repeating: 0, count: 1)
//        self.getBytes(&buffer, range: NSRange(location: 0,length: 1))
//        if buffer == ImageHeaderData.PNG
//        {
//            return .PNG
//        } else if buffer == ImageHeaderData.JPEG
//        {
//            return .JPEG
//        } else if buffer == ImageHeaderData.GIF
//        {
//            return .GIF
//        } else if buffer == ImageHeaderData.TIFF_01 || buffer == ImageHeaderData.TIFF_02{
//            return .TIFF
//        } else{
//            return .Unknown
//        }
//    }
//}

