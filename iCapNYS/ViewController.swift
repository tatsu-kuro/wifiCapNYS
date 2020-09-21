//
//  ViewController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2020/09/21.
//

//
//  ViewController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2020/09/20.
//
import UIKit
import AVFoundation
import GLKit
import Photos
import CoreMotion
class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate{
//import UIKit
//import CoreMotion
//class ViewController: UIViewController {
    var soundIdstart:SystemSoundID = 1117
    var soundIdstop:SystemSoundID = 1118
    var soundIdpint:SystemSoundID = 1109//1009//7
    var recordedFlag:Bool = false
    let motionManager = CMMotionManager()
    var session: AVCaptureSession!
    var videoDevice: AVCaptureDevice?
    var filePath:String?
    var fileOutput = AVCaptureMovieFileOutput()
    var gyro = Array<Double>()
    var recStart = CFAbsoluteTimeGetCurrent()
    var counter:Int=0
    var timer:Timer?
    var quater0:Double=0
    var quater1:Double=0
    var quater2:Double=0
    var quater3:Double=0
    var readingF=false
    @IBOutlet weak var quaternionView: UIImageView!
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
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil){
            AudioServicesCreateSystemSoundID(soundUrl, &soundIdstop)
            AudioServicesPlaySystemSound(soundIdstop)
        }
        print("終了ボタン、最大を超えた時もここを通る")
        motionManager.stopDeviceMotionUpdates()//ここで止めたが良さそう。
        // ライブラリへ保存
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        }) { completed, error in
            if completed {
                print("Video is saved!")
            }
        }
        recordedFlag=true
        if timer?.isValid == true {
            timer!.invalidate()
        }
        performSegue(withIdentifier: "fromRecordToMain", sender: self)
    }
