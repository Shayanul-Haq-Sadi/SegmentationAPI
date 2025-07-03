//
//  SegmentViewController.swift
//  SegmentationAPI
//
//  Created by SHAYAN's Dey 15 on 7/3/25.
//

import UIKit
import MetalPetal
import SVProgressHUD
import Photos


class SegmentViewController: UIViewController {
    
    static let identifier: String = "SegmentViewController"

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var segmentedSwitch: UISwitch!
    @IBOutlet weak var maskSwitch: UISwitch!
    @IBOutlet weak var pathSwitch: UISwitch!
    
    //Images
    var originalImage: UIImage! {  // capped to 1024 for now
        didSet {
//            originalImage = originalImage.resizeImage(targetSize: 1024)
        }
    }
    private var maskImage: UIImage? = nil
    private var segmentedImage: UIImage? = nil
    
    private var contourObservation: VNContoursObservation? = nil

    //layers
    private var segmentedPathLayer: CAShapeLayer = CAShapeLayer()
    
    //Layer Properties
    private var contourBezierPath: UIBezierPath? = nil // holding the normalized path
    private var strokeColor: UIColor! = .orange
    private var fillColor: UIColor! = .gray
    private var opacity: CGFloat! = 1.0
    private var lineWidth: CGFloat = 10.0
    
    //API
    var startTime: Date!
    var uploadCompletedTime: Date!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
                
        //api call
        uploadImageV2(originalImage: originalImage)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        segmentedPathLayer.frame = imageView.bounds
    }
    
    private func setupUI() {
        imageView.backgroundColor = UIColor(patternImage: UIImage(named: "TrasparentCheckerBoard")!)
        overrideUserInterfaceStyle = .dark
        
        segmentedSwitch.isOn = false
        maskSwitch.isOn = false
        pathSwitch.isOn = false
    }
    
    func updateUIForFirstTime() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        preparePathLayer()
        CATransaction.commit()
        
        //Start contour for path
        detectContour()
    }
    
    // MARK: preparePathLayer
    private func preparePathLayer() {
        //add Path Layer to its parent
        segmentedPathLayer.frame = imageView.bounds
        segmentedPathLayer.contentsGravity = .resizeAspect
        segmentedPathLayer.lineCap = .round
        segmentedPathLayer.lineJoin = .round
        segmentedPathLayer.backgroundColor = UIColor.clear.cgColor
        imageView.layer.addSublayer(segmentedPathLayer)
    }
    
    // MARK: Contour Observation
    private func detectContour(){
        guard let maskImage else {return}
        
        self.contourObservation = NCContourDetector.shared().detectVisionContours(maskImage, usingDarkOnLight: false)
        guard let contourObservation = contourObservation else {return}
        
        let bezierPath = UIBezierPath(cgPath: contourObservation.normalizedPath)
        contourBezierPath = bezierPath
    }
    

    private func updatePathProperties(strokeColor: UIColor? = nil, fillColor: UIColor? = nil, opacity: CGFloat? = nil, lineWidth: CGFloat? = nil, animated: Bool = false) {
        if animated {
            if let strokeColor {
                segmentedPathLayer.strokeColor = strokeColor.cgColor
            }
            if let fillColor {
                segmentedPathLayer.fillColor = fillColor.cgColor
            }
            if let opacity {
                segmentedPathLayer.opacity = Float(opacity)
            }
            if let lineWidth {
                segmentedPathLayer.lineWidth = lineWidth
            }
            
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            if let strokeColor {
                segmentedPathLayer.strokeColor = strokeColor.cgColor
            }
            if let fillColor {
                segmentedPathLayer.fillColor = fillColor.cgColor
            }
            if let opacity {
                segmentedPathLayer.opacity = Float(opacity)
            }
            if let lineWidth {
                segmentedPathLayer.lineWidth = lineWidth
            }
                        
            CATransaction.commit()
        }
    }
    
    private func updatePathAndOffset(angle: CGFloat, offset: CGFloat, animated: Bool = false) {
        let finalAngle = angle
        let finalOffset = offset

        guard let contourBezierPath, let segmentedImage else {return}
        let bounds = AVMakeRect(aspectRatio: segmentedImage.size, insideRect: imageView.bounds)
        
//        var tr = CGAffineTransformMake(1, 0, 0, -1, 0, bounds.size.height)
//        tr = CGAffineTransformScale(tr, bounds.size.width, bounds.size.height)
        
        // to add origin for this use case
        var tr = CGAffineTransform(translationX: bounds.origin.x, y: bounds.origin.y + bounds.size.height)
        tr = tr.scaledBy(x: bounds.size.width, y: -bounds.size.height)

        let rAngle = finalAngle * .pi / 180 // Convert to radians
        
        let xOffset = finalOffset * cos(rAngle)
        let yOffset = finalOffset * sin(rAngle)
                
        if animated {
            segmentedPathLayer.path = contourBezierPath.cgPath.copy(using: &tr)
            segmentedPathLayer.shadowOffset = CGSize(width: xOffset, height: yOffset)
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            segmentedPathLayer.path = contourBezierPath.cgPath.copy(using: &tr)
            segmentedPathLayer.shadowOffset = CGSize(width: xOffset, height: yOffset)
            CATransaction.commit()
        }

    }

    // MARK: SAVE Methods
    private func saveImageToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            switch status {
            case .authorized, .limited:
                DispatchQueue.main.async {
                    SVProgressHUD.show()
                }
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.saveAlert(_:didFinishSavingWithError:contextInfo:)), nil)
                
            case .denied, .restricted:
                print("Photo library access denied or restricted.")
                
            case .notDetermined:
                print("Photo library access not determined yet.")
                
            default:
                print("Unknown photo library status.")
            }
        }
        
    }
    
    @objc func saveAlert(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
        }
        if let error = error {
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Success", message: "Image saved to Photo Gallery!", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    private func exportImage(from view: UIView) -> UIImage? {
        guard let imageData = view.asImage()?.pngData(), let image = UIImage(data: imageData) else { return  nil }
        return image
    }
    
    @IBAction func savePressed(_ sender: Any) {
        guard let image = exportImage(from: imageView) else { return }
        saveImageToPhotoLibrary(image)
    }
    
    @IBAction func segmentedSwitchPressed(_ sender: UISwitch) {
        if sender.isOn {
            maskSwitch.setOn(false, animated: true)
            pathSwitch.setOn(false, animated: true)
            updatePathProperties(opacity: 0.0)
            imageView.image = segmentedImage
        } else {
            updatePathProperties(opacity: 0.0)
            imageView.image = nil
        }
    }
    
    @IBAction func maskSwitchPressed(_ sender: UISwitch) {
        if sender.isOn {
            segmentedSwitch.setOn(false, animated: true)
            pathSwitch.setOn(false, animated: true)
            updatePathProperties(opacity: 0.0)
            imageView.image = maskImage
        } else {
            updatePathProperties(opacity: 0.0)
            imageView.image = nil
        }
    }
    
    @IBAction func pathSwitchPressed(_ sender: UISwitch) {
        if sender.isOn {
            segmentedSwitch.setOn(false, animated: true)
            maskSwitch.setOn(false, animated: true)
            imageView.image = nil
            updatePathAndOffset(angle: 0.0, offset: 0.0)
            updatePathProperties(strokeColor: strokeColor, fillColor: fillColor, opacity: opacity, lineWidth: lineWidth)
        } else {
            updatePathProperties(opacity: 0.0)
            imageView.image = nil
        }
    }
}


