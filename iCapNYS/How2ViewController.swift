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
        exitButton.layer.borderColor = UIColor.black.cgColor
        exitButton.layer.borderWidth = 1.0
        exitButton.layer.cornerRadius = 10
//        nextButton.isHidden=true
        nextButton.layer.borderColor = UIColor.black.cgColor
        nextButton.layer.borderWidth = 1.0
        nextButton.layer.cornerRadius = 10
        helpView.image = UIImage(named: "help")
        // Do any additional setup after loading the view.
    }
    var helpNum:Int = 0
    @IBAction func onNextButton(_ sender: Any) {
        helpNum += 1
        if helpNum%2 == 0{
            helpView.image = UIImage(named: "help")
        }else{
            helpView.image = UIImage(named:"help4")
        }
        
    }
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var exitButton: UIButton!
    
    @IBOutlet weak var helpView: UIImageView!
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
