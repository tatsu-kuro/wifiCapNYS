//
//  AutoRecordViewController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2022/08/02.
//

import UIKit
import AVFoundation
import GLKit
import Photos
import CoreMotion
import VideoToolbox
class AutoRecordViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate  {

    @IBOutlet weak var quaternionView: UIImageView!
    @IBOutlet weak var videoView: UIImageView!
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var whiteView: UIImageView!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var currentTime: UILabel!
    func killTimer(){
        if timer?.isValid == true {
            timer!.invalidate()
        }
        if movieTimer?.isValid == true{
            movieTimer!.invalidate()
        }
    }
    var soundPlayer: AVAudioPlayer?
    var videoPlayer: AVPlayer!
    
    func sound(snd:String,fwd:Double){
        if let sound = NSDataAsset(name: snd) {
            soundPlayer = try? AVAudioPlayer(data: sound.data)
            soundPlayer!.currentTime = fwd
            soundPlayer?.play() // → これで音が鳴る
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
    
    var leftPadding:CGFloat=0// =CGFloat( UserDefaults.standard.integer(forKey:"leftPadding"))
    var rightPadding:CGFloat=0//=CGFloat(UserDefaults.standard.integer(forKey:"rightPadding"))
    var topPadding:CGFloat=0//=CGFloat(UserDefaults.standard.integer(forKey:"topPadding"))
    var bottomPadding:CGFloat=0//=CGFloat(UserDefaults.standard.integer(forKey:"bottomPadding"))
//    var realWinWidth:CGFloat=0//=view.bounds.width-leftPadding-rightPadding
    var realWinHeight:CGFloat=0//=view.bounds.height-topPadding-bottomPadding/2
    
    let camera = myFunctions()
    var cameraType:Int = 0
    var soundIdstart:SystemSoundID = 1117
    var soundIdstop:SystemSoundID = 1118
    var soundIdpint:SystemSoundID = 1109//1009//7
    var soundIdx:SystemSoundID = 0
    let albumName:String = "iCapNYS"
    var recordingFlag:Bool = false
    var saved2album:Bool = false
    var setteiMode:Bool = false
    let motionManager = CMMotionManager()

    //for video input
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
    var quater0:Double=0
    var quater1:Double=0
    var quater2:Double=0
    var quater3:Double=0
    var readingFlag = false
    var timer:Timer?
    var movieTimer:Timer?
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
 
    override func viewDidLoad() {
        super.viewDidLoad()
      
        leftPadding=CGFloat( UserDefaults.standard.integer(forKey:"leftPadding"))
        rightPadding=CGFloat(UserDefaults.standard.integer(forKey:"rightPadding"))
        topPadding=CGFloat(UserDefaults.standard.integer(forKey:"topPadding"))
        bottomPadding=CGFloat(UserDefaults.standard.integer(forKey:"bottomPadding"))
//        realWinWidth=view.bounds.width-leftPadding-rightPadding
        realWinHeight=view.bounds.height-topPadding-bottomPadding/2
//        playMoviePath("spon1mov")
        movieTimerCnt=0
        movieTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.movieUpdate), userInfo: nil, repeats: true)

        getCameras()
        camera.makeAlbum()
    
        if (UserDefaults.standard.object(forKey: "cameraType") != nil){//keyが設定してなければ0をセット
            cameraType=UserDefaults.standard.integer(forKey:"cameraType")
        }else{
            cameraType=0
            UserDefaults.standard.set(cameraType, forKey: "cameraType")
        }
    
        set_rpk_ppk()
        setMotion()
        initSession(fps: 60)//遅ければ30fpsにせざるを得ないかも、30fpsだ！


        setFocus(focus:camera.getUserDefaultFloat(str: "focusValue", ret: 0))

        if cameraType==0{
            setZoom(level:camera.getUserDefaultFloat(str: "zoomValue0", ret: 0.017))
        }else{
            setZoom(level:camera.getUserDefaultFloat(str: "zoomValue1", ret: 0.07))
        }

        setExpose(expose: camera.getUserDefaultFloat(str: "exposeValue", ret: 0))

        setButtons()//height:buttonsHeight)
        
        currentTime.isHidden=true
        quaternionView.isHidden=true
        cameraView.isHidden=true
//        exitButton.isHidden=true
     }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    func setZoom(level:Float){//0.0-0.1

        if let device = videoDevice {
        do {
            try device.lockForConfiguration()
                device.ramp(
                    toVideoZoomFactor: (device.minAvailableVideoZoomFactor) + CGFloat(level) * ((device.maxAvailableVideoZoomFactor) - (device.minAvailableVideoZoomFactor)),
                    withRate: 30.0)
            device.unlockForConfiguration()
            } catch {
                print("Failed to change zoom.")
            }
        }
    }
 
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
    func set_rpk_ppk() {
        let faceR:CGFloat = 40//hankei
        var frontBack:Int = 0
        let camera = Int(camera.getUserDefaultInt(str: "cameraType", ret: 0))
        if camera == 0{//front camera
            frontBack = 180
        }
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
        var ppk = Array(repeating: CGFloat(0), count:500)
        let faceX0:CGFloat = w/2;
        let faceY0:CGFloat = h/2;//center
        let faceR:CGFloat = r;//hankei
        let defaultRadius:CGFloat = 40.0
        let size = CGSize(width:w, height:h)
 
        // イメージ処理の開始
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
    
    func setVideoFormat(desiredFps: Double)->Bool {
        var retF:Bool=false
        //desiredFps 60
        // 取得したフォーマットを格納する変数
        var selectedFormat: AVCaptureDevice.Format! = nil
        // そのフレームレートの中で一番大きい解像度を取得する
        // フォーマットを探る
        for format in videoDevice!.formats {
            // フォーマット内の情報を抜き出す (for in と書いているが1つの format につき1つの range しかない)
            for range: AVFrameRateRange in format.videoSupportedFrameRateRanges {
                let description = format.formatDescription as CMFormatDescription    // フォーマットの説明
                let dimensions = CMVideoFormatDescriptionGetDimensions(description)  // 幅・高さ情報を抜き出す
                let width = dimensions.width
//                print(dimensions.width,dimensions.height)
//                if range.maxFrameRate == desiredFps && width == 1280{
                if  width == 1280{
                    selectedFormat = format//最後のformat:一番高品質
//                    print(range.maxFrameRate,dimensions.width,dimensions.height)
                }
            }
        }
//ipod touch 1280x720 1440*1080
//SE 960x540 1280x720 1920x1080
//11 192x144 352x288 480x360 640x480 1024x768 1280x720 1440x1080 1920x1080 3840x2160
//1280に設定すると上手く行く。合成のところには1920x1080で飛んでくるようだ。？
        // フォーマットが取得できていれば設定する
        if selectedFormat != nil {
//            print(selectedFormat.description)
            do {
                try videoDevice!.lockForConfiguration()
                videoDevice!.activeFormat = selectedFormat
//                videoDevice!.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(desiredFps))
                videoDevice!.unlockForConfiguration()
                
                let description = selectedFormat.formatDescription as CMFormatDescription    // フォーマットの説明
                let dimensions = CMVideoFormatDescriptionGetDimensions(description)  // 幅・高さ情報を抜き出す
                iCapNYSWidth = dimensions.width
                iCapNYSHeight = dimensions.height
                if cameraType==0{//訳がわからないがこれで上手くいく、反則行為
                    iCapNYSHeight=720
                }
                iCapNYSFPS = desiredFps
                print("フォーマット・フレームレートを設定 : \(desiredFps) fps・\(iCapNYSWidth) px x \(iCapNYSHeight) px")
                iCapNYSWidthF=CGFloat(iCapNYSWidth)
                iCapNYSHeightF=CGFloat(iCapNYSHeight)
                iCapNYSWidthF120=iCapNYSWidthF/120//quaterの表示開始位置
                iCapNYSHeightF5=iCapNYSHeightF/5//quaterの表示サイズ
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
        return retF
    }
    var telephotoCamera:Bool=false
    var ultrawideCamera:Bool=false
    func getCameras(){//wideAngleCameraのみ使用
        //        if AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil{
        //            ultrawideCamera=true
        //        }
        //        if AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) != nil{
        //            telephotoCamera=true
        //        }
        ultrawideCamera=false
        telephotoCamera=false
    }
    func playMoviePath(_ urlorig:String){
        guard let url = Bundle.main.url(forResource: urlorig, withExtension: "mov") else {
            print("Url is nil")
            return
        }
        videoPlayer = AVPlayer(url: url as URL)
        let layer = AVPlayerLayer()
        layer.videoGravity = AVLayerVideoGravity.resizeAspect
        layer.player = videoPlayer
//        videoView.layer.frame=view.bounds
        print(self.view.bounds,":",view.bounds)
        layer.frame = self.view.bounds
        layer.frame = CGRect(x:-40,y:-10,width:view.bounds.width+80,height: view.bounds.height+20)
        
//        self.view.layer.addSublayer(layer)
        videoView.layer.addSublayer(layer)
        videoPlayer.play()
        
    }
//    let moviePath: String? = Bundle.main.path(forResource: bundleDataName, ofType: bundleDataType)

    var movieTimerCnt:Int=0
    @objc func movieUpdate(tm: Timer){
        movieTimerCnt += 1
        
        if movieTimerCnt == 1{
             playMoviePath("mov78sp1")
            videoView.frame = self.view.bounds
        }
        if movieTimerCnt == 13{
            videoView.frame = CGRect(x:0,y:0,width: 0,height: 0)
            quaternionView.isHidden=false
            cameraView.isHidden=false
        }
//        if movieTimerCnt == 24{
//            quaternionView.isHidden=true
//            cameraView.isHidden=true
//            videoView.frame = self.view.bounds
//          }
        if movieTimerCnt == 27{
            exitButton.alpha=0
            quaternionView.isHidden=true
            cameraView.isHidden=true

            onClickStartButton()
            sound(snd: "m4asp1",fwd: 12)
//            videoView.frame = CGRect(x:0,y:0,width: 0,height: 0)
            
        }
        if movieTimerCnt == 27+22{
            print("stop")
            exitButton.alpha=1.0
            onClickStopButton()
            
            playMoviePath("mov78sp2")
            videoView.frame = self.view.bounds
        }
//        if movieTimerCnt == 27+22+21{
//            sound(snd: "spon3m4a",fwd: 0)
//        }
        if movieTimerCnt == 27+22+20{
            performSegue(withIdentifier: "fromAutoRecord", sender: self)
        }
    }
//    var timerCnt:Int=0
/*    @objc func update(tm: Timer) {
        timerCnt += 1
        if timerCnt == 3{
            //            stopButton.isEnabled=true
            UIApplication.shared.isIdleTimerDisabled = true//スリープしない
            //        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            if let soundUrl = URL(string:
                                    "/System/Library/Audio/UISounds/begin_record.caf"/*photoShutter.caf*/){
                AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundIdx)
                AudioServicesPlaySystemSound(soundIdx)
            }
            
            fileWriter!.startWriting()
            fileWriter!.startSession(atSourceTime: CMTime.zero)
            //        print(fileWriter?.error)
            setMotion()
        }
        if recordingFlag==true && timerCnt>3{//trueになった時 0にリセットされる
            currentTime.text=String(format:"%01d",(timerCnt-3)/60) + ":" + String(format: "%02d",(timerCnt-3)%60)
            if timerCnt%2==0{
                //                stopButton.tintColor=UIColor.cyan
            }else{
                //                stopButton.tintColor=UIColor.yellow// red
            }
        }
        if timerCnt > 60*5{
            motionManager.stopDeviceMotionUpdates()//tuika
            if recordingFlag==true{
                killTimer()
                //                onClickStopButton(0)
            }else{
                killTimer()
                performSegue(withIdentifier: "fromAutoRecord", sender: self)
            }
        }
    }*/
    func setMotion(){
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1 / 100//が最速の模様
        //time0=CFAbsoluteTimeGetCurrent()
        //        var initf:Bool=false
        degreeAtResetHead = -1
        motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { [self] (motion, error) in
            guard let motion = motion, error == nil else { return }
            //            self.gyro.append(CFAbsoluteTimeGetCurrent())
            //            self.gyro.append(motion.rotationRate.y)//
            while self.readingFlag==true{
                //                sleep(UInt32(0.1))
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
    func initSession(fps:Double) {
        // カメラ入力 : 背面カメラ
        cameraType=UserDefaults.standard.integer(forKey:"cameraType")
        
        if cameraType == 0{
            videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)//.back)
        }else if cameraType==1{
            videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }else if cameraType==2{
            videoDevice = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)
        }else if cameraType==3{
            videoDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
        }
        
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)
        
        if setVideoFormat(desiredFps: fps)==false{
            print("error******")
        }else{
            print("no error****")
        }
        // AVCaptureSession生成
        captureSession = AVCaptureSession()
        captureSession.addInput(videoInput)
        
        //        // 音声のインプット設定
        //        let audioDevice: AVCaptureDevice? = AVCaptureDevice.default(for: AVMediaType.audio)
        //        let audioInput = try! AVCaptureDeviceInput(device: audioDevice!)
        //        captureSession.addInput(audioInput)
        //以上のようなことは出来そうにない
        // プレビュー出力設定
        whiteView.layer.frame=CGRect(x:0,y:0,width:view.bounds.width,height:view.bounds.height)
        cameraView.layer.frame=CGRect(x:0,y:0,width:view.bounds.width,height:view.bounds.height)
        cameraView.layer.addSublayer(   whiteView.layer)
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if cameraType==0{
            let leftPadding=CGFloat( UserDefaults.standard.integer(forKey:"leftPadding"))
            let width=view.bounds.width
            let height=view.bounds.height
            videoLayer.frame = CGRect(x:leftPadding+10,y:height*2/5,width:width/5,height:height/5)
            videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        }else{
            videoLayer.frame=self.view.bounds
            videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            
        }
        //info right home button
        let landscapeSide=someFunctions.getUserDefaultInt(str: "landscapeSide", ret: 0)
        if landscapeSide==0{
            videoLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
        }else{
            videoLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
        }
        cameraView.layer.addSublayer(videoLayer)
        
        // VideoDataOutputを作成、startRunningするとそれ以降delegateが呼ばれるようになる。
        let videoDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA] as [String : Any]
        //         videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_32BGRA]
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        //         videoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        captureSession.addOutput(videoDataOutput)
        captureSession.startRunning()
        
        // ファイル出力設定
        startTimeStamp = 0
        //一時ファイルはこの時点で必ず消去
        let fileURL = NSURL(fileURLWithPath: TempFilePath)
        setMotion()//作動中ならそのまま戻る
        fileWriter = try? AVAssetWriter(outputURL: fileURL as URL, fileType: AVFileType.mov)
        
        let videoOutputSettings: Dictionary<String, AnyObject> = [
            AVVideoCodecKey: AVVideoCodecType.h264 as AnyObject,
            AVVideoWidthKey: iCapNYSWidth as AnyObject,
            AVVideoHeightKey: iCapNYSHeight as AnyObject
        ]
        fileWriterInput = AVAssetWriterInput(mediaType:AVMediaType.video, outputSettings: videoOutputSettings)
        fileWriterInput.expectsMediaDataInRealTime = true
        fileWriter.add(fileWriterInput)
        
        fileWriterAdapter = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: fileWriterInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String:Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferHeightKey as String: iCapNYSWidth,
                kCVPixelBufferWidthKey as String: iCapNYSHeight,
            ]
        )
    }

    override func viewDidAppear(_ animated: Bool) {

    }
    func setProperty(label:UILabel,radius:CGFloat){
        label.layer.masksToBounds = true
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.borderWidth = 1.0
        label.layer.cornerRadius = radius
    }
    var focusChangeable:Bool=true
    func setFocus(focus:Float) {//focus 0:最接近　0-1.0
        focusChangeable=false
        if let device = videoDevice{
            if device.isFocusModeSupported(.autoFocus) && device.isFocusPointOfInterestSupported {
                print("focus_supported")
                do {
                    try device.lockForConfiguration()
                    device.focusMode = .locked
                    device.setFocusModeLocked(lensPosition: focus, completionHandler: { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                            device.unlockForConfiguration()
                        })
                    })
                    device.unlockForConfiguration()
                    focusChangeable=true
                }
                catch {
                    // just ignore
                    print("focuserror")
                }
            }else{
                print("focus_not_supported")

//                if cameraType==2{
//                    setZoom(level: focus*4/10)//vHITに比べてすでに1/4にしてあるので
//                    return
//                }
            }
        }
    }
    func setExpose(expose:Float) {
        
        if let currentDevice=videoDevice{
            do {
                try currentDevice.lockForConfiguration()
                defer { currentDevice.unlockForConfiguration() }
                
                // 露出を設定
                
                    currentDevice.exposureMode = .autoExpose
                    currentDevice.setExposureTargetBias(expose, completionHandler: nil)
                    
//                    UserDefaults.standard.set(expose, forKey: "cameraBrightnessValue")
          
            } catch {
                print("\(error.localizedDescription)")
            }
        }
    }
    func setButtons(){
        // recording button
        
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
        let by0=topPadding+sp
        let x0=leftPadding+sp*2
        
//        let by=wh-bh-sp

//        let height=CGFloat(camera.getUserDefaultFloat(str: "buttonsHeight", ret: 0))
////        let leftPadding=CGFloat( UserDefaults.standard.integer(forKey:"leftPadding"))
////        let rightPadding=CGFloat(UserDefaults.standard.integer(forKey:"rightPadding"))
////        let topPadding=CGFloat(UserDefaults.standard.integer(forKey:"topPadding"))
////        let bottomPadding=CGFloat(UserDefaults.standard.integer(forKey:"bottomPadding"))
//        let ww:CGFloat=view.bounds.width-leftPadding-rightPadding
//        let wh:CGFloat=view.bounds.height-topPadding-bottomPadding/2
////        let sp=realWinWidth/120//間隙
//        let sp=ww/120//間隙
////        let bw=(realWinWidth-sp*10)/7//ボタン幅
//        let bw=(ww-sp*10)/7//ボタン幅
//        let bh=bw*170/440
//        let by1=ww-bh-sp-height
////        let by=realWinHeight-(bh+sp)*2-height
//        let by2=realWinHeight-(bh+sp)*2.5-height

//        let x0=leftPadding+sp*2
        camera.setButtonProperty(exitButton,x:x0+bw*6+sp*6,y:by,w:bw,h:bh,UIColor.darkGray)
//        exitButton.isHidden=true
//        exitButton.alpha=1.0
        setProperty(label: currentTime, radius: 4)
        currentTime.font = UIFont.monospacedDigitSystemFont(ofSize: view.bounds.width/30, weight: .medium)
        currentTime.frame = CGRect(x:x0+sp*6+bw*6, y: topPadding+sp, width: bw, height: bh)
        currentTime.alpha=0.5
//        quaternionView.frame=CGRect(x:leftPadding+sp,y:sp,width:realWinHeight/5,height:realWinHeight/5)
        quaternionView.frame=CGRect(x:leftPadding+sp,y:sp,width:wh/5,height:wh/5)
 //        topEndBlankSwitch.frame = CGRect(x:leftPadding+realWinHeight/5+2*sp+20,y:sp,width:switchWidth,height:bh)
//        topEndBlankLabel.frame = CGRect(x:topEndBlankSwitch.frame.maxX+sp,y:sp+switchHeight/2-bh/2,width:realWinWidth,height: bh)

        
//        quaternionView.layer.position=CGPoint(x:ww/12+10,y:leftPadding! + ww/12+10)
//        if setteiMode==true{
//        startButton.frame=CGRect(x:leftPadding+realWinWidth/2-realWinHeight/4,y:realWinHeight/4+topPadding,width: realWinHeight/2,height: realWinHeight/2)
//        }else{
//        startButton.frame=CGRect(x:leftPadding+realWinWidth/2-realWinHeight/2,y:sp+topPadding,width: realWinHeight,height: realWinHeight)
//        }
//        stopButton.frame=CGRect(x:leftPadding+realWinWidth/2-realWinHeight/2,y:sp+topPadding,width: realWinHeight,height: realWinHeight)
//        panTapExplanation.frame=CGRect(x:leftPadding,y:topPadding,width:realWinWidth,height:realWinHeight/2)
//        if cameraType==0{
//            previewSwitch.isHidden=false
//            previewLabel.isHidden=false
//        }else{
//            previewSwitch.isHidden=true
//            previewLabel.isHidden=true
//        }
//        if setteiMode==false{//slider labelを隠す
//                hideButtonsSlides()
////        }else{
////            startButton.isEnabled=false
//        }
//        topEndBlankLabel.isHidden=true
//        topEndBlankSwitch.isHidden=true
    }
    
    //debug用、AVAssetWriterの状態を見るため、そのうち消去
    func printWriterStatus(writer: AVAssetWriter) {
        print("recordingFlag=", recordingFlag)
        switch writer.status {
        case .unknown :
            print("unknown")
        case .writing :
            print("writing")
        case .completed :
            print("completed")
        case .failed :
            print("failed")
        case .cancelled :
            print("cancelled")
        default :
            print("default")
        }
    }
    func monoChromeFilter(_ input: CIImage, intensity: Double) -> CIImage? {
        let ciFilter:CIFilter = CIFilter(name: "CIColorMonochrome")!
        ciFilter.setValue(input, forKey: kCIInputImageKey)
        ciFilter.setValue(CIColor(red: intensity, green: intensity, blue: intensity), forKey: "inputColor")
        ciFilter.setValue(1.0, forKey: "inputIntensity")
        return ciFilter.outputImage
      }
    func sepiaFilter(_ input: CIImage, intensity: Double) -> CIImage? {
          let sepiaFilter = CIFilter(name: "CISepiaTone")
          sepiaFilter?.setValue(input, forKey: kCIInputImageKey)
          sepiaFilter?.setValue(intensity, forKey: kCIInputIntensityKey)
          return sepiaFilter?.outputImage
       }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
     
        if fileWriter.status == .writing && startTimeStamp == 0 {
            startTimeStamp = sampleBuffer.outputPresentationTimeStamp.value
        }

        //全部UIImageで処理してるが、これでは遅いので全てCIImageで処理するように書き換えたほうがよさそう
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            //フレームが取得できなかった場合にすぐ返る
            print("unable to get image from sample buffer")
            return
        }
        //backCamera->.right  frontCamera->.left
        let frameCIImage = cameraType==0 ? CIImage(cvImageBuffer: frame).oriented(CGImagePropertyOrientation.right):CIImage(cvImageBuffer: frame).oriented(CGImagePropertyOrientation.left)
        let matrix1 = CGAffineTransform(rotationAngle: -1*CGFloat.pi/2)
