//
//  RecordViewController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2020/09/22.
//

import UIKit
//import AVKit
//import WebKit
import AVFoundation
import GLKit
import Photos
import CoreMotion
import VideoToolbox
//import MediaPlayer

extension UIColor {
    func image(size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill() // 色を指定
            rendererContext.fill(.init(origin: .zero, size: size)) // 塗りつぶす
        }
    }
}
class RecordViewController:UIViewController, CameraServiceDelegateProtocol {
    let camera = myFunctions()
    var cameraType:Int = 1//0
    var soundIdstart:SystemSoundID = 1117
    var soundIdstop:SystemSoundID = 1118
    var soundIdpint:SystemSoundID = 1109//1009//7
    var soundIdx:SystemSoundID = 0
    let albumName:String = "wifiCapNYS"
    var recordingFlag:Bool = false
    var saved2album:Bool = false
    var setteiMode:Int = 0//0:camera, 1:setteimanual, 2:setteiauto
    var autoRecordMode:Bool = false
    let motionManager = CMMotionManager()
    var currentBrightness:CGFloat=1.0
    var captureSession: AVCaptureSession!
    var videoDevice: AVCaptureDevice?

    //for video output
    var fileWriter: AVAssetWriter!
    var fileWriterInput: AVAssetWriterInput!
    var fileWriterAdapter: AVAssetWriterInputPixelBufferAdaptor!
    var startTimeStamp:Int64 = 0
    
    let TempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
    var newFilePath: String = ""
    var iCapNYSWidth: Int32 = 0
    var iCapNYSHeight: Int32 = 0
    var iCapNYSWidthF: CGFloat = 0
    var iCapNYSHeightF: CGFloat = 0
    var iCapNYSWidthF120: CGFloat = 0
    var iCapNYSHeightF5: CGFloat = 0
    var iCapNYSFPS: Float64 = 0
    //for gyro and face drawing
    var gyro = Array<Double>()
    let someFunctions = myFunctions()
    @IBOutlet weak var mjpegImage: UIImageView!

    func frame(image: UIImage) {
        mjpegImage.image = image
    }

    var cameraService: CameraService?
         
