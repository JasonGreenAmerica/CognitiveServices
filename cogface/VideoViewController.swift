//
//  VideoViewController.swift
//  cogface
//
//  Created by Jason Amos on 3/7/17.
//  Copyright © 2017  All rights reserved.
//

import UIKit
import AVKit
import CoreData
import CoreMotion
import AVFoundation

class VideoViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet var videoPlayer: UIView!
    var captureSession = AVCaptureSession();
    var sessionOutput = AVCaptureVideoDataOutput();
    var sessionOutputSetting = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecJPEG]);
    var player = AVPlayer()
    var sampleTime : Int?
    
    @IBOutlet var textViewDescription: UITextView!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var stillImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
    }
    lazy var cameraSession: AVCaptureSession = {
        let s = AVCaptureSession()
        s.sessionPreset = AVCaptureSessionPresetHigh
        return s
    }()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let previewl:AVCaptureVideoPreviewLayer =  AVCaptureVideoPreviewLayer(session: self.cameraSession)
        previewl.frame = self.videoPlayer.bounds
        return previewl
    }()
    
    func setupCameraSession() {
        
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { (response) in
            if !response{
                return
            }
        }
        let deviceDiscoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInDuoCamera, AVCaptureDeviceType.builtInTelephotoCamera,AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.unspecified)
        for device in (deviceDiscoverySession?.devices)! {
            if(device.position == AVCaptureDevicePosition.back){
                
                let captureDevice = device
                
                do {
                    let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
                    
                    cameraSession.beginConfiguration()
                    
                    if (cameraSession.canAddInput(deviceInput) == true) {
                        cameraSession.addInput(deviceInput)
                    }
                    
                    let dataOutput = AVCaptureVideoDataOutput()
                    dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value:kCVPixelFormatType_32BGRA as UInt32)]
                    dataOutput.alwaysDiscardsLateVideoFrames = true
                    
                    if (cameraSession.canAddOutput(dataOutput) == true) {
                        cameraSession.addOutput(dataOutput)
                    }
                    
                    cameraSession.commitConfiguration()
                    
                    let queue = DispatchQueue(label: "cog.face.queue", attributes: [])
                    dataOutput.setSampleBufferDelegate(self, queue: queue)
                    
                }
                catch let error as NSError {
                    NSLog("\(error), \(error.localizedDescription)")
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupCameraSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        previewLayer.frame = videoPlayer.bounds
        videoPlayer.layer.addSublayer(previewLayer)
        cameraSession.startRunning()
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = videoPlayer.bounds
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func touchUpInsideCapture(_ sender: UIButton) {
        
        videoThumbnails()
    }
    func videoThumbnails(){
        let asset =   player.currentItem?.asset
        
        let imageGenerator = AVAssetImageGenerator(asset: asset!)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize.init(width: 720, height: 1280)
        imageGenerator.requestedTimeToleranceAfter = kCMTimeZero
        let imageRef = try! imageGenerator.copyCGImage(at: player.currentTime(), actualTime: nil)
        stillImage.image = UIImage(cgImage: imageRef)
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        self.sampleTime = Int.init(CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds)
        DispatchQueue.main.async { [unowned self] in
            self.stillImage.image = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            if self.sampleTime! % 60 == 0{
                Face().detectEmotion(self.stillImage.image!, returnFaceId: true, returnFaceLandmarks: true, completion: { (results) in
                    DispatchQueue.main.async { [unowned self] in
                    self.textViewDescription.text = results
                    }
                })
            }
        }
    }
    
    func imageFromSampleBuffer(sampleBuffer:CMSampleBuffer!) -> UIImage {
        let  imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!);
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!);
        let width = CVPixelBufferGetWidth(imageBuffer!);
        let height = CVPixelBufferGetHeight(imageBuffer!);
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        let quartzImage = context?.makeImage();
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
        
        let image = flipImageVertically(originalImage: UIImage.init(cgImage: quartzImage!));
        
        return (image);
    }
    func flipImageVertically(originalImage:UIImage) -> UIImage {
        let image:UIImage = UIImage(cgImage: originalImage.cgImage!, scale: 1.0, orientation: UIImageOrientation.right)
        return image
    }
}
extension UIImage
{
    // Translated from <https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/06_MediaRepresentations.html#//apple_ref/doc/uid/TP40010188-CH2-SW4>
    convenience init?(fromSampleBuffer sampleBuffer: CMSampleBuffer)
    {
        
        guard let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        if CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0)) != kCVReturnSuccess { return nil }
        defer { CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0)) }
        
        
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(imageBuffer),
            width: CVPixelBufferGetWidth(imageBuffer),
            height: CVPixelBufferGetHeight(imageBuffer),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(imageBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        guard let quartzImage = context!.makeImage() else { return nil }
         self.init(cgImage: quartzImage)
    }
    
}