//        let matrix = CGAffineTransform(scaleX: -1.5, y: 2.0)
        //width:1280と設定しているが？
        //width:1920で飛んで来ている
          let matrix2 = CGAffineTransform(translationX: 0, y: CGFloat(1080))
//        let matrix2 = CGAffineTransform(translationX: 0, y: CGFloat(iCapNYSWidth))
        //2つのアフィンを組み合わせ
        let matrix = matrix1.concatenating(matrix2);
        
        let rotatedCIImage = monoChromeFilter(frameCIImage.transformed(by: matrix),intensity: 0.9)
        
//        print(rotatedCIImage.cgImage?.width)
//        print("width*height",frameCIImage.extent.width,frameCIImage.extent.height)
//        print("width*height",rotatedCIImage.cgImage?.width ?? <#default value#>! as Any,rotatedCIImage.cgImage??.height)
        readingFlag=true
        let qCG0=CGFloat(quater0)
        let qCG1=CGFloat(quater1)
        let qCG2=CGFloat(quater2)
        let qCG3=CGFloat(quater3)
//        print(quater0,quater1,quater2,quater3)

        readingFlag=false
        
//        let quaterImage = drawHead(width: 130, height: 130, radius: 50+10,qOld0:qCG0, qOld1: qCG1, qOld2:qCG2,qOld3:qCG3)
        let quaterImage = drawHead(width: realWinHeight/2.5, height: realWinHeight/2.5, radius: realWinHeight/5-1,qOld0:qCG0, qOld1: qCG1, qOld2:qCG2,qOld3:qCG3)
        DispatchQueue.main.async {
          self.quaternionView.image = quaterImage
          self.quaternionView.setNeedsLayout()
        }
        //frameの時間計算, sampleBufferの時刻から算出
        let frameTime:CMTime = CMTimeMake(value: sampleBuffer.outputPresentationTimeStamp.value - startTimeStamp, timescale: sampleBuffer.outputPresentationTimeStamp.timescale)
        let frameUIImage = UIImage(ciImage: rotatedCIImage!)
