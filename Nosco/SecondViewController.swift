//
//  SecondViewController.swift
//  Nosco
//
//  Created by Akshat Jagga on 28/05/18.
//  Copyright © 2018 Akshat Jagga. All rights reserved.
//

import UIKit
import YPImagePicker
import TransitionButton

class SecondViewController: UIViewController {
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        if tabBarController?.selectedIndex == 0 {
            
        }
        else{
            
        
        var config = YPImagePickerConfiguration()
        config.libraryMediaType = .photo
        config.onlySquareFromLibrary = false
        config.onlySquareImagesFromCamera = true
        // config.targetImageSize = .original
        config.libraryTargetImageSize = .original
        config.usesFrontCamera = false
        config.showsFilters = true
        config.filters = [YPFilterDescriptor(name: "Original", filterName: ""),
                          YPFilterDescriptor(name: "Mono", filterName: "CIPhotoEffectMono"),YPFilterDescriptor(name: "Blue Lagoon", filterName: "CIPhotoEffectProcess") , YPFilterDescriptor(name: "Chrome", filterName: "CIPhotoEffectChrome"),YPFilterDescriptor(name: "Noir", filterName: "CIPhotoEffectNoir"),YPFilterDescriptor(name: "Touché", filterName: "CIPhotoEffectTransfer"),YPFilterDescriptor(name: "Tonal", filterName: "CIPhotoEffectTonal")]
        config.shouldSaveNewPicturesToAlbum = true
        //  config.videoCompression = AVAssetExportPresetHighestQuality
        
        config.albumName = "Nosco"
        config.screens = [.library ,.photo]
        config.startOnScreen = .photo
        //        config.videoRecordingTimeLimit = 10
        //        config.videoFromLibraryTimeLimit = 20
        config.wordings.libraryTitle = "Camera Roll"
        config.hidesStatusBar = false
        //   config.overlayView = myOverlayView
        config.maxNumberOfItems = 1
        
        
        
        let picker = YPImagePicker(configuration: config)
        
        YPImagePickerConfiguration.shared = config
        
        picker.didFinishPicking { items, _ in
            if let photo = items.singlePhoto {
                print(photo.fromCamera) // Image source (camera or library)
                print(photo.image) // Final image selected by the user
                print(photo.originalImage) // original image selected by the user, unfiltered
                print(photo.modifiedImage) // Transformed image, can be nil
                //        print(photo.exifMeta) // Print exif meta data of original image.
            }
            picker.dismiss(animated: true, completion: nil)
        }
        
        
        
        picker.didFinishPicking { items, cancelled in
            if cancelled {
                print("Picker was canceled")
                self.tabBarController?.selectedIndex = 0
            }
            picker.dismiss(animated: true, completion: nil)
        }
        
        
        
        
        present(picker, animated: true, completion: nil)
    }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

