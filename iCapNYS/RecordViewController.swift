//
//  RecordViewController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2020/09/22.
//

import UIKit
import AVFoundation
import GLKit
import Photos
import CoreMotion
import VideoToolbox

class RecordViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var soundIdstart:SystemSoundID = 1117
    var soundIdstop:SystemSoundID = 1118
    var soundIdpint:SystemSoundID = 1109//1009//7
    var soundIdx:SystemSoundID = 0

    var recordingFlag:Bool = false
    var saved2album:Bool = false
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
    var iCapNYSAlbum: PHAssetCollection? // アルバムをオブジェクト化
//    let ALBUMTITLE = "iCapNYS" // アルバム名
    // for video resolution/fps (constants)
    var iCapNYSWidth: Int32 = 0
    var iCapNYSHeight: Int32 = 0
    var iCapNYSFPS: Float64 = 0
//    var focusF:Float = 0
    
    //for gyro and face drawing
    var gyro = Array<Double>()

    var quater0:Double=0
    var quater1:Double=0
    var quater2:Double=0
    var quater3:Double=0
    var readingFlag = false
    var timer:Timer?
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
    
    
    @IBOutlet weak var focusFar: UILabel!
    @IBOutlet weak var focusNear: UILabel!
    @IBOutlet weak var focusBar: UISlider!
    
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    @IBOutlet weak var LEDBar: UISlider!
    @IBOutlet weak var LEDHigh: UILabel!
    @IBOutlet weak var LEDLow: UILabel!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var quaternionView: UIImageView!
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var topLabel: UILabel!//storyboardで使っている！大事

    func setFlashlevel(level:Float){
        if let device = videoDevice{
            do {
                if device.hasTorch {
                    do {
                        // torch device lock on
                        try device.lockForConfiguration()
                        
                        if (level > 0.0){
                            do {
                                try device.setTorchModeOn(level: level)
                            } catch {
                                print("error")
                            }
                            
                        } else {
                            // flash LED OFF
                            // 注意しないといけないのは、0.0はエラーになるのでLEDをoffさせます。
                            device.torchMode = AVCaptureDevice.TorchMode.off
                        }
                        // torch device unlock
                        device.unlockForConfiguration()
                        
                    } catch {
                        print("Torch could not be used")
                    }
                }
            }
        }
    }
    
    func killTimer(){
        if timer?.isValid == true {
            timer!.invalidate()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        camera_alert()
        set_rpk_ppk()
        setMotion()
        initSession(fps: 30)//60)//遅ければ30fpsにせざるを得ないかも
  
        startButton.isHidden=false
        stopButton.isHidden=true
        currentTime.isHidden=true
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        //露出はオートの方が良さそう

        focusBar.minimumValue = 0
        focusBar.maximumValue = 1.0
        focusBar.addTarget(self, action: #selector(onSliderValueChange), for: UIControl.Event.valueChanged)
        focusBar.value=getUserDefault(str: "focusLength", ret: 0)
    
        setFocus(focus: focusBar.value)
        
        LEDBar.minimumValue = 0
        LEDBar.maximumValue = 0.1
        LEDBar.addTarget(self, action: #selector(onLEDValueChange), for: UIControl.Event.valueChanged)
        LEDBar.value=getUserDefault(str: "LEDValue", ret:0)
        setFlashlevel(level: LEDBar.value)
 
        setButtons(type: true)
    }
    func getUserDefault(str:String,ret:Float) -> Float{
        if (UserDefaults.standard.object(forKey: str) != nil){
            return UserDefaults.standard.float(forKey: str)
        }else{//keyが設定してなければretをセット
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    
    @objc func onLEDValueChange(){
        setFlashlevel(level: LEDBar.value)
        UserDefaults.standard.set(LEDBar.value, forKey: "LEDValue")
    }
    @objc func onSliderValueChange(){
        setFocus(focus:focusBar.value)
        UserDefaults.standard.set(focusBar.value, forKey: "focusLength")
    }
    var timerCnt:Int=0
    @objc func update(tm: Timer) {
        timerCnt += 1
        UserDefaults.standard.set(videoDevice?.lensPosition, forKey: "focusLength")
        focusBar.value=videoDevice!.lensPosition
        if recordingFlag==true{//trueになった時 0にリセットされる
            currentTime.text=String(format:"%01d",timerCnt/60) + ":" + String(format: "%02d",timerCnt%60)
            if timerCnt%2==0{
                stopButton.tintColor=UIColor.orange
            }else{
                stopButton.tintColor=UIColor.red
            }
        }
        if timerCnt > 60*5{
            if recordingFlag==true{
                killTimer()
                onClickStopButton(0)
            }else{
                killTimer()
                performSegue(withIdentifier: "fromRecord", sender: self)
            }
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
            while self.readingFlag==true{
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
    
    func drawHead(width w:CGFloat, height h:CGFloat, radius r:CGFloat, qOld0:CGFloat, qOld1:CGFloat, qOld2:CGFloat, qOld3:CGFloat)->UIImage{
        //        var ppk:[CGFloat]=[]
//        print(String(format:"%.3f,%.3f,%.3f,%.3f",qOld0,qOld1,qOld2,qOld3))
        var ppk = Array(repeating: CGFloat(0), count:500)
        //  pk_ken = &pk_ken2[0][0];//no smile
        let faceX0:CGFloat = w/2;
        let faceY0:CGFloat = h/2;//center
        let faceR:CGFloat = r;//hankei
        let defaultRadius:CGFloat = 40.0
        let size = CGSize(width:w, height:h)
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
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)

        let drawPath = UIBezierPath(arcCenter: CGPoint(x: faceX0, y:faceY0), radius: faceR, startAngle: 0, endAngle: CGFloat(Double.pi)*2, clockwise: true)
        // 内側の色
//        UIColor(red: 1, green: 1, blue:1, alpha: 0.8).setFill()
        UIColor.white.setFill()// (red: 1, green: 1, blue:1, alpha: 0.8).setFill()

//        // 内側を塗りつぶす
        drawPath.fill()

        let uraPoint=faceR/40.0//この値の意味がよくわからなかった

        var endpointF=true//終点でtrueとする

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

        // 取得したフォーマットを格納する変数
        var selectedFormat: AVCaptureDevice.Format! = nil
        // そのフレームレートの中で一番大きい解像度を取得する
        var maxWidth: Int32 = 0
        
        // フォーマットを探る
//        var getDesiedformat:Bool=false
        for format in videoDevice!.formats {
            // フォーマット内の情報を抜き出す (for in と書いているが1つの format につき1つの range しかない)
//            if getDesiedformat==true{
//                break
//            }
            for range: AVFrameRateRange in format.videoSupportedFrameRateRanges {
                let description = format.formatDescription as CMFormatDescription    // フォーマットの説明
                let dimensions = CMVideoFormatDescriptionGetDimensions(description)  // 幅・高さ情報を抜き出す
                let width = dimensions.width
//                print(dimensions.width,dimensions.height)
                if desiredFps == range.maxFrameRate && width == 1280{//}>= maxWidth {
                    selectedFormat = format
                    maxWidth = width
 //                   getDesiedformat=true
                    print(range.maxFrameRate,dimensions.width,dimensions.height)
 //                   break
                }
            }
        }
//ipod touch 1280x720 1440*1080
//SE 960x540 1280x720 1920x1080
//11 192x144 352x288 480x360 640x480 1024x768 1280x720 1440x1080 1920x1080 3840x2160
//1280に設定すると上手く行く。合成のところには1920x1080で飛んでくるようだ。？
        // フォーマットが取得できていれば設定する
        if selectedFormat != nil {
            do {
                try videoDevice!.lockForConfiguration()
                videoDevice!.activeFormat = selectedFormat
//                videoDevice!.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(desiredFps))
                videoDevice!.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(desiredFps))
                videoDevice!.unlockForConfiguration()
                
                let description = selectedFormat.formatDescription as CMFormatDescription    // フォーマットの説明
                let dimensions = CMVideoFormatDescriptionGetDimensions(description)  // 幅・高さ情報を抜き出す
                iCapNYSWidth = dimensions.width
                iCapNYSHeight = dimensions.height
                iCapNYSFPS = desiredFps
                print("フォーマット・フレームレートを設定 : \(desiredFps) fps・\(iCapNYSWidth) px x \(iCapNYSHeight) px")
                
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
 
    // アルバムが既にあるか確認し、iCapNYSAlbumに代入
    func albumExists(albumTitle: String) -> Bool {
        // ここで以下のようなエラーが出るが、なぜか問題なくアルバムが取得できている
        // [core] "Error returned from daemon: Error Domain=com.apple.accounts Code=7 "(null)""
        let albums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype:
            PHAssetCollectionSubtype.albumRegular, options: nil)
        for i in 0 ..< albums.count {
            let album = albums.object(at: i)
            if album.localizedTitle != nil && album.localizedTitle == albumTitle {
                iCapNYSAlbum = album
                return true
            }
        }
        return false
    }
    
    //何も返していないが、ここで見つけたor作成したalbumを返したい。そうすればグローバル変数にアクセスせずに済む
    func createNewAlbum(albumTitle: String, callback: @escaping (Bool) -> Void) {
        if self.albumExists(albumTitle: albumTitle) {
            callback(true)
        } else {
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumTitle)
            }) { (isSuccess, error) in
                callback(isSuccess)
            }
        }
    }
    
    func camera_alert(){
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    // フォトライブラリに写真を保存するなど、実施したいことをここに書く
                } else if status == .denied {
                }
            }
        } else {
            // フォトライブラリに写真を保存するなど、実施したいことをここに書く
        }
    }
    
    func initSession(fps:Double) {
        // カメラ入力 : 背面カメラ
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)

        if setVideoFormat(desiredFps: fps)==false{
            print("error******")
        }
        // AVCaptureSession生成
        captureSession = AVCaptureSession()
        captureSession.addInput(videoInput)
 
        // プレビュー出力設定
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill//無くても同じ
        //self.view.layer.addSublayer(videoLayer)
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
//        fileOutput = AVCaptureMovieFileOutput()
//        fileOutput.maxRecordedDuration = CMTimeMake(value:5*60, timescale: 1)//最長録画時間
//        session.addOutput(fileOutput)
        //ファイル出力設定　writer使用
//        print ("TempFilePATH",TempFilePath)
        startTimeStamp = 0
        //一時ファイルはこの時点で必ず消去
        //start recordのところで消去でも動くようだ。Exitで抜けた時は消さないように下行はコメントアウト
//        try? FileManager.default.removeItem(atPath: TempFilePath)
        let fileURL = NSURL(fileURLWithPath: TempFilePath)
        setMotion()//作動中ならそのまま戻る
        fileWriter = try? AVAssetWriter(outputURL: fileURL as URL, fileType: AVFileType.mov)
        
        let videoOutputSettings: Dictionary<String, AnyObject> = [
            AVVideoCodecKey: AVVideoCodecType.h264 as AnyObject,
            AVVideoHeightKey: iCapNYSWidth as AnyObject,
            AVVideoWidthKey: iCapNYSHeight as AnyObject
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
//        setButtons(type: true)
    }
    func setProperty(label:UILabel,radius:CGFloat){
        label.layer.masksToBounds = true
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.borderWidth = 1.0
        label.layer.cornerRadius = radius
    }
    func setButtons(type:Bool){
        // recording button
        let topY=topLabel.frame.maxY
        let ww:CGFloat=view.bounds.width
        let wh:CGFloat=view.bounds.height//dammyBottom.frame.maxY// view.bounds.height
        let bw=ww*3/5

        let bh=bw//:Int=60
        currentTime.frame = CGRect(x:0,y: 0 ,width:ww/5, height: ww/10)
        currentTime.layer.position=CGPoint(x:ww-bw*11/60,y:topY+ww/20+10)//wh-bh*4/5)
  //      currentTime.layer.masksToBounds = true
//        currentTime.layer.cornerRadius = 10
        setProperty(label: currentTime, radius: 10)
        currentTime.font = UIFont.monospacedDigitSystemFont(ofSize: 25*view.bounds.width/320, weight: .medium)

        //startButton
        startButton.frame=CGRect(x:0,y:0,width:bw,height:bw)
        startButton.layer.position = CGPoint(x:ww/2,y:wh-bh*4/5)
        stopButton.frame=CGRect(x:0,y:0,width:bw,height:bw)
        stopButton.layer.position = CGPoint(x:ww/2,y:wh-bh*4/5)
        exitButton.frame=CGRect(x:0,y:0,width:bw/3,height:bh/5)
        exitButton.layer.position = CGPoint(x:ww-bw*11/60,y:topY+ww/20+10)//+wh-bh*4/5)
        exitButton.layer.borderColor = UIColor.black.cgColor
        exitButton.layer.borderWidth = 1.0
        exitButton.layer.cornerRadius = 10
        setProperty(label: focusFar, radius: 5)
        setProperty(label: focusNear, radius: 5)
        setProperty(label: LEDLow, radius: 5)
        setProperty(label: LEDHigh, radius: 5)

        startButton.isHidden=false
        stopButton.isHidden=true
        stopButton.tintColor=UIColor.orange
        
        quaternionView.frame=CGRect(x:0,y:0,width:ww/6,height:ww/6)
        quaternionView.layer.position=CGPoint(x:ww/12+10,y:topY + ww/12+10)

    }
    func albumCheck(){//ここでもチェックしないとダメのよう
        if albumExists(albumTitle: "iCapNYS")==false{
            createNewAlbum(albumTitle: "iCapNYS") { (isSuccess) in
                if isSuccess{
                    print("iCapNYS_album can be made,")
                } else{
                    print("iCapNYS_album can't be made.")
                }
            }
        }else{
            print("iCapNYS_album exist already.")
        }
    }
    @IBAction func onClickStopButton(_ sender: Any) {
        albumCheck()//start&stopでチェックしないとダメのよう
        // stop recording
        debugPrint("onClickStopButton")
        recordingFlag=false
        if let soundUrl = URL(string:
                          "/System/Library/Audio/UISounds/end_record.caf"/*photoShutter.caf*/){
            AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundIdx)
            AudioServicesPlaySystemSound(soundIdx)
        }
        if fileWriter!.status == .writing {

            fileWriter!.finishWriting {
                debugPrint("trying to finish")
                return
            }
            while fileWriter!.status == .writing {
                usleep(1)
            }
            debugPrint("done!!")
        }
        
        if FileManager.default.fileExists(atPath: TempFilePath){
            print("tempFileExists")
        }
        let fileURL = URL(fileURLWithPath: TempFilePath)
        //let avAsset = AVAsset(url: fileURL)
        PHPhotoLibrary.shared().performChanges({
            //let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: avAsset)
            let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)!
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: (self.iCapNYSAlbum)!)
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
//            _ = try? FileManager.default.removeItem(atPath: self.TempFilePath)
        }
        motionManager.stopDeviceMotionUpdates()
        captureSession.stopRunning()
        killTimer()
        performSegue(withIdentifier: "fromRecord", sender: self)
    }
    
    @IBAction func onClickStartButton(_ sender: Any) {

        focusNear.isHidden=true
        focusFar.isHidden=true
        focusBar.isHidden=true
        LEDLow.isHidden=true
        LEDHigh.isHidden=true
        LEDBar.isHidden=true
        albumCheck()//record start stopでチェックする
        //sensorをリセットし、正面に
        motionManager.stopDeviceMotionUpdates()
        recordingFlag=true
        //start recording
        startButton.isHidden=true
        stopButton.isHidden=false
        currentTime.isHidden=false
        exitButton.isHidden=true
        
        try? FileManager.default.removeItem(atPath: TempFilePath)

        timerCnt=0
//        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
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

    func autoExpose(){
 
        let focusPoint = CGPoint(x:0.25,y:0.5)
        
        if let device = videoDevice{
            do {
                try device.lockForConfiguration()
                // 露出の設定
                if device.isExposureModeSupported(.continuousAutoExposure) && device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = focusPoint
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
            }
            catch {
                // just ignore
            }
        }
    }
   
    @IBAction func tapGest(_ sender: UITapGestureRecognizer) {
        if recordingFlag==true{
            return
        }
        setMotion()
        let screenSize=cameraView.bounds.size
        let x0 = sender.location(in: self.view).x
        let y0 = sender.location(in: self.view).y
//        print("tap:",x0,y0,screenSize,view.bounds)
        
        if y0>view.bounds.height*0.43{//screenSize.height/2{
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

                device.unlockForConfiguration()
 
            }
            catch {
                // just ignore
            }
        }
    }
    func setFocus(focus:Float) {//focus 0:最接近　0-1.0
         if let device = videoDevice{
            do {
                try device.lockForConfiguration()
                device.focusMode = .locked
                device.setFocusModeLocked(lensPosition: focus, completionHandler: { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                        device.unlockForConfiguration()
                    })
                })
                device.unlockForConfiguration()
            }
            catch {
                // just ignore
            }
