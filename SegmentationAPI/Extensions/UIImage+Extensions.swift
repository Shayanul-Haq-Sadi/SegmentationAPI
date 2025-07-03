//
//  UIImage+Extensions.swift
//  SegmentationModels
//
//  Created by Debotosh Dey-3 on 12/1/25.
//


import UIKit
import CoreImage

extension UIImage {
    
    func fixedOrientation() -> UIImage? {
        guard imageOrientation != UIImage.Orientation.up else {
            // This is default orientation, don't need to do anything
            return self.copy() as? UIImage
        }
        
        guard let cgImage = self.cgImage else {
            // CGImage is not available
            return nil
        }
        
        guard let colorSpace = cgImage.colorSpace, let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil // Not able to create CGContext
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat.pi / -2.0)
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }
        
        // Flip image one more time if needed to, this is to prevent flipped image
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        @unknown default:
            break
        }
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        
        guard let newCGImage = ctx.makeImage() else { return nil }
        return UIImage.init(cgImage: newCGImage, scale: 1, orientation: .up)
    }
    
    
    
    func resizeImage(targetSize: CGFloat) -> UIImage {
        let size = self.size
        
        let widthRatio  = targetSize  / size.width
        let heightRatio = targetSize / size.height
        
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: floor(size.width * heightRatio),
                             height: floor(size.height * heightRatio))
        } else {
            newSize = CGSize(width: floor(size.width * widthRatio),
                             height: floor(size.height * widthRatio))
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let image = newImage else{return UIImage()}
        
        return image
    }
    
    
    func replacingTransparentWithBlack() -> UIImage? {
        let rect = CGRect(origin: .zero, size: self.size)
        
        // Begin image context
        UIGraphicsBeginImageContextWithOptions(self.size, true, self.scale)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        // Fill the entire area with black
//        context.setFillColor(UIColor.black.cgColor)
//        context.fill(rect)
        
        // Draw the original image on top
        self.draw(in: rect)
        
        // Get the result
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }

    
//    @objc
//    func imageIsEmpty() -> Bool {
//        let grayScaleMaskFilter = BCMAlphaMaskToGrayScaleFilter()
//        let img = self.toMTIImage().unpremultiplyingAlpha()
//        grayScaleMaskFilter.inputImage = img
//        guard let outputImage = grayScaleMaskFilter.outputImage?.toUIImage() else { return true }
//        guard let cgImage = outputImage.cgImage,
//              let dataProvider = cgImage.dataProvider else
//        {
//            return true
//        }
//
//        let pixelData = dataProvider.data
//        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
//        let imageWidth = Int(outputImage.size.width)
//        let imageHeight = Int(outputImage.size.height)
//        for x in 0..<imageWidth {
//            for y in 0..<imageHeight {
//                let pixelIndex = ((imageWidth * y) + x) * 4
//                let r = data[pixelIndex]
//                let g = data[pixelIndex + 1]
//                let b = data[pixelIndex + 2]
////                let a = data[pixelIndex + 3]
////                print("alpha", pixelIndex, a);
////                if a != 0 {
//                    if r == 1 && g == 1 && b == 1 {
//                        return false
//                    }
////                }
//            }
//        }
//
//        return true
//    }
    
    
    
    fileprivate class SmoothFilter : CIFilter {
        
        private let kernel: CIColorKernel
        var inputImage: CIImage?
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override init() {
            let kernelStr = """
                kernel vec4 myColor(__sample source) {
                    float maskValue = smoothstep(0.3, 0.5, source.r);
                    return vec4(maskValue,maskValue,maskValue,1.0);
                }
            """
            let kernels = CIColorKernel.makeKernels(source:kernelStr)!
            kernel = kernels[0] as! CIColorKernel
            super.init()
        }
        
        override var outputImage: CIImage? {
            guard let inputImage = inputImage else {return nil}
            let blurFilter = CIFilter.init(name: "CIGaussianBlur")!
            blurFilter.setDefaults()
            blurFilter.setValue(inputImage.extent.width / 90.0, forKey: kCIInputRadiusKey)
            blurFilter.setValue(inputImage, forKey: kCIInputImageKey)
            let bluredImage = blurFilter.value(forKey:kCIOutputImageKey) as! CIImage
            return kernel.apply(extent: bluredImage.extent, arguments: [bluredImage])
        }
    }
    
    func resize(size: CGSize!) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        self.draw(in:rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
    
    
    public func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        return pixelBuffer(width: width, height: height,
                           pixelFormatType: kCVPixelFormatType_32ARGB,
                           colorSpace: CGColorSpaceCreateDeviceRGB(),
                           alphaInfo: .noneSkipFirst)
    }
    
    
    func pixelBuffer(width: Int, height: Int, pixelFormatType: OSType,
                     colorSpace: CGColorSpace, alphaInfo: CGImageAlphaInfo) -> CVPixelBuffer? {
        var maybePixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         pixelFormatType,
                                         attrs as CFDictionary,
                                         &maybePixelBuffer)
        
        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        guard let context = CGContext(data: pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: colorSpace,
                                      bitmapInfo: alphaInfo.rawValue)
        else {
            return nil
        }
        
        UIGraphicsPushContext(context)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer
    }
    
}
