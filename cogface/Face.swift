//
//  Detect.swift
//  cogface
//
//  Created by Jason Amos on 3/8/17.
//  Copyright © 2017 All rights reserved.
//

import Foundation
import UIKit


class Face {
    
    var session = URLSession.shared
    
    func createPersonGroupWith(_ personGroupId: String, name: String, userData: String?, completion: ((_ results: String )->Void)?){
        let url = NSURL(string: "https://westus.api.cognitive.microsoft.com/face/v1.0/persongroups/\(personGroupId)/") as! URL
        let dict = [
            "name": name,
            "userData": userData
        ]

        requestWith(url: url, body: dict, method: "POST",contentType: "application/json", ocpApimSubscriptionKey: "{ocpApimSubscriptionKey}") { (result) in
            completion!(result)
        }

    }
    
    func createPersonWith(_ personGroupId: String, name: String, userData: String?, completion: ((_ results: String )->Void)?){
        let url = NSURL(string: "https://westus.api.cognitive.microsoft.com/face/v1.0/persongroups/\(personGroupId)/persons") as! URL
        
        let dict = [
            "name": name,
            "userData": userData
        ]
        
        requestWith(url: url, body: dict, method: "POST", contentType: "application/json", ocpApimSubscriptionKey: "{ocpApimSubscriptionKey}") { (result) in
         completion!(result)
        }
    }
    
    //If the image contains more than one face, only the largest face will be added
    //You can add other faces to the person by passing a string in the format of "targetFace = left, top, width, height" to Person – Add a Person Face API's targetFace query parameter
    func addPersonWith(_ face: UIImage, personGroupId: String, personId: String, completion: ((_ results: String )->Void)?){
        let url = NSURL(string: "https://westus.api.cognitive.microsoft.com/face/v1.0/persongroups/\(personGroupId)/persons/\(personId)/persistedFaces") as! URL

       let data = UIImageJPEGRepresentation(face, 0.5)
        
        requestWith(data: data!, url: url, method: "POST", contentType: "application/octet-stream", ocpApimSubscriptionKey: "{ocpApimSubscriptionKey}") { (result) in
            completion!(result)
        }
    }
    
    func identifyWith(_ faceIds: [String: String?], personGroupId: String, maxNumOfCandidatesReturned: Int, confidenceThreshold: Float, completion: ((_ results: String )->Void)?){
        
        let url = NSURL(string: "https://westus.api.cognitive.microsoft.com/face/v1.0/identify") as! URL
        
        let dict = [
            "personGroupId": personGroupId,
            "faceIds": faceIds,
            "maxNumOfCandidatesReturned": maxNumOfCandidatesReturned,
            "confidenceThreshold": confidenceThreshold
        ] as [String : Any]
        
        requestWith(url: url, body: dict, method: "POST", contentType: "application/json", ocpApimSubscriptionKey: "{ocpApimSubscriptionKey}") { (result) in
            completion!(result)
        }
        
    }
    
    func getPersonWith(_ personGroupId: String, personId: String, completion: ((_ results: String )->Void)?){
        let url = NSURL(string: "https://westus.api.cognitive.microsoft.com/face/v1.0/persongroups/\(personGroupId)/persons/\(personId)") as! URL
        
        requestWith(url: url, body: [:], method: "POST", contentType: "application/json", ocpApimSubscriptionKey: "{ocpApimSubscriptionKey}") { (result) in
            completion!(result)
        }

    }
    func getWith(_ personGroupId: String, personId: String, persistedFaceId: String, completion: ((_ results: String )->Void)?){
        let url = NSURL(string: "https://westus.api.cognitive.microsoft.com/face/v1.0/persongroups/\(personGroupId)/persons/\(personId)/persistedFaces/\(persistedFaceId)") as! URL
    
        requestWith(url: url, body: [:], method: "POST", contentType: "application/json", ocpApimSubscriptionKey: "{ocpApimSubscriptionKey}") { (result) in
            completion!(result)
        }

    }
    
    func detectEmotion(_ image: UIImage, returnFaceId: Bool, returnFaceLandmarks: Bool, completion: ((_ results: String )->Void)?){
        
        let data = UIImageJPEGRepresentation(image, 0.2)
        
        let url = NSURL(string: "https://westus.api.cognitive.microsoft.com/emotion/v1.0/recognize") as! URL
        
        requestWith(data: data!, url: url, method: "POST", contentType: "application/octet-stream", ocpApimSubscriptionKey: "{ocpApimSubscriptionKey}") { (result) in
            completion!(result)
        }
    }
    
    func detectWith(_ image: UIImage, returnFaceId: Bool, returnFaceLandmarks: Bool, completion: ((_ results: String )->Void)?){
        
        let data = UIImageJPEGRepresentation(image, 1)
        
        let url = NSURL(string: "https://api.projectoxford.ai/face/v1.0/detect?returnFaceId=\(returnFaceId)&returnFaceLandmarks=\(returnFaceLandmarks)&returnFaceAttributes=pose,gender,age,headPose,facialHair,glasses") as! URL
        
        requestWith(data: data!, url: url, method: "POST", contentType: "application/octet-stream", ocpApimSubscriptionKey: "{ocpApimSubscriptionKey}") { (result) in
            completion!(result)
        }
    }

    
   fileprivate func trainPersonGroupWith(_ personGroupId: String, completion: ((_ results: String )->Void)?){
        let url = NSURL(string: "https://westus.api.cognitive.microsoft.com/face/v1.0/persongroups/\(personGroupId)/train") as! URL
    requestWith(url: url, body: [:] as Dictionary, method: "POST", contentType: "application/octet-stream", ocpApimSubscriptionKey: "{ocpApimSubscriptionKey}") { (result) in
            completion!(result)
        }
    }
    
    fileprivate func requestWith(data: Data, url: URL, method: String, contentType: String, ocpApimSubscriptionKey: String, completion: ((_ results: String )->Void)?){
        
        let request = NSMutableURLRequest(url: url)
        
        request.httpMethod = method
        request.httpBody = data //try! JSONSerialization.data(withJSONObject: data, options: [])
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        request.addValue(ocpApimSubscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        let task = session.uploadTask(with: request as URLRequest, from: data) { (data, response, error) in
            print("Response: \(response)")
            let strData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            
            if(error != nil) {
                print(error!.localizedDescription)
            }
            else {
                completion!(strData as! String)
            }
        }
        
        task.resume()
    }
    
    
    fileprivate func requestWith(url: URL, body: [String : Any?], method: String, contentType: String, ocpApimSubscriptionKey: String, completion: ((_ results: String )->Void)?){
        
        let request = NSMutableURLRequest(url: url)
        
        request.httpMethod = method
        request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        request.addValue(ocpApimSubscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            
            print("Response: \(response)")
            let strData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print("Body: \(strData)")

            if(error != nil) {
                print(error!.localizedDescription)
            }
            else {
                 completion!(strData as! String)
            }
        })
        
        task.resume()
    }
}
