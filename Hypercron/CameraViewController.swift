//
//  CameraViewController.swift
//  Hypercron
//
//  Created by Dennis Beatty on 11/12/16.
//  Copyright © 2016 Dennis Beatty. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {
    
    var captureSession : AVCaptureSession?
    var videoPreviewLayer : AVCaptureVideoPreviewLayer?
    var photoOutput : AVCapturePhotoOutput?
    var error : NSError? = nil
    
    @IBOutlet weak var captureButton: UIImageView!
    @IBOutlet weak var overlayImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make sure the app has permission to access the device's camera
        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == .denied {
            error = NSError(domain: "Camera", code: 1, userInfo: nil)
            return
        }
        
        // Load the latest image into the overlay
        PHPhotoLibrary.loadLatestFromAlbum(albumName: "Hypercron", size: overlayImageView.frame.size, completion: {
            image in
            DispatchQueue.main.async(execute: {
                self.overlayImageView.image = image
            })
        })
        
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        // Get an instance of the AVCaptureDeviceInput class using the previous device object
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice) as AVCaptureDeviceInput
            
            // Initialize the captureSession object
            captureSession = AVCaptureSession()
            captureSession?.sessionPreset = AVCaptureSessionPreset1920x1080
            
            // Set the input device on the captureSession
            captureSession?.addInput(input as AVCaptureInput)
            
            // Setup the output stream
            photoOutput = AVCapturePhotoOutput()
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecJPEG])
            photoOutput?.setPreparedPhotoSettingsArray([settings], completionHandler: nil)
            captureSession?.addOutput(photoOutput)
        }
        catch let error as NSError {
            // If any error occurs, store it for popup display and don't continue any further
            self.error = error
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the view preview view's layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        // Start video capture
        captureSession?.startRunning()
        
        // Bring UI to the front
        view.bringSubview(toFront: overlayImageView)
        view.bringSubview(toFront: captureButton)
        
        // Give the capture button a tap event
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CameraViewController.capturePhoto(gestureRecognizer:)))
        captureButton.isUserInteractionEnabled = true
        captureButton.addGestureRecognizer(tapGestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // check if there was an error while loading the view
        if error != nil {
            
            // if there was see if it came from the camera
            if error!.domain == "Camera" {
                
                // if it did create a popup asking the user to give permission to use the camera
                let alert = UIAlertController(
                    title: "Permissions Error",
                    message: "Camera access is required in order to take photos",
                    preferredStyle: UIAlertControllerStyle.alert
                )
                alert.addAction(UIAlertAction(title: "Allow Camera", style: .cancel, handler: { (alert) -> Void in
                    UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
                }))
                present(alert, animated: true, completion: nil)
            } else {
                
                // otherwise just use a basic popup
                let alert = UIAlertController(title: error?.localizedDescription, message: error?.localizedRecoverySuggestion, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                }))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    @IBAction func capturePhoto(gestureRecognizer: UITapGestureRecognizer) {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecJPEG])
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if photoSampleBuffer != nil {
            let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
            let dataProvider = CGDataProvider(data: imageData as! CFData)
            let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.relativeColorimetric)
            
            let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: .right)
            
            self.overlayImageView.image = image
            
            PHPhotoLibrary.saveImage(image: image, albumName: "Hypercron", completion: { _ in })
        }
    }
}

