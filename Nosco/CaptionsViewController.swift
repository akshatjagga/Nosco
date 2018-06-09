//
//  CaptionsViewController.swift
//  Nosco
//
//  Created by Akshat Jagga on 29/05/18.
//  Copyright © 2018 Akshat Jagga. All rights reserved.
//

import UIKit
import TransitionButton

class CaptionsViewController: UIViewController {
    
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var imageViewCaptions: UIImageView! {
        didSet {
            imageViewCaptions.layer.cornerRadius = 10
        }
    }
    @IBOutlet weak var shareButton: UIButton! {
    
    didSet {
    shareButton.layer.cornerRadius = shareButton.frame.height/2
    }
    
    }
    
    
    var customBlurEffectStyle: UIBlurEffectStyle!
    var customInitialScaleAmmount: CGFloat!
    var customAnimationDuration: TimeInterval!
    
    
    
    @IBAction func dismissButoon(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        
         dismiss(animated: true, completion: nil)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
 
       // captionLabel.text = mlText.dropFirst(18)
        
      let modifiedMLText =  mlText.dropFirst(21)
        
        captionLabel.text = String(modifiedMLText) as String
        
        imageViewCaptions.image = captionImage
        
        modalPresentationCapturesStatusBarAppearance = true

        
        // Do any additional setup after loading the view.
    }
    
   
    @IBOutlet weak var popupContentContainerView : UIView!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


extension CaptionsViewController : MIBlurPopupDelegate {
    var popupView: UIView {
        return popupContentContainerView ?? UIView()
    }
    
    var blurEffectStyle: UIBlurEffectStyle {
        return customBlurEffectStyle
    }
    
    var initialScaleAmmount: CGFloat {
        return customInitialScaleAmmount
    }
    
    var animationDuration: TimeInterval {
       return customAnimationDuration
    }
    
    
    
    
    
}