//            print("lensPosition:",device.lensPosition)
        }
    }

    func setExpose(expose:Float){
//    @IBAction func onExposeChanged1(_ sender: UISlider) {
        if let device = videoDevice{
            //        let tag: Int = sender.tag
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                
                //          露出を設定
                device.exposureMode = .autoExpose
                device.setExposureTargetBias(expose, completionHandler: nil)
                
            } catch {
                print("\(error.localizedDescription)")
            }
        }
    }
    @IBAction func onISOChanged(_ sender: UISlider) {
        if let device = videoDevice{
            //        let tag: Int = sender.tag
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                
                //          露出を設定
//                device.exposureMode = .autoExpose
//                device.setExposureTargetBias(sender.value, completionHandler: nil)
                //          ISO感度を設定
                device.exposureMode = .custom
                device.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration,
                                             iso: sender.value,
                                             completionHandler: nil)
//                device.unlockForConfiguration()
                
            } catch {
                print("\(error.localizedDescription)")
            }
        }
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
    
//    var lastFrameTime: Int64 = 0
    
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
        let frameCIImage = CIImage(cvImageBuffer: frame)
        //kaiten
        let matrix1 = CGAffineTransform(rotationAngle: -1 * CGFloat.pi / 2)
//        let matrix = CGAffineTransform(scaleX: -1.5, y: 2.0)
        //width:1280と設定しているが？
        //width:1920で飛んで来ている
        let matrix2 = CGAffineTransform(translationX: 0, y: CGFloat(1920))
        //2つのアフィンを組み合わせ
        let matrix = matrix1.concatenating(matrix2);
        let rotatedCIImage = frameCIImage.transformed(by: matrix)
        readingFlag=true
        let qCG0=CGFloat(quater0)
        let qCG1=CGFloat(quater1)
        let qCG2=CGFloat(quater2)
        let qCG3=CGFloat(quater3)
