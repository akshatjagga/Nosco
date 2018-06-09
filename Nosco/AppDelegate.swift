//
//  AppDelegate.swift
//  Nosco
//
//  Created by Akshat Jagga on 28/05/18.
//  Copyright © 2018 Akshat Jagga. All rights reserved.
//

import UIKit
import YPImagePicker
var imagetransfer : UIImage = UIImage()
var statusofCameraImage = 0
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {
    
    var selectedItems = [YPMediaItem]()

    var window: UIWindow?

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        if viewController is SecondViewController {

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
            
            picker.didFinishPicking { items, cancelled in
                

                if cancelled {

                cancelpickingimage = 1
                    statusofCameraImage = 0
                }
                
                else {
                    cancelpickingimage = 0
                    statusofCameraImage = 1
                    self.selectedItems = items
                    imagetransfer = (items.singlePhoto?.image)!

                }
                
                    
                
                picker.dismiss(animated: true, completion: nil)
            }
            
             tabBarController.present(picker, animated: true)
            
       return false
            
            
        }
    return true
            
    }

    
        


  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

