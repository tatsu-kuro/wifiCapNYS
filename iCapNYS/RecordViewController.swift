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
extension UIColor {
    func image(size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill() // 色を指定
            rendererContext.fill(.init(origin: .zero, size: size)) // 塗りつぶす
        }
    }
}

class RecordViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    let camera = myFunctions()
//    var mainBrightness:CGFloat=0
    var cameraType:Int = 0
    var soundIdstart:SystemSoundID = 1117
    var soundIdstop:SystemSoundID = 1118
    var soundIdpint:SystemSoundID = 1109//1009//7
    var soundIdx:SystemSoundID = 0
    let albumName:String = "iCapNYS"
    var recordingFlag:Bool = false
    var saved2album:Bool = false
    let motionManager = CMMotionManager()
    @IBOutlet weak var previewSwitch: UISwitch!
    
    @IBAction func onPreviewSwitch(_ sender: Any) {
        if previewSwitch.isOn==true{
            UserDefaults.standard.set(1, forKey: "previewOn")
        }else{
            UserDefaults.standard.set(0, forKey: "previewOn")
        }
    }
    @IBOutlet weak var previewLabel: UILabel!
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
    var iCapNYSFPS: Float64 = 0
    //for gyro and face drawing
    var gyro = Array<Double>()
    let someFunctions = myFunctions()
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
 
    @IBAction func onSpeakerSwitch(_ sender: UISwitch) {
        if speakerSwitch.isOn==true{
            UserDefaults.standard.set(1, forKey: "recordSound")
            speakerLabel.tintColor=UIColor.green
        }else{
            UserDefaults.standard.set(0, forKey: "recordSound")
            speakerLabel.tintColor=UIColor.gray
        }
    }
//    @IBOutlet weak var speakerSwitch: UISwitch!
//
//    @IBOutlet weak var speakerLabel: UIImageView!
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
    
    
    @IBOutlet weak var focusLabel: UILabel!
//    @IBOutlet weak var zoomLabel: UILabel!
    @IBOutlet weak var focusBar: UISlider!
    
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var speakerSwitch: UISwitch!
    
    @IBOutlet weak var exposeLabel: UILabel!
    //    @IBOutlet weak var speakerImage: UIImageView!
        @IBOutlet weak var speakerLabel: UIImageView!
    @IBOutlet weak var zoomLabel: UILabel!
//    @IBOutlet weak var zoomFar: UILabel!
    @IBOutlet weak var zoomBar: UISlider!
    @IBOutlet weak var lightBar: UISlider!
    @IBOutlet weak var lightLabel: UILabel!
//    @IBOutlet weak var LEDLow: UILabel!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var quaternionView: UIImageView!
    @IBOutlet weak var cameraView:
        UIImageView!
    
    @IBOutlet weak var panTapExplanation: UILabel!
    @IBOutlet weak var whiteView: UIImageView!
    
    @IBOutlet weak var arrowUpDown: UIImageView!
    //    @IBOutlet weak var topLabel: UILabel!//storyboardで使っている！大事

    @IBOutlet weak var cameraChangeButton: UIButton!
   
