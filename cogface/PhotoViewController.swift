//
//  PhotoViewController.swift
//  cogface
//
//  Created by Jason Amos on 3/10/17.
//  Copyright © 2017 All rights reserved.
//

import UIKit
import SwiftyJSON

class PhotoViewController: UIViewController {
    
    @IBOutlet var imagePicked: UIImageView!
    @IBOutlet var fakeText: UITextView!
    @IBOutlet var fakeButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func openPhotoLibraryButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            var imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func openCameraButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func touchUpInside(_ sender: Any) {
        Face().detectEmotion(imagePicked.image!, returnFaceId: true, returnFaceLandmarks: true) { (result) in
            let json = JSON.init(parseJSON: result)
            self.title = ""
            if let score = (json[0]["scores"].dictionaryObject as? [String : Double]){
                DispatchQueue.main.async { [unowned self] in
                    self.title = score.keysForValue(value: score.values.max()!)[0]
                }
            }
        }
    }
}
extension PhotoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        imagePicked.image = image
        self.dismiss(animated: true, completion: nil);
    }
    
}
extension Dictionary where Value: Equatable {
    func keysForValue(value: Value) -> [Key] {
        return flatMap { (key: Key, val: Value) -> Key? in
            value == val ? key : nil
        }
    }
}
