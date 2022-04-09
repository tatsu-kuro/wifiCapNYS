//
//  How2ViewController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2020/12/07.
//

import UIKit

class How2ViewController: UIViewController {
    let someFunctions = myFunctions()
    
    @IBOutlet weak var upDownLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let leftPadding=CGFloat( UserDefaults.standard.integer(forKey:"leftPadding"))
        let rightPadding=CGFloat(UserDefaults.standard.integer(forKey:"rightPadding"))
        let topPadding=CGFloat(UserDefaults.standard.integer(forKey:"topPadding"))
        let bottomPadding=CGFloat(UserDefaults.standard.integer(forKey:"bottomPadding"))/2
        let ww:CGFloat=view.bounds.width-leftPadding-rightPadding
        let wh:CGFloat=view.bounds.height-topPadding-bottomPadding
        let sp=ww/120//間隙
        let bw=(ww-sp*10)/7//ボタン幅
        let bh=bw*170/440
        let by=wh-bh-sp
//        let by1=wh-(bh+sp)*2+1.5*sp
        let x0=leftPadding+sp*2
        
        exitButton.frame=CGRect(x:x0+bw*6+sp*6,y:by,width:bw,height:bh)//,UIColor.darkGray)
//        nextButton.frame=CGRect(x:x0,y:by,width:bw,height:bh)//,UIColor.darkGray)

        exitButton.layer.borderColor = UIColor.black.cgColor
        exitButton.layer.borderWidth = 1.0
        exitButton.layer.cornerRadius = 5
//        nextButton.layer.borderColor = UIColor.black.cgColor
//        nextButton.layer.borderWidth = 1.0
//        nextButton.layer.cornerRadius = 5
        helpView.frame=CGRect(x:x0,y:topPadding+sp,width: ww-4*sp,height: by)//wh-bh)
        if firstLang().contains("ja"){
//            if helpNum%2==1{
                helpView.image=UIImage(named:"help")
//            }else{
//                helpView.image=UIImage(named:"help2")
//            }
        }else{
//            if helpNum%2==1{
                helpView.image=UIImage(named:"helpEn")
//            }else{
//                helpView.image=UIImage(named:"help2En")
//            }
        }

        
        
        
//        if firstLang().contains("ja"){
//            helpNum = -1
//           }else{
//            helpNum = 1
//        }
//        onNextButton(0)
//        upDownLabel.isHidden=true
//        if helpNum==999{
//            nextButton.isHidden=true
//            helpView.isHidden=true
//            exitButton.setTitle("OK", for: .normal)
//            upDownLabel.isHidden=false
//        }
    }
    func firstLang() -> String {
        let prefLang = Locale.preferredLanguages.first
        return prefLang!
    }
    
//    var helpNum:Int = 0
//    @IBAction func onNextButton(_ sender: Any) {
////        helpNum += 1
//        if firstLang().contains("ja"){
////            if helpNum%2==1{
//                helpView.image=UIImage(named:"help")
////            }else{
////                helpView.image=UIImage(named:"help2")
////            }
//        }else{
////            if helpNum%2==1{
//                helpView.image=UIImage(named:"helpEn")
////            }else{
////                helpView.image=UIImage(named:"help2En")
////            }
//        }
////        if helpNum%4 == 0{
////            helpView.image = UIImage(named: "help")
////        }else if helpNum%4 == 1{
////            helpView.image = UIImage(named:"help2")
////        }else if helpNum%4 == 2{
////            helpView.image = UIImage(named:"helpEn")
////        }else{
////            helpView.image = UIImage(named:"help2En")
////        }
//        
//    }
//    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var exitButton: UIButton!
    
    @IBOutlet weak var helpView: UIImageView!
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
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
