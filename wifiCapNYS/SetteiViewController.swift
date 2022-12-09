//
//  SetteiViewController.swift
//  wifiCapNYS
//
//  Created by 黒田建彰 on 2022/12/07.
//

import UIKit

class SetteiViewController: UIViewController {
     
    @IBOutlet weak var urlInputField: UITextField!
    @IBOutlet weak var urlLabelText: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        urlLabelText.text = myFunctions().getUserDefaultString(str: "urlAdress", ret: "http://192.168.82.1")
        urlInputField.text=urlLabelText.text
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onEditingChanged(_ sender: Any) {
        urlLabelText.text=urlInputField.text
        UserDefaults.standard.set(urlLabelText.text, forKey:"urlAdress")
    }
  
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