//    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection]) {
//        recStart=CFAbsoluteTimeGetCurrent()
//        print("録画開始")
//        //fileOutput.stopRecording()
//     }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        set_rpk_ppk()
        setMotion()
        // Do any additional setup after loading the view.
        timer = Timer.scheduledTimer(timeInterval: 1/60, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)

    }
    @objc func update(tm: Timer) {
        //        print(nq0,nq1,nq2,nq3 as Any)
        readingF=true
        let qCG0=CGFloat(quater0)
        let qCG1=CGFloat(quater1)
        let qCG2=CGFloat(quater2)
        let qCG3=CGFloat(quater3)
        readingF=false
        let quaterImage = drawHead(width: 80, height: 80, qOld0:qCG0, qOld1: qCG1, qOld2:qCG2,qOld3:qCG3)
        setImage(newImage: quaterImage)
    }
 
    public func setImage(newImage: UIImage) {
      DispatchQueue.main.async {
        self.quaternionView.image = newImage
        self.quaternionView.setNeedsLayout()
      }
    }
   
    func setMotion(){
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1 / 100//が最速の模様
        //time0=CFAbsoluteTimeGetCurrent()
        //        var initf:Bool=false
        motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { (motion, error) in
            guard let motion = motion, error == nil else { return }
//            self.gyro.append(CFAbsoluteTimeGetCurrent())
//            self.gyro.append(motion.rotationRate.y)//
            let quat = motion.attitude.quaternion
            while self.readingF==true{
                usleep(1)
            }
            self.quater0 = quat.w
            self.quater1 = quat.x
            self.quater2 = -quat.z
            self.quater3 =  quat.y
           })
    }
    func set_rpk_ppk() {
        let faceR:CGFloat = 40//hankei
        // convert draw data to radian
        for i in 0..<facePoints.count/3 {
            //            print(pk_ken2[i*3],pk_ken2[i*3+1],pk_ken2[i*3+2])
            rpk1[i*2] = CGFloat(facePoints[3 * i + 0]) * 0.01745329//pi/180
            rpk1[i*2+1] = CGFloat(facePoints[3 * i + 1]) * 0.01745329//pi/180
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
    func isBigger(len:CGFloat,than:CGFloat)->Bool{
        if len > than{
            return true
        }else{
            return false
        }
    }
    var headCnt:Int=0
    func drawHead(width w:CGFloat,height h:CGFloat,qOld0:CGFloat, qOld1:CGFloat, qOld2:CGFloat, qOld3:CGFloat)->UIImage{
        //        var ppk:[CGFloat]=[]
        var ppk = Array(repeating: CGFloat(0), count:500)
        //  pk_ken = &pk_ken2[0][0];//no smile
        let faceX0:CGFloat = 40;
        let faceY0:CGFloat = 40;//center
        let faceR:CGFloat = 40;//hankei
        let size = CGSize(width:w, height:h)
        headCnt += 1
//        // イメージ処理の開始
//        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)

        
        for i in 0..<facePoints.count/3 {
            //RotateQuat(&ppk[i][0], &ppk[i][1], &ppk[i][2],ppk1[i][0],ppk1[i][1],ppk1[i][2], q0, q1, q2, q3);
            //   func rotateQuat(){//(fl *x, fl *y, fl *z,fl x0,fl y0,fl z0, fl q0, fl q1, fl q2, fl q3)
            let x0:CGFloat=ppk1[i*3]
            let y0:CGFloat=ppk1[i*3+1]
            let z0:CGFloat=ppk1[i*3+2]
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

//        for i in 0..<13{
//            print(i,":",pk_ken2[i*3+2],":",String(format:"%.1f %.1f %.1f",ppk[i*3],ppk[i*3+1],ppk[i*3+2]))
//        }
//        drawSquare(x: 84,y: 84,w: faceR)
        // 円
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)

        let drawPath = UIBezierPath(arcCenter: CGPoint(x: 40, y:40), radius: 39, startAngle: 0, endAngle: CGFloat(Double.pi)*2, clockwise: true)
        // 内側の色
//        UIColor(red: 0, green: 0, blue: 1, alpha: 0.3).setFill()
//        // 内側を塗りつぶす
//        circle.fill()

        let uraPoint=faceR/40.0

        var endpointF=true//終点でtrueとする

        for i in 0..<facePoints.count/3-1{
            if endpointF==true{//始点に移動する

                if ppk[i*3+1] < uraPoint{
                    endpointF=true
                }else{
                    endpointF=false
                }
                drawPath.move(to: CGPoint(x:faceX0-ppk[i*3],y:faceY0+ppk[i*3+2]))
            }else{
                if ppk[i*3+1] > uraPoint{
                    drawPath.addLine(to: CGPoint(x:faceX0-ppk[i*3],y:faceY0+ppk[i*3+2]))
                }else{
                    drawPath.move(to: CGPoint(x:faceX0-ppk[i*3],y:faceY0+ppk[i*3+2]))
                }
                if facePoints[3*i+2] == 1{
                    endpointF=true
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
}
/*
 //
 //  RecordViewController.swift
 //  vHIT96da
 //
 //  Created by 黒田建彰 on 2020/02/29.
 //  Copyright © 2020 tatsuaki.kuroda. All rights reserved.
 //

 import UIKit
 import AVFoundation
 import GLKit
 import Photos
 import CoreMotion
 class RecordViewController: UIViewController, AVCaptureFileOutputRecordingDelegate{
     var recordedFlag:Bool = false
     let motionManager = CMMotionManager()
     var session: AVCaptureSession!
     var videoDevice: AVCaptureDevice?
     var filePath:String?
     var timer:Timer?

     var fileOutput = AVCaptureMovieFileOutput()
     var gyro = Array<Double>()
     var recStart = CFAbsoluteTimeGetCurrent()
 //    var recEnd=CFAbsoluteTimeGetCurrent()
 //    var recordButton: UIButton!
 //    var currTime:UILabel?
     @IBOutlet weak var currentTime: UILabel!
     
   
     @IBOutlet weak var stopButton: UIButton!
     @IBOutlet weak var startButton: UIButton!
     @IBOutlet weak var exitBut: UIButton!
     @IBOutlet weak var cameraView: UIImageView!
     @IBAction func startRecord(_ sender: Any) {
         onClickRecordButton()
     }
     
     @IBOutlet weak var damyBottom: UILabel!
     @IBAction func stopRecord(_ sender: Any) {
         onClickRecordButton()
     }
     func drawSquare(x:CGFloat,y:CGFloat){
         /* --- 正方形を描画 --- */
         let dia:CGFloat = view.bounds.width/5
         let squareLayer = CAShapeLayer.init()
         let squareFrame = CGRect.init(x:x-dia/2,y:y-dia/2,width:dia,height:dia)
         squareLayer.frame = squareFrame
         // 輪郭の色
         squareLayer.strokeColor = UIColor.red.cgColor
         // 中の色
         squareLayer.fillColor = UIColor.clear.cgColor//UIColor.red.cgColor
         // 輪郭の太さ
         squareLayer.lineWidth = 1.0
         // 正方形を描画
         squareLayer.path = UIBezierPath.init(rect: CGRect.init(x: 0, y: 0, width: squareFrame.size.width, height: squareFrame.size.height)).cgPath
         self.view.layer.addSublayer(squareLayer)
     }

     var tapF:Bool=false
     @IBAction func tapGes(_ sender: UITapGestureRecognizer) {
         let screenSize=cameraView.bounds.size
         let x0 = sender.location(in: self.view).x
         let y0 = sender.location(in: self.view).y
         print("tap:",x0,y0,screenSize.height)
         
         if y0>screenSize.height*5/6{
             return
         }
         let x = y0/screenSize.height
         let y = 1.0 - x0/screenSize.width
         let focusPoint = CGPoint(x:x,y:y)
         
         if let device = videoDevice{
             do {
                 try device.lockForConfiguration()
                 
                 device.focusPointOfInterest = focusPoint
                 //                device.focusMode = .continuousAutoFocus
                 device.focusMode = .autoFocus
                 //                device.focusMode = .locked
                 // 露出の設定
                 if device.isExposureModeSupported(.continuousAutoExposure) && device.isExposurePointOfInterestSupported {
                     device.exposurePointOfInterest = focusPoint
                     device.exposureMode = .continuousAutoExposure
                 }
                 device.unlockForConfiguration()
                 
                 if tapF {
                     view.layer.sublayers?.removeLast()
                 }
                 drawSquare(x: x0, y: y0)
                 tapF=true;
                 //                }
             }
             catch {
                 // just ignore
             }
         }
     }
     // 指定の FPS のフォーマットに切り替える (その FPS で最大解像度のフォーマットを選ぶ)
     //
     // - Parameters:
     //   - desiredFps: 切り替えたい FPS (AVFrameRateRange.maxFrameRate が Double なので合わせる)
     func switchFormat(desiredFps: Double)->Bool {
         // セッションが始動しているかどうか
         var retF:Bool=false
         let isRunning = session.isRunning
         
         // セッションが始動中なら止める
         if isRunning {
             print("isrunning")
             session.stopRunning()
         }
         
         // 取得したフォーマットを格納する変数
         var selectedFormat: AVCaptureDevice.Format! = nil
         // そのフレームレートの中で一番大きい解像度を取得する
         var maxWidth: Int32 = 0
         
         // フォーマットを探る
         for format in videoDevice!.formats {
             // フォーマット内の情報を抜き出す (for in と書いているが1つの format につき1つの range しかない)
             for range: AVFrameRateRange in format.videoSupportedFrameRateRanges {
                 let description = format.formatDescription as CMFormatDescription    // フォーマットの説明
                 let dimensions = CMVideoFormatDescriptionGetDimensions(description)  // 幅・高さ情報を抜き出す
                 let width = dimensions.width
                  if desiredFps == range.maxFrameRate && width >= maxWidth {
                       selectedFormat = format
                     maxWidth = width
                 }
             }
         }
         
         // フォーマットが取得できていれば設定する
         if selectedFormat != nil {
             do {
                 try videoDevice!.lockForConfiguration()
                 videoDevice!.activeFormat = selectedFormat
                 videoDevice!.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(desiredFps))
                 videoDevice!.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(desiredFps))
                 videoDevice!.unlockForConfiguration()
                 print("フォーマット・フレームレートを設定 : \(desiredFps) fps・\(maxWidth) px")
                 retF=true
             }
             catch {
                 print("フォーマット・フレームレートが指定できなかった")
                 retF=false
             }
         }
         else {
             print("指定のフォーマットが取得できなかった")
             retF=false
         }
         
         // セッションが始動中だったら再開する
         if isRunning {
             session.startRunning()
         }
         return retF
     }
     
     func setMotion(){
         guard motionManager.isDeviceMotionAvailable else { return }
         motionManager.deviceMotionUpdateInterval = 1 / 100//が最速の模様
         //time0=CFAbsoluteTimeGetCurrent()
         //        var initf:Bool=false
         motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { (motion, error) in
             guard let motion = motion, error == nil else { return }
             self.gyro.append(CFAbsoluteTimeGetCurrent())
             self.gyro.append(motion.rotationRate.y)//
            })
     }
  
     override func viewDidLoad() {
         super.viewDidLoad()
         self.view.backgroundColor = .black
         initSession(fps: 60)//遅ければ30fpsにせざるを得ないかも
         
         startButton.isHidden=true
         stopButton.isHidden=true
         currentTime.isHidden=true
         
     }
     override func viewDidAppear(_ animated: Bool) {
         setButtons(type: true)
     }
     
     func setButtons(type:Bool){
         // recording button
         
         let ww=view.bounds.width
         let wh=damyBottom.frame.maxY// view.bounds.height
         let bw=Int(ww/4)-8
         //        let bd=Int(ww/5/4)
         let bh:Int=60
         let bpos=Int(wh)-bh/2-10

         currentTime.frame   = CGRect(x:0,   y: 0 ,width: Int(Double(bw)*1.5), height: bh/2)
         currentTime.layer.position=CGPoint(x:Int(ww)/2,y:Int(wh)-Int(Double(bh)*2.5))
         currentTime.isHidden=true
         currentTime.layer.masksToBounds = true
         currentTime.layer.cornerRadius = 5

         //startButton
         startButton.frame=CGRect(x:0,y:0,width:bh*2,height:bh*2)
         startButton.layer.position = CGPoint(x:Int(ww)/2,y:bpos-bh/3)
         stopButton.frame=CGRect(x:0,y:0,width:bh*2,height:bh*2)
         stopButton.layer.position = CGPoint(x:Int(ww)/2,y:bpos-bh/3)
         startButton.isHidden=false
         stopButton.isHidden=true
         stopButton.tintColor=UIColor.orange
         setButtonProperty(button: exitBut, bw: CGFloat(bw), bh: CGFloat(bh), cx: CGFloat(Int(Int(ww)-10-bw/2)), cy:CGFloat(bpos))
     }
     func setButtonProperty(button:UIButton,bw:CGFloat,bh:CGFloat,cx:CGFloat,cy:CGFloat){
         button.frame   = CGRect(x:0,   y: 0 ,width: bw, height: bh)
         button.layer.borderColor = UIColor.green.cgColor
         button.layer.borderWidth = 1.0
         button.layer.position=CGPoint(x:cx,y:cy)
         button.layer.cornerRadius = 5
     }
     func initSession(fps:Int) {
         // セッション生成
         session = AVCaptureSession()
         // 入力 : 背面カメラ
         videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
         let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)
         session.addInput(videoInput)
  
         if switchFormat(desiredFps: 60)==false{
             print("error******")
         }
         // ファイル出力設定
         fileOutput = AVCaptureMovieFileOutput()
         fileOutput.maxRecordedDuration = CMTimeMake(value:5*60, timescale: 1)//最長録画時間
         session.addOutput(fileOutput)
         
         let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
         videoLayer.frame = self.view.bounds
         videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill//無くても同じ
         //self.view.layer.addSublayer(videoLayer)
         cameraView.layer.addSublayer(videoLayer)
         // zooming slider
         // セッションを開始する (録画開始とは別)
         session.startRunning()
     }

     var soundIdstart:SystemSoundID = 1117
     var soundIdstop:SystemSoundID = 1118
     var soundIdpint:SystemSoundID = 1109//1009//7
     
     var counter:Int=0
     @objc func update(tm: Timer) {
         counter += 1
         currentTime.text=String(format:"%02d",counter/60) + ":" + String(format: "%02d",counter%60)
         if counter%2==0{
             stopButton.tintColor=UIColor.orange
         }else{
             stopButton.tintColor=UIColor.red
         }
     }
     
     func onClickRecordButton() {
         if self.fileOutput.isRecording {
             // stop recording
             
             print("ストップボタンを押した。")
             fileOutput.stopRecording()
             
         } else {
             //start recording
             startButton.isHidden=true
             stopButton.isHidden=false
             currentTime.isHidden=false
             
             exitBut.isHidden=true
             timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
             UIApplication.shared.isIdleTimerDisabled = true//スリープしない
             if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil){
                 AudioServicesCreateSystemSoundID(soundUrl, &soundIdstart)
                 AudioServicesPlaySystemSound(soundIdstart)
             }
             
             let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
             let documentsDirectory = paths[0] as String
             // 現在時刻をファイル名に付与することでファイル重複を防ぐ : "myvideo-20190101125900.mp4" な形式になる
             let formatter = DateFormatter()
             formatter.dateFormat = "yyyy-MM-dd_HH:mm:ss"
             filePath = "vHIT96da\(formatter.string(from: Date())).MOV"
             let filefullPath="\(documentsDirectory)/" + filePath!
             let fileURL = NSURL(fileURLWithPath: filefullPath)
             setMotion()//作動中ならそのまま戻る
             print("録画開始 : \(filePath!)")
             fileOutput.startRecording(to: fileURL as URL, recordingDelegate: self)
         }
     }

     func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
         if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil){
             AudioServicesCreateSystemSoundID(soundUrl, &soundIdstop)
             AudioServicesPlaySystemSound(soundIdstop)
         }
         print("終了ボタン、最大を超えた時もここを通る")
         motionManager.stopDeviceMotionUpdates()//ここで止めたが良さそう。
         // ライブラリへ保存
         PHPhotoLibrary.shared().performChanges({
             PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
         }) { completed, error in
             if completed {
                 print("Video is saved!")
             }
         }
         recordedFlag=true
         if timer?.isValid == true {
             timer!.invalidate()
         }
         performSegue(withIdentifier: "fromRecordToMain", sender: self)
     }
     func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection]) {
         recStart=CFAbsoluteTimeGetCurrent()
         print("録画開始")
         //fileOutput.stopRecording()
      }
 }

 */