//        print(frameUIImage.size.width,frameUIImage.size.height)
//        let iCapNYSH=CGFloat(iCapNYSHeight)
//        let iCapNYSW=CGFloat(iCapNYSWidth)
        UIGraphicsBeginImageContext(CGSize(width: iCapNYSWidthF, height: iCapNYSHeightF))
        frameUIImage.draw(in: CGRect(x:0, y:0, width:iCapNYSWidthF, height: iCapNYSHeightF))
        //let r=view.bounds.height/view.bounds.width
//        let r=iCapNYSH/iCapNYSW
        quaterImage.draw(in: CGRect(x:iCapNYSWidthF120, y:iCapNYSWidthF120, width:iCapNYSHeightF5,height: iCapNYSHeightF5))
        //写真で再生すると左上の頭位アニメが隠れてしまうので、中央右にも表示。
//        quaterImage.draw(in: CGRect(x:0/*CGFloat(iCapNYSHeight)-quaterImage.size.width*/, y:CGFloat(iCapNYSWidth)*3/4, width:quaterImage.size.width, height:quaterImage.size.height))
        let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let renderedBuffer = (renderedImage?.toCVPixelBuffer())!
//        print(String(format:"%.5f,%.5f,%.5f,%.5f",quater0,quater1,quater2,quater3))
//        printWriterStatus(writer: fileWriter)
        if (recordingFlag == true && startTimeStamp != 0 && fileWriter!.status == .writing) {
            if fileWriterInput?.isReadyForMoreMediaData != nil{
                //for speed check
                fileWriterAdapter.append(renderedBuffer, withPresentationTime: frameTime)
            }
        } else {
            //print("not writing")
        }
    }
    func onClickStopButton() {
        recordingFlag=false

        if let soundUrl = URL(string:
                                "/System/Library/Audio/UISounds/begin_record.caf"){
            AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundIdx)
            AudioServicesPlaySystemSound(soundIdx)
        }
        
        motionManager.stopDeviceMotionUpdates()

        if fileWriter!.status == .writing {
            fileWriter!.finishWriting {
                debugPrint("trying to finish")
                return
            }
            while fileWriter!.status == .writing {
                sleep(UInt32(0.1))
            }
            debugPrint("done!!")
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
//            stopButton.isHidden=true
            //と変更することで、Exitボタンで帰った状態にする。
        }
        motionManager.stopDeviceMotionUpdates()
        captureSession.stopRunning()
//        killTimer()
        while saved2album==false{
            sleep(UInt32(0.1))
        }
//        performSegue(withIdentifier: "fromAutoRecord", sender: self)
    }
    func onClickStartButton() {
          if cameraType==0{
            let mainBrightness = UIScreen.main.brightness
            UserDefaults.standard.set(mainBrightness, forKey: "mainBrightness")
            UIScreen.main.brightness = 1
        }
        
        motionManager.stopDeviceMotionUpdates()
        recordingFlag=true
        //start recording
        //          exitButton.isHidden=true
        quaternionView.isHidden=true
        cameraView.isHidden=true
        currentTime.alpha=0.1
        try? FileManager.default.removeItem(atPath: TempFilePath)

        UIApplication.shared.isIdleTimerDisabled = true//スリープしない
       //        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

       if let soundUrl = URL(string:
                               "/System/Library/Audio/UISounds/begin_record.caf"/*photoShutter.caf*/){
           AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundIdx)
           AudioServicesPlaySystemSound(soundIdx)
       }

       fileWriter!.startWriting()
       fileWriter!.startSession(atSourceTime: CMTime.zero)
       setMotion()
    }
}

