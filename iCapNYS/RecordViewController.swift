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

class RecordViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var soundIdstart:SystemSoundID = 1117
    var soundIdstop:SystemSoundID = 1118
    var soundIdpint:SystemSoundID = 1109//1009//7
    var recordedFlag:Bool = false
    var recordingFlag:Bool = false
    let motionManager = CMMotionManager()
    
    var session: AVCaptureSession!
    var videoDevice: AVCaptureDevice?


    var fileWriter: AVAssetWriter!
    var fileWriterInput: AVAssetWriterInput!
    var fileWriterAdapter: AVAssetWriterInputPixelBufferAdaptor!
    
    let ALBUMTITLE = "iCapNYS" // アルバム名
    var iCapNYSAlbum: PHAssetCollection? // アルバムをオブジェクト化
    let TempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
    
    var Width: Int32 = 0
    var Height: Int32 = 0
    var Fps: Float64 = 0
    var frameCount: Int64 = 0
    
    var gyro = Array<Double>()
    var recStart = CFAbsoluteTimeGetCurrent()
    var counter:Int=0
    var timer:Timer?
    var quater0:Double=0
    var quater1:Double=0
    var quater2:Double=0
    var quater3:Double=0
    var readingF = false
    
    var tapF:Bool=false
    
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
    @IBOutlet weak var cameraView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        //iCapNYSアルバムがなければ作成し、iCapNYSAlbumにアルバムを代入
        createNewAlbum(albumTitle: ALBUMTITLE) { (isSuccess) in
            if isSuccess{
                print("iCapNYS_album can be made,")
            } else{
                print("iCapNYS_album can't be made.")
            }
        }
        
        camera_alert()
        set_rpk_ppk()
        setMotion()
        // Do any additional setup after loading the view.
        timer = Timer.scheduledTimer(timeInterval: 1/60, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)

//        self.view.backgroundColor = .black
        initSession(fps: 60)//遅ければ30fpsにせざるを得ないかも
        setButtons(type: true)
        startButton.isHidden=true
        stopButton.isHidden=true
        currentTime.isHidden=true
        let str=getFilesindoc()
        print(str)
        
        
        // Do any additional setup after loading the view.
    }
    
    @objc func update(tm: Timer) {
        //        print(nq0,nq1,nq2,nq3 as Any)
//        print("update**")
        readingF=true
        let qCG0=CGFloat(quater0)
        let qCG1=CGFloat(quater1)
        let qCG2=CGFloat(quater2)
        let qCG3=CGFloat(quater3)
        readingF=false
        let quaterImage = drawHead(width: 80, height: 80, qOld0:qCG0, qOld1: qCG1, qOld2:qCG2,qOld3:qCG3)
        setImage(newImage: quaterImage)
        if recordingFlag==true{
//            var cnt60:Int?
            counter += 1
            let cnt60=counter/60
            currentTime.text=String(format:"%02d",cnt60/60) + ":" + String(format: "%02d",cnt60%60)
            if cnt60%2==0{
                stopButton.tintColor=UIColor.orange
            }else{
                stopButton.tintColor=UIColor.red
            }
        }
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
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)

        let drawPath = UIBezierPath(arcCenter: CGPoint(x: 40, y:40), radius: 39, startAngle: 0, endAngle: CGFloat(Double.pi)*2, clockwise: true)
        // 内側の色
//        UIColor(red: 1, green: 1, blue:1, alpha: 0.8).setFill()
        UIColor.white.setFill()// (red: 1, green: 1, blue:1, alpha: 0.8).setFill()

