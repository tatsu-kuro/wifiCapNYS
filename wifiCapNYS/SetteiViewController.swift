//
//  SetteiViewController.swift
//  wifiCapNYS
//
//  Created by 黒田建彰 on 2022/12/07.
//

import UIKit

class SetteiViewController: UIViewController {
     
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var maxTimeLabel: UILabel!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var maxTimeSwitch: UISwitch!
    @IBOutlet weak var urlInputField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        urlInputField.text=myFunctions().getUserDefaultString(str: "urlAdress", ret: "http://192.168.82.1")
        maxTimeSwitch.isOn=myFunctions().getUserDefaultBool(str: "maxTimeLimit", ret: true)
        // Do any additional setup after loading the view.
        let leftPadding=CGFloat( UserDefaults.standard.integer(forKey:"leftPadding"))
        let rightPadding=CGFloat(UserDefaults.standard.integer(forKey:"rightPadding"))
        let topPadding=CGFloat(UserDefaults.standard.integer(forKey:"topPadding"))
        let bottomPadding=CGFloat(UserDefaults.standard.integer(forKey:"bottomPadding"))
        let realWidth=view.bounds.width-leftPadding-rightPadding
        let realHeight=view.bounds.height-topPadding-bottomPadding/2

        let height:CGFloat=0//CGFloat(camera.getUserDefaultFloat(str: "buttonsHeight", ret: 0))
        let sp=realWidth/120//間隙
        let bw=(realWidth-sp*10)/7//ボタン幅
        let bh=bw*240/440
        let x0=leftPadding+sp*2
        myFunctions().setButtonProperty(exitButton,x:x0+bw*6+sp*6,y:topPadding+sp,w:bw,h:bh,UIColor.darkGray)
        myFunctions().setLabelProperty(urlLabel, x: leftPadding+2*sp, y: topPadding+sp, w: bw, h: bh, UIColor.systemGray2)
//        urlLabel.frame=CGRect(x:leftPadding + 2*sp,y:topPadding+sp,width:bw,height: bh)
        urlInputField.frame=CGRect(x:urlLabel.frame.maxX+sp,y:topPadding+sp,width:exitButton.frame.minX-urlLabel.frame.maxX-2*sp,height: bh)
        maxTimeSwitch.frame=CGRect(x:leftPadding+2*sp,y:bh+2*sp,width: 30,height: bh)
        maxTimeLabel.frame=CGRect(x:maxTimeSwitch.frame.maxX+sp,y:bh+2*sp,width:200,height: maxTimeSwitch.frame.height)
//        exitButton.frame=CGRect(x:)
//        let by1=realHeight-bh-sp-height-bh*2/3
//        let by=realHeight-(bh+sp)*2-height-bh*2/3
//        let x0=leftPadding+sp*2

    }
    
    @IBAction func onEditingChanged(_ sender: Any) {
        UserDefaults.standard.set(urlInputField.text, forKey:"urlAdress")
    }
  
    @IBAction func onMaxTime(_ sender: Any) {
        UserDefaults.standard.set(maxTimeSwitch.isOn,forKey:"maxTimeLimit")
    }
    
    /*
     if showRect==0{
         showRectSwitch.isOn=false
     }else{
         showRectSwitch.isOn=true
     }
     @IBAction func onShowRect(_ sender: Any) {
         if showRectSwitch.isOn{
             showRect=1
         }else{
             showRect=0
         }
         setUserDefaults()
     }
     
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
