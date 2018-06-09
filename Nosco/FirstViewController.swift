//
//  FirstViewController.swift
//  Nosco
//
//  Created by Akshat Jagga on 28/05/18.
//  Copyright © 2018 Akshat Jagga. All rights reserved.
//

import UIKit
import TransitionButton
import Agrume
import ChameleonFramework
import YPImagePicker
import CoreML
import Vision


var cancelpickingimage = 0

var captionImage = UIImage()

var mlText = ""

class FirstViewController: UIViewController {
    var selectedItems = [YPMediaItem]()
    
    
    var model : GoogLeNetPlaces!
    
     let showAndTell = ShowAndTell()

    
    @IBAction func openforZoomImage(_ sender: Any) {
        let agrume = Agrume(image: (imageView.image)!)
        agrume.show(from : self)
        
        
    }
    @IBOutlet weak var imageView: UIImageView!
    
   var button = TransitionButton()
    var  button2 = TransitionButton()
    
    
    override func viewDidLoad() {
        
        
        
    self.tabBarController?.delegate = UIApplication.shared.delegate as? UITabBarControllerDelegate

        
        self.view.addSubview( button2)
        self.view.addSubview(button)
       
         button2.translatesAutoresizingMaskIntoConstraints = false
         button2.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
      //  button.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 200).isActive = true
        
        button2.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -200).isActive = true

        
        button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -125).isActive = true
       
         button2.widthAnchor.constraint(equalTo: view.widthAnchor, constant : -100).isActive = true

       // button.widthAnchor.constraint(equalToConstant: 200).isActive = true
        button.widthAnchor.constraint(equalTo: view.widthAnchor, constant : -100).isActive = true
        
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
         button2.heightAnchor.constraint(equalToConstant: 45).isActive = true

        
        
         button2.backgroundColor = UIColor.flatRed
         button2.setTitle("Choose Photo", for: .normal)
         button2.cornerRadius = 20
         button2.spinnerColor = .white

        button.backgroundColor = UIColor.flatMint
        button.setTitle("Generate Captions", for: .normal)
        button.cornerRadius = 20
        button.spinnerColor = .white
       // button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)

         button2.addTarget(self, action: #selector(button2Action), for: .touchUpInside)

        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    @objc func button2Action()
    {
        button2.startAnimation()

        let qualityOfServiceClass = DispatchQoS.QoSClass.background

        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        backgroundQueue.async(execute: {


            DispatchQueue.main.async(execute: { () -> Void in
                // 4: Stop the animation, here you have three options for the `animationStyle` property:
                // .expand: useful when the task has been compeletd successfully and you want to expand the button and transit to another view controller in the completion callback
                // .shake: when you want to reflect to the user that the task did not complete successfly
                // .normal
                var config = YPImagePickerConfiguration()
                config.libraryMediaType = .photo
                config.onlySquareFromLibrary = false
                config.onlySquareImagesFromCamera = true
                config.libraryTargetImageSize = .original
                config.usesFrontCamera = false
                config.showsFilters = true
                config.filters = [YPFilterDescriptor(name: "Original", filterName: ""),
                                  YPFilterDescriptor(name: "Mono", filterName: "CIPhotoEffectMono"),YPFilterDescriptor(name: "Blue Lagoon", filterName: "CIPhotoEffectProcess") , YPFilterDescriptor(name: "Chrome", filterName: "CIPhotoEffectChrome"),YPFilterDescriptor(name: "Noir", filterName: "CIPhotoEffectNoir"),YPFilterDescriptor(name: "Touché", filterName: "CIPhotoEffectTransfer"),YPFilterDescriptor(name: "Tonal", filterName: "CIPhotoEffectTonal")]
                config.shouldSaveNewPicturesToAlbum = true
                //  config.videoCompression = AVAssetExportPresetHighestQuality
                
                config.albumName = "Nosco"
                config.screens = [.library]
                config.startOnScreen = .library
                //        config.videoRecordingTimeLimit = 10
                //        config.videoFromLibraryTimeLimit = 20
                config.wordings.libraryTitle = "Camera Roll"
                config.hidesStatusBar = false
                //   config.overlayView = myOverlayView
                config.maxNumberOfItems = 1
                
                
                
                let picker = YPImagePicker(configuration: config)
                
                YPImagePickerConfiguration.shared = config
                
                picker.didFinishPicking { items, cancelled in
                    
                    
                    if cancelled {
                        print("ripppp")
                        cancelpickingimage = 1
                    }
                    else {
                        cancelpickingimage = 0
                        self.selectedItems = items
                        self.imageView.image = items.singlePhoto?.image
                    }
                    
                    picker.dismiss(animated: true, completion: nil)
                }
                
                
                
                self.present(picker, animated: true, completion: nil)


                self.button2.stopAnimation(animationStyle: .normal, completion: {

                  

                })
            })
        })


    }
    
    @objc func buttonAction()
    {
         button.startAnimation()
        
    
        let qualityOfServiceClass = DispatchQoS.QoSClass.background

        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        backgroundQueue.async(execute: {
            
            captionImage = self.imageView.image!
            
            
            UIGraphicsBeginImageContextWithOptions(CGSize(width: 224, height: 224), true, 1.0)
            self.imageView.image?.draw(in: CGRect(x: 0, y: 0, width: 224, height: 224))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            let attributes = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
            var pixelBuffer : CVPixelBuffer?
            let status = CVPixelBufferCreate(kCFAllocatorDefault, Int((newImage?.size.width)!), Int((newImage?.size.height)!), kCVPixelFormatType_32ARGB, attributes, &pixelBuffer)
            guard (status == kCVReturnSuccess) else {
                return
            }

            CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int((newImage?.size.width)!), height: Int((newImage?.size.height)!), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

            context?.translateBy(x: 0, y: (newImage?.size.height)!)
            context?.scaleBy(x: 1.0, y: -1.0)

            UIGraphicsPushContext(context!)
            newImage?.draw(in: CGRect(x: 0, y: 0, width: (newImage?.size.width)!, height: (newImage?.size.height)!))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            //self.imageView.image = newImage
            


         
            
            
            
            let results = self.showAndTell.predict(image: self.imageView.image!, beamSize: 1, maxWordNumber: 15)
           
                       var displayingResults = results.sorted(by: {$0.score > $1.score}).map({
               var x = $0.readAbleSentence.suffix($0.readAbleSentence.count - 1)
                if $0.sentence.last == Caption.endID {
                    _ = x.removeLast()
                }
                return String.init(format: "Probability:%.3f‱ \n \(x.joined(separator: " ").capitalized)", pow(2, $0.score) * 10000.0)
            }).joined(separator: "\n\n")
            
            
            sleep(3) // 3: Do your networking task or background work here.
            
            print(displayingResults)
            
            mlText = displayingResults

            
            DispatchQueue.main.async(execute: { () -> Void in
               
               

                
                self.button.stopAnimation(animationStyle: .normal, completion: {
                    
                    self.performSegue(withIdentifier: "captionsVC", sender: nil)
                    
                })
            })
        })
    }
        
        
    override func viewDidAppear(_ animated: Bool) {
        if statusofCameraImage == 1 {
            imageView.image = imagetransfer
            statusofCameraImage = 0
        }
     
        

    }
    
    
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: nil)
        
        guard let popupViewController = segue.destination as? CaptionsViewController else {
            
            
            return }
        
        popupViewController.customBlurEffectStyle = .dark
        
        popupViewController.customAnimationDuration = TimeInterval(0.5)
        popupViewController.customInitialScaleAmmount = 0.3
        print("hello")
        
    }


}