//        // 内側を塗りつぶす
        drawPath.fill()

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
    
    func switchFormat(desiredFps: Double)->Bool {
        print("switchFormat")
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
                    Width = dimensions.width
                    Height = dimensions.height
                    Fps = range.maxFrameRate
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

//    PHAssetChangeRequest *createAlbumRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:@"New Album"];
//    PHObjectPlaceholder *albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection;
//    PHCollectionListChangeRequest *folderChangeRequest =
//        [PHCollectionListChangeRequest changeRequestForCollectionList:folder];
//    [folderChangeRequest addChildCollections:@[ albumPlaceholder ]];
    
//    PHPhotoLibrary.shared().performChanges({
//        PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
//    }, completionHandler: { success, error in
//        if !success { print("Error creating album: \(String(describing: error)).") }
//    })
    
    
    func createNewAlbum(albumTitle: String, callback: @escaping (Bool) -> Void) {
        if self.albumExists(albumTitle: albumTitle) {
            callback(true)
        } else {
            
            //TempFilePath = "\(NSTemporaryDirectory())temp.mp4"
            print (TempFilePath)
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumTitle)
            }) { (isSuccess, error) in
                callback(isSuccess)
            }
        }
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
    
    
    func initSession(fps:Int) {
        // セッション生成
        session = AVCaptureSession()
        // カメラ入力 : 背面カメラ
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)
        session.addInput(videoInput)
        
        if switchFormat(desiredFps: 60)==false{
            print("error******")
        }

        // プレビュー出力設定
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill//無くても同じ
        //self.view.layer.addSublayer(videoLayer)
        cameraView.layer.addSublayer(videoLayer)
        // zooming slider
        // セッションを開始する (録画開始とは別)
        
        //        let imageOutput: AVCapturePhotoOutput = AVCapturePhotoOutput()
        //         session.addOutput(imageOutput)
        
        // VideoDataOutputにする
        let videoDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA] as [String : Any]
        //         videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_32BGRA]
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        //         videoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        session.addOutput(videoDataOutput)
        session.startRunning()
        
        //ファイル出力設定　writer使用
        //一時ファイルに記録し、書き込み終了後にアルバムに追加する。
        let TempFilePath = "\(NSTemporaryDirectory())temp.mp4"
        print ("TempFilePATH",TempFilePath)

        //一時ファイルはこの時点で必ず消去
        try? FileManager.default.removeItem(atPath: TempFilePath)
        let fileURL = NSURL(fileURLWithPath: TempFilePath)
        setMotion()//作動中ならそのまま戻る
        fileWriter = try? AVAssetWriter(outputURL: fileURL as URL, fileType: AVFileType.mov)
        
        let videoOutputSettings: Dictionary<String, AnyObject> = [
            AVVideoCodecKey: AVVideoCodecType.h264 as AnyObject,
            AVVideoHeightKey: Height as AnyObject,
            AVVideoWidthKey: Width as AnyObject
        ]
        fileWriterInput = AVAssetWriterInput(mediaType:AVMediaType.video, outputSettings: videoOutputSettings)
        fileWriterInput.expectsMediaDataInRealTime = true
        fileWriter.add(fileWriterInput)
        
        fileWriterAdapter = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: fileWriterInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String:Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferHeightKey as String: Height,
                kCVPixelBufferWidthKey as String: Width
            ]
        )

    }

    func getFilesindoc()->String{
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let contentUrls = try FileManager.default.contentsOfDirectory(at: documentDirectoryURL, includingPropertiesForKeys: nil)
            let files = contentUrls.map{$0.lastPathComponent}
            var str:String=""
            if files.count==0{
                return("")
            }
            for i in 0..<files.count{
                str += files[i] + ","
            }
            let str2=str.dropLast()
//            print("before",str)
//            print("after",str2)
            return String(str2)
        } catch {
            return ""
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        setButtons(type: true)
    }

    @IBOutlet weak var topLabel: UILabel!
    func setButtons(type:Bool){
        // recording button
        let topX=topLabel.frame.maxY
        let ww:CGFloat=view.bounds.width
        let wh:CGFloat=view.bounds.height//dammyBottom.frame.maxY// view.bounds.height
        let bw=ww*3/5

        let bh=bw//:Int=60
        currentTime.frame = CGRect(x:0,y: 0 ,width:ww/5, height: ww/10)
        currentTime.layer.position=CGPoint(x:ww-bw*11/60,y:wh-bh*4/5)
        currentTime.layer.masksToBounds = true
        currentTime.layer.cornerRadius = 10

        //startButton
        startButton.frame=CGRect(x:0,y:0,width:bw,height:bw)
        startButton.layer.position = CGPoint(x:ww/2,y:wh-bh*4/5)
        stopButton.frame=CGRect(x:0,y:0,width:bw,height:bw)
        stopButton.layer.position = CGPoint(x:ww/2,y:wh-bh*4/5)
        exitButton.frame=CGRect(x:0,y:0,width:bw/3,height:bh/5)
        exitButton.layer.position = CGPoint(x:ww-bw*11/60,y:wh-bh*4/5)
        exitButton.layer.borderColor = UIColor.green.cgColor
        exitButton.layer.borderWidth = 1.0

        exitButton.layer.cornerRadius = 10
        

        startButton.isHidden=false
        stopButton.isHidden=true
        stopButton.tintColor=UIColor.orange
        
        quaternionView.frame=CGRect(x:0,y:0,width:ww/6,height:ww/6)
        quaternionView.layer.position=CGPoint(x:ww/12+10,y:topX + ww/12+10)

    }

    @IBAction func onClickStopButton(_ sender: Any) {
        onClickStartButton(0)
    }
    
    
    @IBAction func onClickStartButton(_ sender: Any) {
        if fileWriter!.status == .writing {
            // stop recording
            recordingFlag=false
            print("ストップボタンを押した。")
            fileWriter!.finishWriting {
                print("trying to finish")
                return
            }
            while fileWriter!.status == .writing {
                usleep(1)
            }
            print("done!!")
            
            
            startButton.isHidden=false
            stopButton.isHidden=true
            currentTime.isHidden=true
            
            if FileManager.default.fileExists(atPath: TempFilePath){
                print("tempFileExists")
            }
            let fileURL = URL(fileURLWithPath: TempFilePath)
            
            PHPhotoLibrary.shared().performChanges({
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)!
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: (self.iCapNYSAlbum)!)
                let placeHolder = assetRequest.placeholderForCreatedAsset
                albumChangeRequest?.addAssets([placeHolder!] as NSArray)
                //imageID = assetRequest.placeholderForCreatedAsset?.localIdentifier
                print("file add to album")
            }) { (isSuccess, error) in
                if isSuccess {
                    // 保存した画像にアクセスする為のimageIDを返却
                    //completionBlock(imageID)
                    print("success")
                } else {
                    //failureBlock(error)
                    print("fail")
                    print(error)
                }
                _ = try? FileManager.default.removeItem(atPath: self.TempFilePath)
            }
            
        } else {
            recordedFlag=false
            recordingFlag=true
            //start recording
            startButton.isHidden=true
            stopButton.isHidden=false
            currentTime.isHidden=false
            counter=0
            
            exitButton.isHidden=true
            //            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
            UIApplication.shared.isIdleTimerDisabled = true//スリープしない
            if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil){
                AudioServicesCreateSystemSoundID(soundUrl, &soundIdstart)
                AudioServicesPlaySystemSound(soundIdstart)
            }
            frameCount = 0
            fileWriter!.startWriting()
            fileWriter!.startSession(atSourceTime: CMTime.zero)
            print(fileWriter?.error)
        }
    }

    
    
    @IBAction func tapGest(_ sender: UITapGestureRecognizer) {
    
  
        let screenSize=cameraView.bounds.size
        let x0 = sender.location(in: self.view).x
        let y0 = sender.location(in: self.view).y
        print("tap:",x0,y0,screenSize.height)
        
        if y0>screenSize.height*5/6{
            return
        }
        //ここでリセットしてz軸を正面とする。
        motionManager.stopDeviceMotionUpdates()
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
        setMotion()
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

    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            //フレームが取得できなかった場合にすぐ返る
            print("unable to get image from sample buffer")
            return
        }

        //frameの時間計算、フレーム番号とFPSが必要、フレーム番号*1sec/FPSしてくれる。
        let frameTime:CMTime = CMTimeMake(value: frameCount, timescale: Int32(Fps))
        
        if (recordingFlag == true && fileWriter!.status == .writing) {
            if fileWriterInput?.isReadyForMoreMediaData != nil{
                fileWriterAdapter.append(frame, withPresentationTime: frameTime)
            }
        } else {
            //print("not writing")
        }
        frameCount = frameCount + 1
        readingF=true
        let qCG0=CGFloat(quater0)
        let qCG1=CGFloat(quater1)
        let qCG2=CGFloat(quater2)
        let qCG3=CGFloat(quater3)
        readingF=false
        let quaterImage = drawHead(width: 80, height: 80, qOld0:qCG0, qOld1: qCG1, qOld2:qCG2,qOld3:qCG3)
        setImage(newImage: quaterImage)
        // ここに処理を書くと良いと書いてあるが、まだここに飛んでこない
    }

}
