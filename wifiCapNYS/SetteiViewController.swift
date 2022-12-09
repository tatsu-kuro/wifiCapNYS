//
//  SetteiViewController.swift
//  wifiCapNYS
//
//  Created by 黒田建彰 on 2022/12/07.
//

import UIKit

class SetteiViewController: UIViewController {
     
    @IBOutlet weak var maxTimeSwitch: UISwitch!
    @IBOutlet weak var urlInputField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        urlInputField.text=myFunctions().getUserDefaultString(str: "urlAdress", ret: "http://192.168.82.1")
        maxTimeSwitch.isOn=myFunctions().getUserDefaultBool(str: "maxTimeLimit", ret: true)
        // Do any additional setup after loading the view.
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
