//
//  How2ViewController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2020/12/07.
//

import UIKit

class How2ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        how2Button.layer.borderColor = UIColor.green.cgColor
        how2Button.layer.borderWidth = 1.0
        how2Button.layer.cornerRadius = 10
        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var how2Button: UIButton!
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
