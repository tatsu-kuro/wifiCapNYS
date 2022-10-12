//
//  How2ViewController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2020/12/07.
//

import UIKit

class How2ViewController: UIViewController {
    let someFunctions = myFunctions()
    var helpNumber:Int=0
    var helpHlimit:CGFloat=0
    var posYlast:CGFloat=0
    var targetMode:Int = 0
    
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var helpView: UIImageView!

    func setHelpImage(){
        let left=CGFloat(UserDefaults.standard.float(forKey: "leftPadding"))
        let right=CGFloat(UserDefaults.standard.float(forKey: "rightPadding"))
        let top=CGFloat(UserDefaults.standard.float(forKey: "topPadding"))
        let bottom=CGFloat(UserDefaults.standard.float(forKey: "bottomPadding"))
         if someFunctions.firstLang().contains("ja"){
            helpView.image = UIImage(named:"helpNew")
        }else{
            helpView.image=UIImage(named: "helpEn")
        }
        // 画像の縦横サイズを取得
        var imgWidth:CGFloat = helpView.image!.size.width
          var imgHeight:CGFloat = helpView.image!.size.height
  
         // 画像サイズをスクリーン幅に合わせる
        let scale:CGFloat = imgHeight / imgWidth
        let helpWidth=view.bounds.width-left-right
        helpView.frame=CGRect(x:left,y:top,width:helpWidth,height: helpWidth*scale)
    }
 
     override func viewDidLoad() {
        super.viewDidLoad()
        
        
          let top=CGFloat(UserDefaults.standard.float(forKey: "topPadding"))
          let bottom=CGFloat(UserDefaults.standard.float(forKey: "bottomPadding"))
          let left=CGFloat(UserDefaults.standard.float(forKey: "leftPadding"))
          let right=CGFloat(UserDefaults.standard.float(forKey: "rightPadding"))
      
          let ww=view.bounds.width-(left+right)
          let wh=view.bounds.height-(top+bottom)
          let sp=ww/120//間隙
          let bw=(ww-sp*10)/7//ボタン幅
          let bh=bw*170/440
          let by=wh-bh-sp
          someFunctions.setButtonProperty(exitButton,x:left+bw*6+sp*8,y:by,w:bw,h:bh,UIColor.darkGray)
          helpView.frame=CGRect(x:left+2*sp,y:2*sp,width: ww-4*sp,height: wh-bh-3*sp)
          if UIApplication.shared.isIdleTimerDisabled == true{
              UIApplication.shared.isIdleTimerDisabled = false//監視する
          }
          helpNumber=0
          setHelpImage()
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    @IBAction func panGesture(_ sender: UIPanGestureRecognizer) {
        let move:CGPoint = sender.translation(in: self.view)
        let height=helpView.frame.size.height
        let exitY=exitButton.frame.minY
        if sender.state == .began {
            posYlast=helpView.frame.origin.y
        }else if sender.state == .changed {
            helpView.frame.origin.y = posYlast + move.y
            if helpView.frame.origin.y > 0{
                helpView.frame.origin.y=0
            }else if helpView.frame.origin.y < -height+exitY{
                helpView.frame.origin.y = -height+exitY//view.bounds.height-exitY
            }
            print("helpview:",helpView.frame.origin.y,move.y)
        }else if sender.state == .ended{
        }
    }
    
}