    override var shouldAutorotate: Bool {
        return false
    }
  
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let landscapeSide=someFunctions.getUserDefaultInt(str: "landscapeSide", ret: 0)
        if landscapeSide==0{
            return UIInterfaceOrientationMask.landscapeRight
        }else{
            return UIInterfaceOrientationMask.landscapeLeft
        }
    }
    var quater0:Double=0
    var quater1:Double=0
    var quater2:Double=0
    var quater3:Double=0
    var readingFlag = false
    var timer:Timer?
    var timer_motion:Timer?
    var tapFlag:Bool=false//??
    var flashFlag=false
    
    var rpk1 = Array(repeating: CGFloat(0), count:500)
    var ppk1 = Array(repeating: CGFloat(0), count:500)//144*3
    var facePoints:[Int] = [//x1,y1,0, x2,y2,0, x3,y3,1, x4,y4,0  の並びは   MoveTo(x1,y1)  LineTo(x2,y2)  LineTo(x3,y3)  MoveTo(x4,y4) と描画される
        0,0,0, 15,0,0, 30,0,0, 45,0,0, 60,0,0, 75,0,0, 90,0,0, 105,0,0, 120,0,0, 135,0,0, 150,0,0, 165,0,0,//horizon 12
        180,0,0, 195,0,0, 210,0,0, 225,0,0, 240,0,0, 255,0,0, 270,0,0, 285,0,0, 300,0,0, 315,0,0, 330,0,0, 345,0,0, 360,0,1,//horizon 12+13=25
        0,0,0, 0,15,0, 0,30,0, 0,45,0, 0,60,0, 0,75,0, 0,90,0, 0,105,0, 0,120,0, 0,135,0, 0,150,0, 0,165,0,//vertical 25+12
        0,180,0, 0,195,0, 0,210,0, 0,225,0, 0,240,0, 0,255,0, 0,270,0, 0,285,0, 0,300,0, 0,315,0, 0,330,0, 0,345,0, 0,360,1,//virtical 37+13=50
        0,90,0, 15,90,0, 30,90,0, 45,90,0, 60,90,0, 75,90,0, 90,90,0, 105,90,0, 120,90,0, 135,90,0, 150,90,0, 165,90,0,//coronal 50+12=62
        180,90,0, 195,90,0, 210,90,0, 225,90,0, 240,90,0, 255,90,0, 270,90,0, 285,90,0, 300,90,0, 315,90,0, 330,90,0, 345,90,90, 360,90,1,//coronal 62+13=75
        20,-90,0, 20,-105,0, 20,-120,0, 20,-135,0, 20,-150,0, 20,-165,0, 20,-180,1,
        //hair 75+7=82
        -20,-90,0, -20,-105,0, -20,-120,0, -20,-135,0, -20,-150,0, -20,-165,0, -20,-180,1,//hair 82+7=89
        40,-90,0, 40,-105,0, 40,-120,0, 40,-135,0, 40,-150,0, 40,-165,0, 40,-180,1,
        //hair 89+7=96
        -40,-90,0, -40,-105,0, -40,-120,0, -40,-135,0, -40,-150,0, -40,-165,0, -40,-180,1,//hair 96+7=103
        23,-9,0, 31,-12,0, 38,-20,0, 40,-31,0, 38,-41,0, 31,-46,0, 23,-45,0, 15,-39,0, 10,-32,0, 8,-23,0, 10,-16,0, 15,-10,0, 23,-9,1,//eye +13
        -23,-9,0, -31,-12,0, -38,-20,0, -40,-31,0, -38,-41,0, -31,-46,0, -23,-45,0, -15,-39,0, -10,-32,0, -8,-23,0, -10,-16,0, -15,-10,0, -23,-9,1,//eye +13
        22,-26,0, 23,-25,0, 24,-24,1,//eye dots 3
        -22,-26,0, -23,-25,0, -24,-24,1,//eye dots 3
        -19,32,0, -14,31,0, -9,31,0, -4,31,0, 0,30,0, 4,31,0, 9,31,0, 14,31,0, 19,32,1]//mouse 9
    
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!

    
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var quaternionView: UIImageView!
//    @IBOutlet weak var cameraView:UIImageView!
   
    @IBOutlet weak var hatenaButton: UIButton!
    func killTimer(){
        if timer?.isValid == true {
            timer!.invalidate()
        }
        if timer_motion?.isValid == true {
            timer_motion!.invalidate()
        }
    }
    
  
     func getUserDefault(str:String,ret:Int) -> Int{//getUserDefault_one
         if (UserDefaults.standard.object(forKey: str) != nil){//keyが設定してなければretをセット
             return UserDefaults.standard.integer(forKey:str)
         }else{
             UserDefaults.standard.set(ret, forKey: str)
             return ret
         }
     }
    
    var leftPadding:CGFloat=0
    var rightPadding:CGFloat=0
    var topPadding:CGFloat=0
    var bottomPadding:CGFloat=0
    var realWidth:CGFloat=0
    var realHeight:CGFloat=0