//    func setBars(){
//        if cameraType==0 || cameraType==3{
//            lightBar.value=camera.getUserDefaultFloat(str: "screenBrightnessValue", ret: 1.0)
//            UIScreen.main.brightness = 10*CGFloat(lightBar.value)
//            focusBar.value=camera.getUserDefaultFloat(str: "zoomValue", ret: 0)
//            setZoom(level: focusBar.value)
////            focusLabel.text = "拡大"
////            zoomLabel.text = "縮小"
//        }else{
//            focusBar.value=camera.getUserDefaultFloat(str: "focusValue", ret: 0)
//            setFocus(focus: focusBar.value)
//            lightBar.value=camera.getUserDefaultFloat(str: "ledValue", ret: 0)
//            setFlashlevel(level: lightBar.value)
////            focusLabel.text = "遠い"//false
////            zoomLabel.text = "近い"//isHidden=false
//        }
//    }
    func setZoom(level:Float){//
        let zoom=level*level/4
        if let device = videoDevice {
        do {
            try device.lockForConfiguration()
                device.ramp(
                    toVideoZoomFactor: (device.minAvailableVideoZoomFactor) + CGFloat(zoom) * ((device.maxAvailableVideoZoomFactor) - (device.minAvailableVideoZoomFactor)),
                    withRate: 30.0)
            device.unlockForConfiguration()
            } catch {
                print("Failed to change zoom.")
            }
        }
    }
    
    func setFlashlevel(level:Float){
        if cameraType != 0{
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
        }else{//front camera
            
        }
    }
    
    func killTimer(){
        if timer?.isValid == true {
            timer!.invalidate()
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
    /*
     override func viewDidLoad() {
         super.viewDidLoad()
         getCameras()
         cameraType=getUserDefault(str: "cameraType", ret: 0)
 //        if (UserDefaults.standard.object(forKey: "cameraType") != nil){//keyが設定してなければretをセット
 //            cameraType=UserDefaults.standard.integer(forKey:"cameraType")
 //        }else{
 //            cameraType=0
 //            UserDefaults.standard.set(cameraType, forKey: "cameraType")
 //        }
         let sound=getUserDefault(str: "recordSound", ret: 1)
         if sound==0{
             speakerSwitch.isOn=false
         }else{
             speakerSwitch.isOn=true
         }

     */
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getCameras()
        camera.makeAlbum()
        //speakerSwitchは、ipod touchの時に便利
//        let sound=getUserDefault(str: "recordSound", ret: 1)
//        if sound==0{
//            speakerSwitch.isOn=false
//            speakerLabel.tintColor=UIColor.gray
//        }else{
//            speakerSwitch.isOn=true
//            speakerLabel.tintColor=UIColor.green
//        }
        let previewOn=getUserDefault(str: "previewOn", ret: 0)
        if previewOn==0{
            previewSwitch.isOn=false
        }else{
            previewSwitch.isOn=true
        }
        //speakerSwitch使用しない
        speakerLabel.isHidden=true
        speakerSwitch.isHidden=true
        UserDefaults.standard.set(1,forKey: "recordSound")
        
        if (UserDefaults.standard.object(forKey: "cameraType") != nil){//keyが設定してなければ0をセット
            cameraType=UserDefaults.standard.integer(forKey:"cameraType")
        }else{
            cameraType=0
            UserDefaults.standard.set(cameraType, forKey: "cameraType")
        }
    
        set_rpk_ppk()
        setMotion()
        initSession(fps: 60)//遅ければ30fpsにせざるを得ないかも、30fpsだ！

        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        //露出はオートの方が良さそう
    
        lightBar.minimumValue = 0
        lightBar.maximumValue = 0.1
        lightBar.addTarget(self, action: #selector(onLEDValueChange), for: UIControl.Event.valueChanged)
        lightBar.value=UserDefaults.standard.float(forKey: "")
        if cameraType==0{
            lightBar.value=camera.getUserDefaultFloat(str: "screenBrightnessValue", ret: 0.9)
//            lightBar.value=UserDefaults.standard.float(forKey: "screenBrightnessValue")
        }else{
            lightBar.value=UserDefaults.standard.float(forKey: "ledValue")
        }
        onLEDValueChange()
        

        focusBar.minimumValue = 0
        focusBar.maximumValue = 1.0
        focusBar.addTarget(self, action: #selector(onFocusValueChange), for: UIControl.Event.valueChanged)
        focusBar.value=UserDefaults.standard.float(forKey: "focusValue")
        onFocusValueChange()
        
        zoomBar.minimumValue = 0
        zoomBar.maximumValue = 1.0
        zoomBar.addTarget(self, action: #selector(onZoomValueChange), for: UIControl.Event.valueChanged)
        zoomBar.value=UserDefaults.standard.float(forKey: "zoomValue")
        onZoomValueChange()
        
        
        exposeBar.minimumValue = Float(videoDevice!.minExposureTargetBias)
        exposeBar.maximumValue = Float(videoDevice!.maxExposureTargetBias)
        exposeBar.addTarget(self, action: #selector(onExposeValueChange), for: UIControl.Event.valueChanged)
        exposeBar.value=camera.getUserDefaultFloat(str:"exposeValue",ret:0)
        onExposeValueChange()
        //        self.view.addSubview(brightnessSlider)
        //        // ISO感度用スライダー設定
//        isoBar.minimumValue = Float(videoDevice!.activeFormat.minISO)
//        isoBar.maximumValue = Float(videoDevice!.activeFormat.maxISO)
//        let isoHalf = (isoBar.minimumValue + isoBar.maximumValue) / 2
//        isoBar.addTarget(self, action: #selector(onIsoValueChange), for: UIControl.Event.valueChanged)
//        isoBar.value=camera.getUserDefaultFloat(str: "isoValue", ret: isoHalf)
//        onIsoValueChange()
        isoBar.isHidden=true//exposeとisoは互いに影響している？exposeだけ使う事とした
//        let buttonsHeight=CGFloat(camera.getUserDefaultFloat(str: "buttonsHeight", ret: 0))
        setButtons()//height:buttonsHeight)
        
        currentTime.isHidden=true
        startButton.alpha=0.25
        startButton.isHidden=false
        stopButton.isHidden=true
        stopButton.isEnabled=false
     }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    @objc func onZoomValueChange(){
//        if cameraType == 0 || cameraType==3{
           if cameraType==0{
               setZoom(level: zoomBar.value)
           }else{
               setZoom(level: zoomBar.value/3)
           }
           UserDefaults.standard.set(zoomBar.value, forKey: "zoomValue")
//       }
    }
    @objc func onLEDValueChange(){
        print("brightness:",lightBar.value)
        if cameraType==0{
            UIScreen.main.brightness = 10*CGFloat(lightBar.value)
            UserDefaults.standard.set(lightBar.value, forKey: "screenBrightnessValue")
//            print("screenBrightnessValue:",lightBar.value)
        }else{
            UIScreen.main.brightness=CGFloat(UserDefaults.standard.float(forKey: "mainBrightness"))
            setFlashlevel(level: lightBar.value)
            UserDefaults.standard.set(lightBar.value, forKey: "ledValue")
        }
    }
  
    var timerCnt:Int=0
    @objc func update(tm: Timer) {
        timerCnt += 1
//        if timerCnt>1{
//            stopButton.isHidden=false
//        }
//        UserDefaults.standard.set(videoDevice?.lensPosition, forKey: "focusLength")
//        focusBar.value=videoDevice!.lensPosition
        if recordingFlag==true{//trueになった時 0にリセットされる
            currentTime.text=String(format:"%01d",timerCnt/60) + ":" + String(format: "%02d",timerCnt%60)
            if timerCnt%2==0{
                stopButton.tintColor=UIColor.cyan
            }else{
                stopButton.tintColor=UIColor.yellow// red
            }
        }
        if timerCnt > 60*5{
            motionManager.stopDeviceMotionUpdates()//tuika
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
    /*
     
     void RotateX(float *x, float *y, float *z, float rad) {
         float  dy, dz;
         dy = *y * float(cos(rad)) - *z * float(sin(rad));
         dz = *y * float(sin(rad)) + *z * float(cos(rad));
         *y = dy;
         *z = dz;
     }

     void RotateY(float *x, float *y, float *z, float rad) {
         float dx,dz;// dy, dz;
         dx = *x * float(cos(rad)) + *z * float(sin(rad));
         dz = - *x * float(sin(rad)) + *z * float(cos(rad));
         *x = dx;
         *z = dz;
     }

     void RotateZ(float *x, float *y, float *z, float rad) {
         float dx, dy;//, dz;
         dx = *x * float(cos(rad)) - *y * float(sin(rad));
         dy = *x * float(sin(rad)) + *y * float(cos(rad));
         *x = dx;
         *y = dy;
     }

     void RotateQuat(float *x, float *y, float *z, float q0, float q1, float q2, float q3)
     {
         float ax, ay, az, norm, mag;
         
         mag =float( sqrt((q0 * q0) + (q1 * q1) + (q2 * q2) +(q3 * q3)));
         if (mag > FLT_EPSILON ) {
             norm = 1 / mag;
             q0 *= norm;
             q1 *= norm;
             q2 *= norm;
             q3 *= norm;
         }

         ax = *x * (q0 * q0 + q1 * q1 - q2 * q2 - q3 * q3) + *y * (2 * (q1 * q2 - q0 * q3)) + *z * (2 * (q1 * q3 + q0 * q2));
         ay = *x * (2 * (q1 * q2 + q0 * q3)) + *y * (q0 * q0 - q1 * q1 + q2 * q2 - q3 * q3) + *z * (2 * (q2 * q3 - q0 * q1));
         az = *x * (2 * (q1 * q3 - q0 * q2)) + *y * (2 * (q2 * q3 + q0 * q1)) + *z * (q0 * q0 - q1 * q1 - q2 * q2 + q3 * q3);
         *x = ax;
         *y = ay;
         *z = az;
     }
     void MultQuat(float *a0, float *a1, float *a2, float *a3, float q0, float q1, float q2, float q3, float p0, float p1, float p2, float p3)
     {
      *a0 = q0 * p0 - q1 * p1 - q2 * p2 - q3 * p3;
      *a1 = q1 * p0 + q0 * p1 - q3 * p2 + q2 * p3;
      *a2 = q2 * p0 + q3 * p1 + q0 * p2 - q1 * p3;
      *a3 = q3 * p0 - q2 * p1 + q1 * p2 + q0 * p3;
     }
     void QuatXchan(float *q0,float *q1,float *q2,float *q3)
     {
         float tx,ty,tz;
         if(Sxyz[0]=='1')tx=*q1;
         else if(Sxyz[0]=='2')tx=*q2;
         else tx=*q3;
         if(Sxyz[1]=='-')tx=-tx;

         if(Sxyz[3]=='1')ty=*q1;
         else if(Sxyz[3]=='2')ty=*q2;
         else ty=*q3;
         if(Sxyz[4]=='-')ty=-ty;

         if(Sxyz[6]=='1')tz=*q1;
         else if(Sxyz[6]=='2')tz=*q2;
         else tz=*q3;
         if(Sxyz[7]=='-')tz=-tz;
         *q1=tx;
         *q2=ty;
         *q3=tz;
     }
    extern float cq0, cq1, cq2, cq3;//spaceを押した時のcenter quatrnion
    extern float nq0, nq1, nq2, nq3;//現在のquaternion
    extern float mnq0, mnq1, mnq2, mnq3;//受け渡し用のquaternion

    if (Resetheadfcnt > 0) {
        cq0 = nq0; cq3 = -nq3;
    }

    nq0 = f0;
    nq1 = f1;
    nq2 = f2;
    nq3 = f3;
    MultQuat(&f0, &f1, &f2, &f3, cq0, cq1, cq2, cq3, nq0, nq1, nq2, nq3);
    QuatXchan(&f0, &f1, &f2, &f3);

    mnq0 = f0;
    mnq1 = f1;
    mnq2 = f2;
    mnq3 = f3;
    */
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
    func getCameras(){
        if AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil{
            ultrawideCamera=true
        }
        if AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) != nil{
            telephotoCamera=true
        }
    }
    /*
    iCapNYS---
     cameraType=0//front
    cameraType=1//wideAngle
    cameraType=2//telephoto
    cameraType3//ultraWide
    vHIT96da-------
    cameraType=0//wideAngle
    cameraType=1//telephoto
    cameraType=2//ultraWide--focusが効かない、広角、ズームを効かせる。
    */
    @IBAction func onCameraChangeButton(_ sender: Any) {//camera>1
        cameraType=UserDefaults.standard.integer(forKey:"cameraType")
        if cameraType==0{
            cameraType=1
        }else if cameraType==1{
            if telephotoCamera == true{
                cameraType=2//telephoto
            }else if ultrawideCamera == true{
                cameraType=3
            }else{
                cameraType=0
            }
        }else if cameraType==2{
            if ultrawideCamera==true{
                cameraType=3//ultraWide
            }else{
                cameraType=0
            }
        }else{
            cameraType=0//wideAngle
        }
        print("camera:",cameraType)
        UserDefaults.standard.set(cameraType, forKey: "cameraType")
        captureSession.stopRunning()
        set_rpk_ppk()
        initSession(fps: 60)
        onLEDValueChange()
        onZoomValueChange()
        onFocusValueChange()
        onExposeValueChange()
        setButtons()
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
 
        // プレビュー出力設定
        whiteView.layer.frame=CGRect(x:0,y:0,width:view.bounds.width,height:view.bounds.height)
        cameraView.layer.frame=CGRect(x:0,y:0,width:view.bounds.width,height:view.bounds.height)
        cameraView.layer.addSublayer(   whiteView.layer)
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if cameraType==0{
            videoLayer.frame = CGRect(x:self.view.bounds.width/3,y:0,width:self.view.bounds.width/3,height:self.view.bounds.height/3)
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
    var startButtonsHeight:CGFloat=0
    @IBAction func panGesture(_ sender: UIPanGestureRecognizer) {
        let move:CGPoint = sender.translation(in: self.view)
//        let pos = sender.location(in: self.view)
        print("panGesture")
        if recordingFlag==true{
            return
        }
        if sender.state == .began {
            startButtonsHeight=CGFloat(camera.getUserDefaultFloat(str: "buttonsHeight", ret: 0))
        } else if sender.state == .changed {
            var changedButtonHeight=startButtonsHeight - move.y
            if changedButtonHeight>view.bounds.height/5{
                changedButtonHeight=view.bounds.height/5
            }else if changedButtonHeight<0{
                changedButtonHeight = 0
            }
            UserDefaults.standard.set(changedButtonHeight,forKey: "buttonsHeight")
            setButtons()//,changedButtonHeight)
        }else if sender.state == .ended{
        }
    }
    func setButtons(){
        // recording button
        let height=CGFloat(camera.getUserDefaultFloat(str: "buttonsHeight", ret: 0))

        let leftPadding=CGFloat( UserDefaults.standard.integer(forKey:"leftPadding"))
        let rightPadding=CGFloat(UserDefaults.standard.integer(forKey:"rightPadding"))
        let topPadding=CGFloat(UserDefaults.standard.integer(forKey:"topPadding"))
        let bottomPadding=CGFloat(UserDefaults.standard.integer(forKey:"bottomPadding"))/2
        let ww:CGFloat=view.bounds.width-leftPadding-rightPadding
        let wh:CGFloat=view.bounds.height-topPadding-bottomPadding
        let sp=ww/120//間隙
        let bw=(ww-sp*10)/7//ボタン幅
        let bh=bw*170/440
        let by=wh-bh-sp-height
        let by1=wh-(bh+sp)*2-height
        let by2=wh-(bh+sp)*2.5-height
        let x0=leftPadding+sp*2
        
        previewSwitch.frame = CGRect(x:view.bounds.width*2/3+sp,y:topPadding+sp,width: bw,height: bh)
        let switchHeight=previewSwitch.frame.height
        previewLabel.frame.origin.x=previewSwitch.frame.maxX+sp
        previewLabel.frame.origin.y=(topPadding+sp+switchHeight/2)-bh/2
        previewLabel.frame.size.width=bw*5
        previewLabel.frame.size.height=bh
        camera.setLabelProperty(focusLabel,x:x0,y:by,w:bw,h:bh,UIColor.darkGray)
        focusBar.frame = CGRect(x:x0+bw+sp, y: by, width:bw*2+sp, height: bh)
        camera.setLabelProperty(lightLabel,x:x0,y:by1,w:bw,h:bh,UIColor.darkGray)
        lightBar.frame = CGRect(x:x0+bw+sp,y:by1,width:bw*2+sp,height:bh)
        camera.setLabelProperty(exposeLabel, x: x0+bw*3+sp*3, y: by1, w: bw, h: bh, UIColor.darkGray)
        camera.setLabelProperty(zoomLabel,x:x0+bw*3+sp*3,y:by,w:bw,h:bh,UIColor.darkGray)
        zoomBar.frame = CGRect(x:x0+bw*4+sp*4,y:by,width:bw*2+sp,height: bh)
        exposeBar.frame = CGRect(x:x0+bw*4+sp*4,y:by1,width:bw*2+sp,height: bh)
        isoBar.frame = CGRect(x:x0+bw*4+sp*4,y:by2,width:bw*2+sp,height: bh)
        camera.setButtonProperty(exitButton,x:x0+bw*6+sp*6,y:by,w:bw,h:bh,UIColor.darkGray)
        camera.setButtonProperty(cameraChangeButton,x:x0+bw*6+sp*6,y:by1,w:bw,h:bh,UIColor.darkGray)
        speakerSwitch.frame = CGRect(x:x0+bw*5*sp*5,y:by1,width:bw,height:bh)
//        //switchの大きさは規定されているので、作ってみてそのサイズを得て、再設定
        let switchWidth=speakerSwitch.frame.width
//        let switchHeight=speakerSwitch.frame.height
        let d=(bh-switchHeight)/2
        speakerSwitch.frame = CGRect(x:x0+bw*5+sp*5,y:by1+d,width:switchWidth,height: bh)
        speakerLabel.frame = CGRect(x:x0+bw*5+sp*4+switchWidth,y:by1,width:bw/2,height:bh)
        setProperty(label: currentTime, radius: 4)
        currentTime.font = UIFont.monospacedDigitSystemFont(ofSize: view.bounds.width/30, weight: .medium)
        currentTime.frame = CGRect(x:x0+sp*6+bw*6, y: topPadding+sp, width: bw, height: bh)
        currentTime.alpha=0.5
        quaternionView.frame=CGRect(x:leftPadding+sp*2,y:sp,width:wh/6,height:wh/6)
//        quaternionView.layer.position=CGPoint(x:ww/12+10,y:leftPadding + ww/12+10)
        startButton.frame=CGRect(x:leftPadding+ww/2-wh/4,y:sp+topPadding,width: wh/2,height: wh/2)
        stopButton.frame=CGRect(x:leftPadding+ww/2-wh/2,y:sp+topPadding,width: wh,height: wh)
        panTapExplanation.frame=CGRect(x:leftPadding,y:topPadding,width:ww,height:wh/2)
        if cameraType==0{
            previewSwitch.isHidden=false
            previewLabel.isHidden=false
        }else{
            previewSwitch.isHidden=true
            previewLabel.isHidden=true
        }
    }
  
    @IBAction func onClickStopButton(_ sender: Any) {
        recordingFlag=false
        if speakerSwitch.isOn==true{
            if let soundUrl = URL(string:
                                    "/System/Library/Audio/UISounds/begin_record.caf"){
                AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundIdx)
                AudioServicesPlaySystemSound(soundIdx)
            }
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
            stopButton.isHidden=true
            //と変更することで、Exitボタンで帰った状態にする。
        }
        motionManager.stopDeviceMotionUpdates()
        captureSession.stopRunning()
        killTimer()
        while saved2album==false{
            sleep(UInt32(0.1))
        }
        performSegue(withIdentifier: "fromRecord", sender: self)
    }
    @IBAction func onClickStartButton(_ sender: Any) {
        zoomLabel.isHidden=true
        focusLabel.isHidden=true
        focusBar.isHidden=true
        zoomBar.isHidden=true
        lightLabel.isHidden=true
        lightBar.isHidden=true
        exposeLabel.isHidden=true
        exposeBar.isHidden=true
        cameraChangeButton.isHidden=true
        panTapExplanation.isHidden=true
        //sensorをリセットし、正面に
        motionManager.stopDeviceMotionUpdates()
        recordingFlag=true
        //start recording
        startButton.isHidden=true
        stopButton.isHidden=false
        stopButton.isEnabled=true
        startButton.isEnabled=false
        currentTime.isHidden=false
        exitButton.isHidden=true
        speakerSwitch.isHidden=true
        speakerLabel.isHidden=true
        stopButton.alpha=0.02
        previewLabel.isHidden=true
        previewSwitch.isHidden=true
        if cameraType==0 && previewSwitch.isOn==false{
            quaternionView.isHidden=true
            cameraView.isHidden=true
            currentTime.alpha=0.1
        }
        try? FileManager.default.removeItem(atPath: TempFilePath)

        timerCnt=0
        UIApplication.shared.isIdleTimerDisabled = true//スリープしない
        //        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        if speakerSwitch.isOn==true{
        if let soundUrl = URL(string:
                                
                                "/System/Library/Audio/UISounds/begin_record.caf"/*photoShutter.caf*/){
            AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundIdx)
            AudioServicesPlaySystemSound(soundIdx)
        }
        }
        fileWriter!.startWriting()
        fileWriter!.startSession(atSourceTime: CMTime.zero)
//        print(fileWriter?.error)
        setMotion()
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
        if cameraType==1 || cameraType==2{

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
    }
    @objc func onFocusValueChange(){
            setFocus(focus:focusBar.value)
            UserDefaults.standard.set(focusBar.value, forKey: "focusValue")
    }
    func setFocus(focus:Float) {//focus 0:最接近　0-1.0
        if let device = videoDevice{
            if device.isFocusModeSupported(.autoFocus) && device.isFocusPointOfInterestSupported {
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
                    print("focuserror")
                }
            }else{
//                if cameraType==2{
//                    setZoom(level: focus*4/10)//vHITに比べてすでに1/4にしてあるので
//                    return
//                }
            }
        }
    }
    @IBOutlet weak var isoBar: UISlider!
    @IBOutlet weak var exposeBar: UISlider!
    
//    func setupSlider() {
//        // 露出用スライダー設定
//        brightnessSlider.minimumValue = Float(videoDevice!.minExposureTargetBias)
//        brightnessSlider.maximumValue = Float(videoDevice!.maxExposureTargetBias)
//        self.brightnessSlider.value = (brightnessSlider.minimumValue + brightnessSlider.maximumValue) / 2
//        brightnessSlider.addTarget(self, action: #selector(changeSlider), for: UIControl.Event.valueChanged)
//        self.view.addSubview(brightnessSlider)
//        brightnessSlider.tag = 1  // タグを1に設定
//        // ISO感度用スライダー設定
//        isoSlider.minimumValue = Float(videoDevice!.activeFormat.minISO)
//        isoSlider.maximumValue = Float(videoDevice!.activeFormat.maxISO)
//        self.isoSlider.value = (isoSlider.minimumValue + isoSlider.maximumValue) / 2
//        isoSlider.addTarget(self, action: #selector(changeSlider), for: UIControl.Event.valueChanged)
//        self.view.addSubview(isoSlider)
//        isoSlider.tag = 2  // タグを2に設定
//    }
    @objc func onExposeValueChange(){
        setExpose(expose:exposeBar.value)
        UserDefaults.standard.set(exposeBar.value, forKey: "exposeValue")
    }
    @objc func onIsoValueChange(){
        setIso(iso:isoBar.value)
        UserDefaults.standard.set(isoBar.value, forKey: "isoValue")
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
    func setIso(iso: Float) {
        if let currentDevice=videoDevice{
            do {
                try currentDevice.lockForConfiguration()
                defer { currentDevice.unlockForConfiguration() }
                // ISO感度を設定
                currentDevice.exposureMode = .custom
                currentDevice.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration,
                                                    iso: iso,
                                                    completionHandler: nil)
                
            } catch {
                print("\(error.localizedDescription)")
            }
        }
    }
    // MARK: - Slider Action
//    @IBAction func changeSlider(_ sender: UISlider) {
//
//        let tag: Int = sender.tag
//        if let currentDevice=videoDevice{
//            do {
//                try currentDevice.lockForConfiguration()
//                defer { currentDevice.unlockForConfiguration() }
//
//                // 露出、または ISO感度を設定
//                switch tag {
//                case 1:
//                    currentDevice.exposureMode = .autoExpose
//                    currentDevice.setExposureTargetBias(sender.value, completionHandler: nil)
//                    print("expose:",sender.value)
//                    UserDefaults.standard.set(sender.value, forKey: "cameraBrightnessValue")
//                case 2:
//                    currentDevice.exposureMode = .custom
//                    currentDevice.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration,
//                                                        iso: sender.value,
//                                                        completionHandler: nil)
//                    print("iso:",sender.value)
//                default:
//                    break
//                }
//            } catch {
//                print("\(error.localizedDescription)")
//            }
//        }
//    }
//    @IBAction func onISOChanged(_ sender: UISlider) {
//        if cameraType==0{
//            return
//        }
//        if let device = videoDevice{
//            //        let tag: Int = sender.tag
//            do {
//                try device.lockForConfiguration()
//                defer { device.unlockForConfiguration() }
//
//                //          露出を設定
////                device.exposureMode = .autoExpose
////                device.setExposureTargetBias(sender.value, completionHandler: nil)
//                //          ISO感度を設定
//                device.exposureMode = .custom
//                device.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration,
//                                             iso: sender.value,
//                                             completionHandler: nil)
////                device.unlockForConfiguration()
//
//            } catch {
//                print("\(error.localizedDescription)")
//            }
//        }
//    }
 //   let shutterSpeed = CMTimeMake(1, 400)
 //   device.setExposureModeCustom(duration: shutterSpeed, iso: 800, completionHandler: nil)
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
        
        let rotatedCIImage = frameCIImage.transformed(by: matrix)
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
        
        let quaterImage = drawHead(width: 130, height: 130, radius: 50,qOld0:qCG0, qOld1: qCG1, qOld2:qCG2,qOld3:qCG3)
        DispatchQueue.main.async {
          self.quaternionView.image = quaterImage
          self.quaternionView.setNeedsLayout()
        }
        //frameの時間計算, sampleBufferの時刻から算出
        let frameTime:CMTime = CMTimeMake(value: sampleBuffer.outputPresentationTimeStamp.value - startTimeStamp, timescale: sampleBuffer.outputPresentationTimeStamp.timescale)
        let frameUIImage = UIImage(ciImage: rotatedCIImage)
//        print(frameUIImage.size.width,frameUIImage.size.height)
        let iCapNYSH=CGFloat(iCapNYSHeight)
        let iCapNYSW=CGFloat(iCapNYSWidth)
        UIGraphicsBeginImageContext(CGSize(width: iCapNYSW, height: iCapNYSH))
        frameUIImage.draw(in: CGRect(x: 0, y: 0, width:iCapNYSW, height: iCapNYSH))
        //let r=view.bounds.height/view.bounds.width
//        let r=iCapNYSH/iCapNYSW
        quaterImage.draw(in: CGRect(x:0, y:0, width:quaterImage.size.width, height:quaterImage.size.height))
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
