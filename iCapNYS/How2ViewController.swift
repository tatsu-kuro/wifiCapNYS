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
    //    override var shouldAutorotate: Bool {
//        return false
//    }
//
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        let landscapeSide=someFunctions.getUserDefaultInt(str: "landscapeSide", ret: 0)
//        if landscapeSide==0{
//            return UIInterfaceOrientationMask.landscapeRight
//        }else{
//            return UIInterfaceOrientationMask.landscapeLeft
//        }
//    }
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
        nextButton.frame=CGRect(x:x0,y:by,width:bw,height:bh)//,UIColor.darkGray)

        exitButton.layer.borderColor = UIColor.black.cgColor
        exitButton.layer.borderWidth = 1.0
        exitButton.layer.cornerRadius = 5
//        nextButton.isHidden=true
        nextButton.layer.borderColor = UIColor.black.cgColor
        nextButton.layer.borderWidth = 1.0
        nextButton.layer.cornerRadius = 5
        helpView.frame=CGRect(x:x0,y:topPadding+sp,width: ww-4*sp,height: wh-2*sp)
        helpView.image = UIImage(named: "helpnew")
        // Do any additional setup after loading the view.
        upDownLabel.isHidden=true

        if helpNum==999{
            nextButton.isHidden=true
            helpView.isHidden=true
//            helpView.image = UIImage(named:"helpnew2")
            exitButton.setTitle("OK", for: .normal)
            
            upDownLabel.isHidden=false
        }
    }
    var helpNum:Int = 0
    @IBAction func onNextButton(_ sender: Any) {
        helpNum += 1
        if helpNum%2 == 0{
            helpView.image = UIImage(named: "helpnew")
        }else{
            helpView.image = UIImage(named:"helpnew2")
        }
        
    }
    @IBOutlet weak var nextButton: UIButton!
    
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