//    func loadWebView(){
//        /*
//        let myURL1 = URL(string: "https://www.youtube.com/embed/live_stream?channel=UCMvoqnZFzcPubp4zErbDYlQ&amp;autoplay=1&amp;mute=1&amp;controls=0&amp;showinfo=0&amp;mute=1&amp;playsinline=1")
//        let myURL2 = URL(string:"http://192.168.82.1")
//        let myURL3 = URL(string: "https://www.shaku6.com/temp/temp.html")
//        let myURL4 = URL(string: "http://192.168.0.8:9000")
//         */
//        let URL=URL(string:myFunctions().getUserDefaultString(str: "urlAdress", ret: "http://192.168.82.1"))
//        ipWebView.load(URLRequest(url: URL!))
//    }

    @IBAction func onHatenaButton(_ sender: Any) {
//        ipWebView.scrollView.zoom(to: CGRect(x:330,y:8,width: 320,height: 240), animated: true)
//        ipWebView.scrollView.zoom(to: CGRect(x:150,y:0,width: 300,height: 225), animated: true)
        dispFilesInDoc()
        print("dispfilesindoc")

    }
    var maxTimeLimit:Bool=true
    override func viewDidLoad() {
        super.viewDidLoad()
        leftPadding=CGFloat( UserDefaults.standard.integer(forKey:"leftPadding"))
        rightPadding=CGFloat(UserDefaults.standard.integer(forKey:"rightPadding"))
        topPadding=CGFloat(UserDefaults.standard.integer(forKey:"topPadding"))
        bottomPadding=CGFloat(UserDefaults.standard.integer(forKey:"bottomPadding"))
        realWidth=view.bounds.width-leftPadding-rightPadding
        realHeight=view.bounds.height-topPadding-bottomPadding/2
        camera.makeAlbum()
        set_rpk_ppk()
        setMotion()

        setButtons()
        startButton.isHidden=false
        stopButton.isHidden=true
//        let left=(realWidth-realHeight*320/240)/2
//        mjpegImage.frame=CGRect(x:leftPadding+left,y: topPadding,width:realHeight*320/240,height:realHeight)
        cameraService = CameraService(delegate: self)
        let cameraURL =  URL(string:myFunctions().getUserDefaultString(str: "urlAdress", ret: "http://192.168.82.1"))

        cameraService!.play(url: cameraURL!)
//        mjpegImage.frame=CGRect(x:leftPadding+left,y: topPadding,width:realHeight*320/240,height:realHeight)
//        quaternionView.frame=CGRect(x:leftPadding+left+15,y:topPadding+5,width: realHeight/5,height: realHeight/5)
        self.view.bringSubviewToFront(quaternionView)
        timer_motion = Timer.scheduledTimer(timeInterval: 1/30, target: self, selector: #selector(self.update_motion), userInfo: nil, repeats: true)
        maxTimeLimit=myFunctions().getUserDefaultBool(str: "maxTimeLimit", ret: true)

    }

     override var prefersStatusBarHidden: Bool {
        return true
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
 
    var timerCnt:Int=0
    @objc func update(tm: Timer) {
        timerCnt += 1
        currentTime.text=String(format:"%01d",(timerCnt)/60) + ":" + String(format: "%02d",(timerCnt)%60)
//        if timerCnt%2==1{
//            stopButton.tintColor=UIColor.systemRed
//        }else{
//            stopButton.tintColor=UIColor.systemOrange
//        }
//        maxTimeSwitch.isOn=myFunctions().getUserDefaultBool(str: "maxTimeLimit", ret: true)
        
        if maxTimeLimit && (timerCnt > 60*5){
            onClickStopButton(0)
        }
    }
    func dispFilesInDoc(){
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let contentUrls = try FileManager.default.contentsOfDirectory(at: documentDirectoryURL, includingPropertiesForKeys: nil)
            let files = contentUrls.map{$0.lastPathComponent}
            
            for i in 0..<files.count{
                print(files[i])
            }
        } catch {
            print("none?")
        }
    }
    /*
         startButton.frame=CGRect(x:x0+bw*6+sp*6,y:(realHeight-bw)/2,width: bw,height:bw)
     stopButton.frame=CGRect(x:x0+bw*6+sp*6,y:(realHeight-bw)/2,width: bw,height: bw)
     mjpegImage.frame=CGRect(x:capX,y:sp,width:capWidth,height:capHeight)

     */
    var capX:CGFloat=0
    var capWidth:CGFloat=0
    var capHeight:CGFloat=0
    /*
     func takeScreenShot() -> UIImage {
             let width: CGFloat = UIScreen.main.bounds.size.width
             let height: CGFloat = UIScreen.main.bounds.size.height
             let bW=view.bounds.width
             let bH=view.bounds.height
             let capHeight=bH*0.93//-topPadding-bottomPadding
             let capWidth=capHeight*4/3
             let size = CGSize(width: capWidth, height: capHeight)
             let capRect = CGRect(x:(capWidth-bW)/2,y:topPadding,width:width,height:height)
             UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
             view.drawHierarchy(in:capRect, afterScreenUpdates: true)
             let screenShotImage = UIGraphicsGetImageFromCurrentImageContext()!
             UIGraphicsEndImageContext()
             return screenShotImage
         }
     
    func takeScreenShot() -> UIImage {
            let width: CGFloat = UIScreen.main.bounds.size.width
            let height: CGFloat = UIScreen.main.bounds.size.height
            let bW=view.bounds.width
            let bH=view.bounds.height
            let capHeight=bH*0.93//-topPadding-bottomPadding
            let capWidth=capHeight*4/3
            let size = CGSize(width: capWidth, height: capHeight)
            let capRect = CGRect(x:(capWidth-bW)/2,y:topPadding,width:width,height:height)
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            view.drawHierarchy(in:capRect, afterScreenUpdates: true)
            let screenShotImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return screenShotImage
        }
    */
    func takeScreenShot() -> UIImage {
        let width: CGFloat = UIScreen.main.bounds.size.width
        let height: CGFloat = UIScreen.main.bounds.size.height
        let bW=view.bounds.width
        let bH=view.bounds.height
        let sp=realWidth/120//間隙
        let capHeight=bH*0.93
        let capWidth=capHeight*4/3
 //            let capX=x0+bw*6+sp*6-capWidth-sp
//        let capHeight=bH*0.93//-topPadding-bottomPadding
//        let capWidth=capHeight*4/3
        let size = CGSize(width: capWidth, height: capHeight)
        let capRect = CGRect(x:-capX,y:-sp,width:bW,height:bH)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        view.drawHierarchy(in:capRect, afterScreenUpdates: true)
        let screenShotImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return screenShotImage
    }
    func takeScreenShot1() -> UIImage {
        let width: CGFloat = UIScreen.main.bounds.size.width
        let height: CGFloat = UIScreen.main.bounds.size.height
        let capHeight=view.bounds.height-topPadding-bottomPadding
        let capWidth=capHeight*4/3
        let size = CGSize(width: capWidth, height: capHeight)
        let capRect = CGRect(x:(capWidth-width)/2,y:topPadding,width:view.bounds.width,height:view.bounds.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        view.drawHierarchy(in:capRect, afterScreenUpdates: true)
        let screenShotImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return screenShotImage
    }
    @objc func update_motion(tm: Timer) {
        readingFlag=true

        let qCG0=CGFloat(quater0)
        let qCG1=CGFloat(quater1)
        let qCG2=CGFloat(quater2)
        let qCG3=CGFloat(quater3)
        //        print(quater0,quater1,quater2,quater3)
        readingFlag=false
        let quaterImage = drawHead(width: realHeight/2.5, height: realHeight/2.5, radius: realHeight/5-1,qOld0:qCG0, qOld1: qCG1, qOld2:qCG2,qOld3:qCG3)
        DispatchQueue.main.async {
            self.quaternionView.image = quaterImage
            self.quaternionView.setNeedsLayout()
        }
        if recordingFlag==true{
            let image=takeScreenShot()
//            cameraView.image=image
           createSecond(image: image)
        }
    }
    func setMotion(){
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1 / 100//が最速の模様
        degreeAtResetHead = -1
        cameraType=1
        motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { [self] (motion, error) in
            guard let motion = motion, error == nil else { return }
            while self.readingFlag==true{
                usleep(1000)//0.001sec
            }
            let quat = motion.attitude.quaternion
            
            let landscapeSide=someFunctions.getUserDefaultInt(str: "landscapeSide", ret: 0)
            
            if landscapeSide==0{
                self.quater0 = quat.w
                self.quater1 = -quat.y
                self.quater2 = -quat.z
                self.quater3 = quat.x
            }else{
                self.quater0 = quat.w
                self.quater1 = quat.y
                self.quater2 = -quat.z
                self.quater3 = -quat.x
                
            }
            //degreeAtResetHead:モーションセンサーをリセットするときに-1とする。リセット時に-1なら,角度から０か１をセット
            //drawHeadで顔を描くとき利用する。
            if degreeAtResetHead == -1{
                if motion.gravity.z > 0{
                    degreeAtResetHead = cameraType != 0 ? 1:0
                }else{
                    degreeAtResetHead = cameraType != 0 ? 0:1
                }
            }
        })
    }
    
    func set_rpk_ppk() {
        let faceR:CGFloat = 40//hankei
        var frontBack:Int = 0
        cameraType=1
//        if cameraType == 0{//front camera
//            frontBack = 180
//        }
        // convert draw data to radian
        
        print("frontBack",frontBack)
        for i in 0..<facePoints.count/3 {
            rpk1[i*2] = CGFloat(facePoints[3 * i + 0]) * 0.01745329//pi/180
            rpk1[i*2+1] = CGFloat(facePoints[3 * i + 1]+frontBack) * 0.01745329//pi/180
        }
        // move (1,0,0) to each draw point
        for i in 0..<facePoints.count/3{
            ppk1[i*3] = 0
            ppk1[i*3+1] = faceR
            ppk1[i*3+2] = 0
        }
        // rotate all draw point based on draw data
        var dx,dy,dz:CGFloat
        for i in  0..<facePoints.count/3 {
            //rotateX
            dy = ppk1[i*3+1]*cos(rpk1[i*2]) - ppk1[i*3+2]*sin(rpk1[i*2])
            dz = ppk1[i*3+1]*sin(rpk1[i*2]) + ppk1[i*3+2]*cos(rpk1[i*2])
            ppk1[i*3+1] = dy;
            ppk1[i*3+2] = dz;
          //rotateZ
            dx = ppk1[i*3]*cos(rpk1[i*2+1])-ppk1[i*3+1]*sin(rpk1[i*2+1])
            dy = ppk1[i*3]*sin(rpk1[i*2+1]) + ppk1[i*3+1]*cos(rpk1[i*2+1])
            ppk1[i*3] = dx
            ppk1[i*3+1] = dy
            //rotateY
            dx =  ppk1[i*3] * cos(1.5707963) + ppk1[i*3+2] * sin(1.5707963)
            dz = -ppk1[i*3] * sin(1.5707963) + ppk1[i*3+2] * cos(1.5707963)
            ppk1[i*3]=dx
            ppk1[i*3+2]=dz
        }
    }
    //モーションセンサーをリセットするときに-1とする。リセット時に-1なら,角度から０か１をセット
    var degreeAtResetHead:Int=0//0:-90<&&<90 1:<-90||>90 -1:flag for get degree
    func drawHead(width w:CGFloat, height h:CGFloat, radius r:CGFloat, qOld0:CGFloat, qOld1:CGFloat, qOld2:CGFloat, qOld3:CGFloat)->UIImage{
//        print(String(format:"%.3f,%.3f,%.3f,%.3f",qOld0,qOld1,qOld2,qOld3))
        cameraType=1
        var ppk = Array(repeating: CGFloat(0), count:500)
        let faceX0:CGFloat = w/2;
        let faceY0:CGFloat = h/2;//center
        let faceR:CGFloat = r;//hankei
        let defaultRadius:CGFloat = 40.0
        let size = CGSize(width:w, height:h)
    
//        print("quat:",String(format: "%.2f %.2f %.2f %.2f",qOld0,qOld0,qOld2,qOld3))

//        // イメージ処理の開始
        for i in 0..<facePoints.count/3 {
            let x0:CGFloat = ppk1[i*3]
            let y0:CGFloat = ppk1[i*3+1]
            let z0:CGFloat = cameraType==0 ? -ppk1[i*3+2]:ppk1[i*3+2]
            var q0=qOld0
            var q1=qOld1
            var q2=qOld2
            var q3=qOld3
            var norm,mag:CGFloat!
            mag = CGFloat(sqrt(q0*q0 + q1*q1 + q2*q2 + q3*q3))
            if mag>CGFloat(Float.ulpOfOne){
                norm = 1 / mag
                q0 *= norm
                q1 *= norm
                q2 *= norm
                q3 *= norm
            }
            ppk[i*3] = x0 * (q0 * q0 + q1 * q1 - q2 * q2 - q3 * q3) + y0 * (2 * (q1 * q2 - q0 * q3)) + z0 * (2 * (q1 * q3 + q0 * q2))
            ppk[i*3+1] = x0 * (2 * (q1 * q2 + q0 * q3)) + y0 * (q0 * q0 - q1 * q1 + q2 * q2 - q3 * q3) + z0 * (2 * (q2 * q3 - q0 * q1))
            ppk[i*3+2] = x0 * (2 * (q1 * q3 - q0 * q2)) + y0 * (2 * (q2 * q3 + q0 * q1)) + z0 * (q0 * q0 - q1 * q1 - q2 * q2 + q3 * q3)
        }
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)

        let drawPath = UIBezierPath(arcCenter: CGPoint(x: faceX0, y:faceY0), radius: faceR, startAngle: 0, endAngle: CGFloat(Double.pi)*2, clockwise: true)
        // 内側の色
        UIColor.white.setFill()
//        // 内側を塗りつぶす
        drawPath.fill()

        let uraPoint=faceR/40.0//この値の意味がよくわからなかった

        var endpointF=true//終点でtrueとする
        if degreeAtResetHead == 1{//iPhoneが >90||<-90 垂直以上に傾いた時
            for i in 0..<facePoints.count/3-1{
                if endpointF==true{//始点に移動する
                    
                    if ppk[i*3+1] < uraPoint{
                        endpointF=true
                    }else{
                        endpointF=false
                    }
                    drawPath.move(to: CGPoint(x:faceX0+ppk[i*3]*faceR/defaultRadius,y:faceY0-ppk[i*3+2]*faceR/defaultRadius))
                }else{
                    if ppk[i*3+1] > uraPoint{
                        drawPath.addLine(to: CGPoint(x:faceX0+ppk[i*3]*faceR/defaultRadius,y:faceY0-ppk[i*3+2]*faceR/defaultRadius))
                    }else{
                        drawPath.move(to: CGPoint(x:faceX0+ppk[i*3]*faceR/defaultRadius,y:faceY0-ppk[i*3+2]*faceR/defaultRadius))
                    }
                    if facePoints[3*i+2] == 1{
                        endpointF=true
                    }
                }
            }
        }else{//iPhoneが-90~+90の時
            for i in 0..<facePoints.count/3-1{
                if endpointF==true{//始点に移動する
                    
                    if ppk[i*3+1] < uraPoint{
                        endpointF=true
                    }else{
                        endpointF=false
                    }
                    drawPath.move(to: CGPoint(x:faceX0-ppk[i*3]*faceR/defaultRadius,y:faceY0+ppk[i*3+2]*faceR/defaultRadius))
                }else{
                    if ppk[i*3+1] > uraPoint{
                        drawPath.addLine(to: CGPoint(x:faceX0-ppk[i*3]*faceR/defaultRadius,y:faceY0+ppk[i*3+2]*faceR/defaultRadius))
                    }else{
                        drawPath.move(to: CGPoint(x:faceX0-ppk[i*3]*faceR/defaultRadius,y:faceY0+ppk[i*3+2]*faceR/defaultRadius))
                    }
                    if facePoints[3*i+2] == 1{
                        endpointF=true
                    }
                }
            }
        }
        // 線の色
        UIColor.black.setStroke()
        drawPath.lineWidth = 2.0//1.0
        // 線を描く
        drawPath.stroke()
        // イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
 
    override func viewDidAppear(_ animated: Bool) {
//        ipWebView.scrollView.zoom(to: CGRect(x:330,y:8,width: 320,height: 240), animated: true)
    }
    func setProperty(label:UILabel,radius:CGFloat){
        label.layer.masksToBounds = true
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.borderWidth = 1.0
        label.layer.cornerRadius = radius
    }

    func setButtons(){
        // recording button
        let height:CGFloat=0//CGFloat(camera.getUserDefaultFloat(str: "buttonsHeight", ret: 0))
        let sp=realWidth/120//間隙
        let bw=(realWidth-sp*10)/7//ボタン幅
        let bh=bw*170/440
        let by1=realHeight-bh-sp-height-bh*2/3
        let by=realHeight-(bh+sp)*2-height-bh*2/3
        let x0=leftPadding+sp*2
        camera.setButtonProperty(exitButton,x:x0+bw*6+sp*6,y:view.bounds.height-sp-bh,w:bw,h:bh,UIColor.darkGray)
        camera.setButtonProperty(hatenaButton,x:x0+bw*6+sp*6,y:by,w:bw,h:bh,UIColor.darkGray)
        hatenaButton.isHidden=true
        setProperty(label: currentTime, radius: 4)
        currentTime.font = UIFont.monospacedDigitSystemFont(ofSize: view.bounds.width/30, weight: .medium)
        currentTime.frame = CGRect(x:x0+sp*6+bw*6, y: topPadding+sp, width: bw, height: bh)
        capHeight=view.bounds.height-2*sp
        capWidth=capHeight*4/3
        capX=x0+bw*6+sp*6-capWidth-sp
        startButton.frame=CGRect(x:x0+bw*6+sp*6-sp,y:(realHeight-bw)/2-sp,width: bw+2*sp,height:bw+2*sp)
        stopButton.frame=CGRect(x:x0+bw*6+sp*6-sp,y:(realHeight-bw)/2-sp,width: bw+2*sp,height: bw+2*sp)
        mjpegImage.frame=CGRect(x:capX,y:sp,width:capWidth,height:capHeight)
        quaternionView.frame=CGRect(x:capX+sp,y:2*sp,width: realHeight/5,height: realHeight/5)

        if someFunctions.firstLang().contains("ja"){
//            explanationLabel.text=explanationText + "録画設定"
        }else{
//            explanationLabel.text=explanationText + "Record Settings"
        }
    }
 
    @IBAction func onClickStopButton(_ sender: Any) {
        recordingFlag=false

        if let soundUrl = URL(string:
                                "/System/Library/Audio/UISounds/begin_record.caf"){
            AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundIdx)
            AudioServicesPlaySystemSound(soundIdx)
        }
        motionManager.stopDeviceMotionUpdates()
        killTimer()
        //動画生成終了を呼び出してURLを得る -> Playerにのせる
        var capFinishedFlag=false
        self.finished { (url) in
            DispatchQueue.main.async{
                capFinishedFlag=true
                print("url:",url)
//                let avPlayer = AVPlayer(url:url)
//                self.avPlayerVC.player = avPlayer
//                avPlayer.play()
            }
        }
        if FileManager.default.fileExists(atPath: TempFilePath){
            print("tempFileExists")
        }
        let fileURL = URL(fileURLWithPath: TempFilePath)
        if camera.albumExists()==true{
            PHPhotoLibrary.shared().performChanges({ [self] in
                //let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: avAsset)
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)!
                let albumChangeRequest = PHAssetCollectionChangeRequest(for:camera.getPHAssetcollection())
                let placeHolder = assetRequest.placeholderForCreatedAsset
                albumChangeRequest?.addAssets([placeHolder!] as NSArray)
                //imageID = assetRequest.placeholderForCreatedAsset?.localIdentifier
                print("file add to album")
            }) { [self] (isSuccess, error) in
                if isSuccess {
                    // 保存した画像にアクセスする為のimageIDを返却
                    //completionBlock(imageID)
                    print("success")
                    self.saved2album=true
                } else {
                    //failureBlock(error)
                    print("fail")
                    //                print(error)
                    self.saved2album=true
                }
            }
        }else{
            //アプリ起動中にアルバムを削除して録画するとここを通る。
            stopButton.isHidden=true
            //と変更することで、Exitボタンで帰った状態にする。
        }

        while saved2album==false{
            sleep(UInt32(0.1))
        }
 //        isFirstTap = true
        performSegue(withIdentifier: "fromRecord", sender: self)
    }

    @IBAction func onClickStartButton(_ sender: Any) {

        timerCnt=0
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        //sensorをリセットし、正面に
        motionManager.stopDeviceMotionUpdates()
        recordingFlag=true
        //start recording
        stopButton.isHidden=false
        exitButton.isHidden=true
        startButton.isHidden=true
     
//        try? FileManager.default.removeItem(atPath: TempFilePath)//deleteしておく
 

        if let soundUrl = URL(string:
                                "/System/Library/Audio/UISounds/begin_record.caf"/*photoShutter.caf*/){
            AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundIdx)
            AudioServicesPlaySystemSound(soundIdx)
        }
        
        setMotion()
        createFirst(image:takeScreenShot() ,size:CGSize(width: 472, height: 354))
        stopButton.isHidden=false

    }
    
     @IBAction func tapGest(_ sender: UITapGestureRecognizer) {
        if recordingFlag==true{
            return
        }
        setMotion()
    }

    //movie creator***********************************
    //１枚めの画像かどうか