//        print(quater0,quater1,quater2,quater3)

        readingFlag=false
        
        let quaterImage = drawHead(width: 130, height: 130, radius: 60,qOld0:qCG0, qOld1: qCG1, qOld2:qCG2,qOld3:qCG3)
        DispatchQueue.main.async {
          self.quaternionView.image = quaterImage
          self.quaternionView.setNeedsLayout()
        }
        //frameの時間計算, sampleBufferの時刻から算出
        let frameTime:CMTime = CMTimeMake(value: sampleBuffer.outputPresentationTimeStamp.value - startTimeStamp, timescale: sampleBuffer.outputPresentationTimeStamp.timescale)

        //var frameCGImage: CGImage?
        //VTCreateCGImageFromCVPixelBuffer(frame, options: nil, imageOut: &frameCGImage)
        //let frameUIImage = UIImage(cgImage: frameCGImage!)
        let frameUIImage = UIImage(ciImage: rotatedCIImage)
//        print(frameUIImage.size.width,frameUIImage.size.height)
        UIGraphicsBeginImageContext(CGSize(width: CGFloat(iCapNYSHeight), height: CGFloat(iCapNYSWidth)))
        
        frameUIImage.draw(in: CGRect(x: 0, y: 0, width: CGFloat(iCapNYSHeight), height: CGFloat(iCapNYSWidth)))
        quaterImage.draw(in: CGRect(x:0, y:0, width:quaterImage.size.width, height:quaterImage.size.height))
        //写真で再生すると左上の頭位アニメが隠れてしまうので、中央右にも表示。
        quaterImage.draw(in: CGRect(x:0/*CGFloat(iCapNYSHeight)-quaterImage.size.width*/, y:CGFloat(iCapNYSWidth)*3/4, width:quaterImage.size.width, height:quaterImage.size.height))
        let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let renderedBuffer = (renderedImage?.toCVPixelBuffer())!
//        print(String(format:"%.5f,%.5f,%.5f,%.5f",quater0,quater1,quater2,quater3))
//        printWriterStatus(writer: fileWriter)
        if (recordingFlag == true && startTimeStamp != 0 && fileWriter!.status == .writing) {
            if fileWriterInput?.isReadyForMoreMediaData != nil{
                //for speed check
//                print(frameTime.value - lastFrameTime)
//                lastFrameTime = frameTime.value
                //
                fileWriterAdapter.append(renderedBuffer, withPresentationTime: frameTime)
            }
        } else {
            //print("not writing")
        }
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