// MARK: API Methods
extension SegmentViewController {
    
    private func uploadImageV2(originalImage: UIImage) {
        print("uploadImageV2 API CALLED")
        DispatchQueue.main.async {
            SVProgressHUD.show()
        }
        startTime = Date()
        
        NCBGRemoverAPIManager.shared.uploadImageV2(image: originalImage, uploadProgressHandler: { progress, state in
            print("\(state): \(progress)% upload completed")
            
        }, downloadProgressHandler: { progress, state in
            print("\(state): \(progress)% download completed")
            
        }, completion: { [weak self] response in
            
            switch response {
            case .success(let result):
                guard let self else { return }
                uploadCompletedTime = Date()
                print("download successful.")
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                }
                
                processTimeLog(startTime: startTime, endTime: uploadCompletedTime, size: originalImage.size)
                guard let mask = result.maskImage else { return }
                maskImage = mask
                
                if let segmented = result.segmentedImage {
                    // with api segmented
                    let segmentedImg = mt_blend(originalImage: segmented, maskedImage: mask)
                    segmentedImage = segmentedImg
                    imageView.image = segmentedImg
                    segmentedSwitch.setOn(true, animated: true)
                    updateUIForFirstTime()

                } else {
                    // without api segmented
                    // async for open cv
//                    DispatchQueue.global().async { [weak self] in
//                        guard let self else { return }
//                        let segmentedImg = OpenCVWrapper.inpaintEdge(originalImage, mask: mask)
//                        blendedSegmentedImage = segmentedImg

                        let segmentedImg = mt_blend(originalImage: originalImage, maskedImage: mask)
                        segmentedImage = segmentedImg
                        imageView.image = segmentedImg
                        segmentedSwitch.setOn(true, animated: true)
                        updateUIForFirstTime()
//                    }
                }
                
            case .failure(let error):
                print("Error: \(error)")
            }
        })
    }
    
    
    private func processTimeLog(startTime: Date, endTime: Date, size: CGSize) {
        let uploadTime =  endTime.timeIntervalSinceNow - startTime.timeIntervalSinceNow
        let message = """
            Image Size - \(size)
            API TimeLog - \(String(format: "%.2f", uploadTime)) sec.
            """
//        DispatchQueue.main.async {
//            BFToast.showMessage(message, after: 0, delay: 3, disappeared: nil)
//        }
        print(message)
    }
    
    
    private func mt_blend(originalImage: UIImage, maskedImage: UIImage) -> UIImage {
        let cgMaskImage = maskedImage.cgImage!
        let mtiMaskImage = MTIImage(cgImage: cgMaskImage, isOpaque: true)
        let mtiMask = MTIMask(content: mtiMaskImage)
        
        let cgOriginalImage = originalImage.cgImage!
        let mtiOriginalImage = MTIImage(cgImage: cgOriginalImage, isOpaque: true)

        let contextOptions = MTIContextOptions()
        let context = try! MTIContext(device: MTLCreateSystemDefaultDevice()!, options: contextOptions)

        let blendFilter = MTIBlendWithMaskFilter()
        blendFilter.inputMask = mtiMask
//        blendFilter.inputBackgroundImage = mtiMaskImage
        blendFilter.inputBackgroundImage = MTIImage.init(color: MTIColor.clear, sRGB: false, size: mtiOriginalImage.size)

        blendFilter.inputImage = mtiOriginalImage
        
        let outputImage = try! context.makeCGImage(from: blendFilter.outputImage!)
        return UIImage(cgImage: outputImage)
    }
    
}

