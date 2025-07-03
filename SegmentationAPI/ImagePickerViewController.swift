//
//  ImagePickerViewController.swift
//  SegmentationAPI
//
//  Created by SHAYAN's Dey 15 on 7/3/25.
//

import UIKit

class ImagePickerViewController: UIViewController, UINavigationControllerDelegate {
    
    static let identifier: String = "ImagePickerViewController"
    
    @IBOutlet weak var imageView: UIImageView!
    
    private var pickedImage: UIImage!
    
    private var isPicked: Bool = false


    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark

    }
    @IBAction func imagePickerPressed(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
//        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func imageGeneratePressed(_ sender: Any) {
        if isPicked {
            guard let VC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: SegmentViewController.identifier) as? SegmentViewController else { return }
            
            VC.originalImage = pickedImage
            
            self.navigationController?.pushViewController(VC, animated: true)
        }
    }
}


extension ImagePickerViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.isPicked = true
            self.pickedImage = pickedImage
            
//            guard let fixedOrientationImage = pickedImage.fixedOrientation() else { return }

            
            DispatchQueue.main.async {
                self.imageView.image = pickedImage
            }
            
        }
        dismiss(animated: true, completion: nil)
    }
        
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
