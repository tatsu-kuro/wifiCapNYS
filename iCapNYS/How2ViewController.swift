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
        //topPadding = 0 always?
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
        let x0=leftPadding+sp*2
        
        exitButton.frame=CGRect(x:x0+bw*6+sp*6,y:by,width:bw,height:bh)//,UIColor.darkGray)
        exitButton.layer.borderColor = UIColor.black.cgColor
        exitButton.layer.borderWidth = 1.0
        exitButton.layer.cornerRadius = 5
        helpView.frame=CGRect(x:x0,y:topPadding+sp,width: ww-4*sp,height: by-sp)//wh-bh)
        if firstLang().contains("ja"){
            helpView.image=UIImage(named:"help")
        }else{
            helpView.image=UIImage(named:"helpEn")
        }
    }
    func firstLang() -> String {
        let prefLang = Locale.preferredLanguages.first
        return prefLang!
    }

    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var helpView: UIImageView!
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
}