//    var isFirstTap = true
    
    //画像のサイズ
    var imageSize = CGSize(width:320*4+1,height:240*4+1)

    //保存先のURL
    var capUrl:URL?
    
    //フレーム数
    var frameCount = 0
    
    // FPS
    let fps: __int32_t = 30
    var time:Int = 1    // (time / fps)   VCからいじる
    
    var videoWriter:AVAssetWriter?
    var writerInput:AVAssetWriterInput?
    var adaptor:AVAssetWriterInputPixelBufferAdaptor!
    
    //適当に画像サイズ
//    let imageSize = CGSize(width:1280,height:960)
    
    
    //イチバン最初はこれを呼び出す
    func createFirst(image:UIImage,size:CGSize){
//        imageSize=image.size
//        print(imageSize,image.size)
//         let TempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
        //保存先のURL
        capUrl = NSURL(fileURLWithPath: TempFilePath) as URL
        try? FileManager.default.removeItem(atPath: TempFilePath)//消去しておく
//        capUrl = NSURL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("\(NSUUID().uuidString).mp4")
 // AVAssetWriter
        guard let firstVideoWriter = try? AVAssetWriter(outputURL: capUrl!, fileType: AVFileType.mov) else {
            fatalError("AVAssetWriter error")
        }
        videoWriter = firstVideoWriter
        print(capUrl)
        //画像サイズを変える
        let width = size.width
        let height = size.height
        
        // AVAssetWriterInput
        let outputSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
            ] as [String : Any]
        writerInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings as [String : AnyObject])
        videoWriter!.add(writerInput!)
        
        // AVAssetWriterInputPixelBufferAdaptor
        adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput!,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
                ]
        )
        
        writerInput?.expectsMediaDataInRealTime = true
        
        // 動画の生成開始
        
        // 生成できるか確認
        if (!videoWriter!.startWriting()) {
            // error
            print("error videoWriter startWriting")
        }
        
        // 動画生成開始
        videoWriter!.startSession(atSourceTime: CMTime.zero)
        
        // pixel bufferを宣言
        var buffer: CVPixelBuffer? = nil
        
        // 現在のフレームカウント
        frameCount = 0
        
        if (!adaptor.assetWriterInput.isReadyForMoreMediaData) {
            return
        }
        
        // 動画の時間を生成(その画像の表示する時間/開始時点と表示時間を渡す)
        let frameTime: CMTime = CMTimeMake(value: Int64(__int32_t(frameCount) * __int32_t(time)), timescale: fps)
        //時間経過を確認(確認用)
        let second = CMTimeGetSeconds(frameTime)
        print(second)
        
        //画像のリサイズと整形
        let resize = resizeImage(image: image, contentSize: imageSize)
        
        // CGImageからBufferを生成
        buffer = self.pixelBufferFromCGImage(cgImage: resize.cgImage!)
        
        // 生成したBufferを追加
        if (!adaptor.append(buffer!, withPresentationTime: frameTime)) {
            // Error!
            print("adaptError")
            print(videoWriter!.error!)
        }
        
        frameCount += 1
        
    }
    
    //２回め以降はこれを呼び出す
    func createSecond(image:UIImage){
        //videoWriterがなければ終了
        if videoWriter == nil{
            return
        }
        
        // pixel bufferを宣言
        var buffer: CVPixelBuffer? = nil
        
        if (!adaptor.assetWriterInput.isReadyForMoreMediaData) {
            return
        }
        
        // 動画の時間を生成(その画像の表示する時間/開始時点と表示時間を渡す)
        let frameTime: CMTime = CMTimeMake(value: Int64(__int32_t(frameCount) * __int32_t(time)), timescale: fps)
        //時間経過を確認(確認用)
        let second = CMTimeGetSeconds(frameTime)
        print(second)
        
        // CGImageからBufferを生成
        let resize = resizeImage(image: image, contentSize: imageSize)
        buffer = self.pixelBufferFromCGImage(cgImage: resize.cgImage!)
        
        // 生成したBufferを追加
        if (!adaptor.append(buffer!, withPresentationTime: frameTime)) {
            // Error!
            print(videoWriter!.error!)
        }
  
        print("frameCount :\(frameCount)")
        frameCount += 1
    }
    
    
    //終わったら後始末をしてURLを返す
    func finished(_ completion:@escaping (URL)->()){
        // 動画生成終了
        if writerInput == nil || videoWriter == nil{
            return
        }
        writerInput!.markAsFinished()
        videoWriter!.endSession(atSourceTime: CMTimeMake(value: Int64((__int32_t(frameCount)) *  __int32_t(time)), timescale: fps))
        videoWriter!.finishWriting(completionHandler: {
            // Finish!
            print("movie created.")
            self.writerInput = nil
            if self.capUrl != nil {
                completion(self.capUrl!)
            }
        })
    }
    
    //ピクセルバッファへの変換
    func pixelBufferFromCGImage(cgImage: CGImage) -> CVPixelBuffer {
        
        let options = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        var pxBuffer: CVPixelBuffer? = nil
        
        let width = cgImage.width
        let height = cgImage.height
        
        CVPixelBufferCreate(kCFAllocatorDefault,
                            width,
                            height,
                            kCVPixelFormatType_32ARGB,
                            options as CFDictionary?,
                            &pxBuffer)
        
        CVPixelBufferLockBaseAddress(pxBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        let pxdata = CVPixelBufferGetBaseAddress(pxBuffer!)
        
        let bitsPerComponent: size_t = 8
        let bytesPerRow: size_t = 4 * width
        
        let rgbColorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pxdata,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.draw(cgImage, in: CGRect(x:0, y:0, width:CGFloat(width),height:CGFloat(height)))
        
        CVPixelBufferUnlockBaseAddress(pxBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pxBuffer!
    }
    
    
    //リサイズが必要なら
    func resizeImage(image:UIImage,contentSize:CGSize) -> UIImage{
        // リサイズ処理
        let origWidth  = Int(image.size.width)
        let origHeight = Int(image.size.height)
        var resizeWidth:Int = 0, resizeHeight:Int = 0
        if (origWidth < origHeight) {
            resizeWidth = Int(contentSize.width)
            resizeHeight = origHeight * resizeWidth / origWidth
        } else {
            resizeHeight = Int(contentSize.height)
            resizeWidth = origWidth * resizeHeight / origHeight
        }
        
        let resizeSize = CGSize(width:CGFloat(resizeWidth), height:CGFloat(resizeHeight))
        UIGraphicsBeginImageContext(resizeSize)
        
        image.draw(in: CGRect(x:0,y: 0,width: CGFloat(resizeWidth), height:CGFloat(resizeHeight)))
        
        let resizeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // 切り抜き処理
        
        let cropRect  = CGRect(
            x:CGFloat((resizeWidth - Int(contentSize.width)) / 2),
            y:CGFloat((resizeHeight - Int(contentSize.height)) / 2),
            width:contentSize.width, height:contentSize.height)
        let cropRef   = (resizeImage?.cgImage)!.cropping(to: cropRect)
        let cropImage = UIImage(cgImage: cropRef!)
        
        return cropImage
    }
}

extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }

        if let pixelBuffer = pixelBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

            context?.translateBy(x: 0, y: self.size.height)
            context?.scaleBy(x: 1.0, y: -1.0)

            UIGraphicsPushContext(context!)
            self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

            return pixelBuffer
        }

        return nil
    }
}
