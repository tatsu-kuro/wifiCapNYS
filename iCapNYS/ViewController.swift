//
//  ViewController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2020/09/21.
//
// landscape_new:から動けない、conflictして、解消出来ない。
//
//  ViewController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2020/09/20.
//
import UIKit
import Photos
import AssetsLibrary
import CoreMotion

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    @IBOutlet weak var steelLabel: UILabel!
    @IBOutlet weak var postualLabel: UILabel!
    @IBOutlet weak var autoRecordButton: UIButton!
    let someFunctions = myFunctions()
    let TempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
    let albumName:String = "iCapNYS"
    var videoCurrentCount:Int = 0
    var videoDate = Array<String>()
    @IBOutlet weak var how2Button: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topLabel: UILabel!
    private var videoCnt: [Int] = [] {
        didSet {
            tableView?.reloadData()
        }
    }

    //motion sensor*************************
    let motionManager = CMMotionManager()
    var isStarted = false
    var accel = Array<Int>()
    var rotatez = Array<Int>()
    var rotatex = Array<Int>()
    var tapLeft:Bool=false

    func checkTap(cnt:Int)->Bool{
        for i in 0...15{
            if rotatex[cnt+i] > 9 || rotatex[cnt+i] < -9{
                return false
            }
        }
        let a0=accel[cnt]
        let a1=accel[cnt+1]
        let a2=accel[cnt+2]
        let a3=accel[cnt+3]
        let a4=accel[cnt+4]
        let rz0=rotatez[cnt]
        let rz1=rotatez[cnt+1]
        let rz2=rotatez[cnt+2]
        let rz3=rotatez[cnt+3]
        let rz4=rotatez[cnt+4]
        if a0 > -1 && a1 > -1 && a2<1 && a3<1 && a4<1{
            if a0+a1>6 && a2+a3+a4 < -6{
                if rz0+rz1>rz2+rz3+rz4{
                    tapLeft=true
                }else{
                    tapLeft=false
                }
                return true
            }
        }
        return false
    }
    func checkTaps(_ n1:Int,_ n2:Int)->Bool{
        for i in n1...n2{
            if checkTap(cnt: i){
                return true
            }
        }
        return false
    }

    func stopMotion() {
        isStarted = false
        motionManager.stopDeviceMotionUpdates()
        if tapLeft{
            onAutoRecordButton(0)
        }else{
            onPositioningRecordButton(0)
        }
    }
    private func updateMotionData(deviceMotion:CMDeviceMotion) {
        let ax=deviceMotion.userAcceleration.x
        rotatex.append(Int(deviceMotion.rotationRate.x*50))
        rotatez.append(Int(deviceMotion.rotationRate.z*50))
        accel.append(Int(ax*50))
        if accel.count>100{

            accel.remove(at: 0)
            rotatez.remove(at: 0)
            rotatex.remove(at: 0)
            if checkTap(cnt: 0){
                print("oneTap")
                if checkTaps(30,60){
                    print("doubleTap")
                    stopMotion()
                }
            }
        }
    }
    func startMotion(){
        accel.removeAll()
        rotatez.removeAll()
        rotatex.removeAll()

        // start monitoring sensor data
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.01
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {(motion:CMDeviceMotion?, error:Error?) in
                self.updateMotionData(deviceMotion: motion!)
            })
        }
        isStarted = true
    }
    //motion sensor*****************
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("viewDidLayoutSubviews*******")

//        if #available(iOS 11.0, *) {
            // viewDidLayoutSubviewsではSafeAreaの取得ができている
            let topPadding = self.view.safeAreaInsets.top
            let bottomPadding = self.view.safeAreaInsets.bottom
            let leftPadding = self.view.safeAreaInsets.left
            let rightPadding = self.view.safeAreaInsets.right
            UserDefaults.standard.set(topPadding,forKey: "topPadding")
            UserDefaults.standard.set(bottomPadding,forKey: "bottomPadding")
            UserDefaults.standard.set(leftPadding,forKey: "leftPadding")
            UserDefaults.standard.set(rightPadding,forKey: "rightPadding")
            setButtons()
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    //これは.isHiddenとする
    @IBOutlet weak var setteiButtonAuto: UIButton!
    @IBOutlet weak var setteiButtonManual: UIButton!
    @IBOutlet weak var positioningAutoRecordButton: UIButton!
    
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
    
    @IBAction func onCameraButton(_ sender: Any) {
        let nextView = storyboard?.instantiateViewController(withIdentifier: "RECORD") as! RecordViewController
        nextView.setteiMode=0
        nextView.autoRecordMode=false
        nextView.currentBrightness=UIScreen.main.brightness
        self.present(nextView, animated: true, completion: nil)
    }
    
    @IBAction func onSetteiButtonAuto(_ sender: Any) {
        let nextView = storyboard?.instantiateViewController(withIdentifier: "RECORD") as! RecordViewController
        nextView.setteiMode=2
        nextView.autoRecordMode=false
        nextView.currentBrightness=UIScreen.main.brightness
        nextView.explanationLabeltextColor=UIColor.systemOrange
        self.present(nextView, animated: true, completion: nil)
    }
    
    @IBAction func onSetteiButtonManual(_ sender: Any) {
        let nextView = storyboard?.instantiateViewController(withIdentifier: "RECORD") as! RecordViewController
        nextView.setteiMode=1
        nextView.autoRecordMode=false
        nextView.currentBrightness=UIScreen.main.brightness
        nextView.explanationLabeltextColor=UIColor.systemGreen
        self.present(nextView, animated: true, completion: nil)
    }
    
    @IBAction func onPositioningRecordButton(_ sender: Any) {
        let nextView = storyboard?.instantiateViewController(withIdentifier: "AUTORECORD") as! AutoRecordViewController
        nextView.isPositional=true
        nextView.currentBrightness=UIScreen.main.brightness
        self.present(nextView, animated: true, completion: nil)
    }
    @IBAction func onAutoRecordButton(_ sender: Any) {
        let nextView = storyboard?.instantiateViewController(withIdentifier: "AUTORECORD") as! AutoRecordViewController
        nextView.isPositional=false
        nextView.currentBrightness=UIScreen.main.brightness
        self.present(nextView, animated: true, completion: nil)
    }
//    @IBAction func onChangeLandscapeSide(_ sender: Any) {
//        var landscapeSide=someFunctions.getUserDefaultInt(str: "landscapeSide", ret: 0)
//        if landscapeSide==0{
//            landscapeSide=1
//        }else{
//            landscapeSide=0
//        }
//        UserDefaults.standard.set(landscapeSide,forKey: "landscapeSide")
//        let nextView = storyboard?.instantiateViewController(withIdentifier: "HOW2") as! How2ViewController
//        self.present(nextView, animated: true, completion: nil)
//    }
    
    @IBAction func unwindAction(segue: UIStoryboardSegue) {
        print("segueWhat:",segue)
        if let vc = segue.source as? RecordViewController{
            let Controller:RecordViewController = vc
            if Controller.stopButton.isHidden==true{//Exit
                print("Exit / not recorded")
            }else{
                print("Exit / recorded")
                if someFunctions.videoPHAsset.count<5{
                    someFunctions.getAlbumAssets()
                    print("count<5")
                }else{
                    someFunctions.getAlbumAssets_last()
                    print("count>4")
                }
                UserDefaults.standard.set(0,forKey: "contentOffsetY")
                DispatchQueue.main.async { [self] in
                    self.tableView.contentOffset.y=0
                }
            }
//            if Controller.cameraType==0{//frontCameraの時だけ明るさを元に戻す。バックカメラの録画時では明るさを変更しない。
            UIScreen.main.brightness = Controller.currentBrightness// CGFloat(UserDefaults.standard.float(forKey:
            print("brightness/unwind:",Controller.currentBrightness, UIScreen.main.brightness)
//            }
            print("segue:","\(segue.identifier!)")
            Controller.motionManager.stopDeviceMotionUpdates()
            Controller.captureSession.stopRunning()
        }else if let vc = segue.source as? AutoRecordViewController{
            let Controller:AutoRecordViewController = vc
            Controller.killTimer()//念の為
            if (Controller.isPositional==false && Controller.movieTimerCnt>25) ||
                (Controller.isPositional==true && Controller.movieTimerCnt>112){
                print("Exit / Auto recorded")
                if someFunctions.videoPHAsset.count<5{
                    someFunctions.getAlbumAssets()
                    print("count<5")
                }else{
                    someFunctions.getAlbumAssets_last()
                    print("count>4")
                }
                UserDefaults.standard.set(0,forKey: "contentOffsetY")
                DispatchQueue.main.async { [self] in
                    self.tableView.contentOffset.y=0
                    self.tableView.reloadData()//こちらだけこれが必要なのはどうして
                }
            }
            //            if Controller.cameraType==0{//frontCameraの時だけ明るさを元に戻す。バックカメラの録画時では明るさを変更しない。
            UIScreen.main.brightness = Controller.currentBrightness
            //            }
            print("brightness/unwind:",Controller.currentBrightness, UIScreen.main.brightness)
            print("segue:","\(segue.identifier!)")
            Controller.motionManager.stopDeviceMotionUpdates()
            Controller.captureSession.stopRunning()
        }else if let vc = segue.source as? AutoRecordViewController{

        }
        UIApplication.shared.isIdleTimerDisabled = false//スリープする.監視する
        print("unwind")
        startMotion()
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
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad*******")
        startMotion()
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    self.checkLibraryAuthrizedFlag=1
                    print("authorized")
                } else if status == .denied {
                    self.checkLibraryAuthrizedFlag = -1
                    print("denied")
                }else{
                    self.checkLibraryAuthrizedFlag = -1
                }
            }
        }else{
            someFunctions.getAlbumAssets()//完了したら戻ってくるようにしたつもり
        }
        //初回起動時にdefaultを設定
        let cameraType=someFunctions.getUserDefaultInt(str: "cameraType", ret: 0)
        let topEndBlank=0//someFunctions.getUserDefaultInt(str: "topEndBlank", ret: 0)
        
        UIApplication.shared.isIdleTimerDisabled = false//スリープする
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if UIApplication.shared.isIdleTimerDisabled == true{
            UIApplication.shared.isIdleTimerDisabled = false//監視する
        }
        print("viewDidAppear*********")
        tableView.reloadData()
        let contentOffsetY = CGFloat(someFunctions.getUserDefaultFloat(str:"contentOffsetY",ret:0))
        DispatchQueue.main.async { [self] in
            self.tableView.contentOffset.y=contentOffsetY
        }
    }
    var checkLibraryAuthrizedFlag:Int=0
    func checkLibraryAuthorized(){
        //iOS14に対応
        checkLibraryAuthrizedFlag=0//0：ここの処理が終わっていないとき　1：許可　−１：拒否
        if #available(iOS 14.0, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                switch status {
                case .limited:
                    self.checkLibraryAuthrizedFlag=1
                    print("limited")
                    break
                case .authorized:
                    self.checkLibraryAuthrizedFlag=1
                    print("authorized")
                    break
                case .denied:
                    self.checkLibraryAuthrizedFlag = -1
                    print("denied")
                    break
                default:
                    self.checkLibraryAuthrizedFlag = -1
                    break
                }
            }
        }
        else  {
            if PHPhotoLibrary.authorizationStatus() != .authorized {
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        self.checkLibraryAuthrizedFlag=1
                        print("authorized")
                    } else if status == .denied {
                        self.checkLibraryAuthrizedFlag = -1
                        print("denied")
                    }
                }
            } else {
                self.checkLibraryAuthrizedFlag=1
            }
        }
    }
    func setButtons(){
        let leftPadding=CGFloat( UserDefaults.standard.integer(forKey:"leftPadding"))
        let rightPadding=CGFloat(UserDefaults.standard.integer(forKey:"rightPadding"))
        let topPadding=CGFloat(UserDefaults.standard.integer(forKey:"topPadding"))
        let bottomPadding=CGFloat(UserDefaults.standard.integer(forKey:"bottomPadding"))/2
        let ww:CGFloat=view.bounds.width-leftPadding-rightPadding
        let wh:CGFloat=view.bounds.height-topPadding-bottomPadding
        let sp=ww/120//間隙
//        let bw=(ww-sp*10)/7//ボタン幅
         let x0=leftPadding+sp*2
        let x0but=view.bounds.width-rightPadding-wh*3/4
        let x1but=x0but+wh/2-wh/40
        let bw=view.bounds.width-x1but-rightPadding-2*sp
        let bh=bw*170/440
        let by=wh-bh-sp
        let by0=topPadding+sp
        someFunctions.setButtonProperty(how2Button, x:x1but+sp/2, y: by-bh*2/3, w: bw, h: bh, UIColor.darkGray)
//        someFunctions.setButtonProperty(how2Button, x:x0+bw*6+sp*6, y: by-bh*2/3, w: bw, h: bh, UIColor.darkGray)
        someFunctions.setButtonProperty(setteiButtonAuto, x:x1but, y:by0+bh*2/3, w: bw, h: bh, UIColor.systemOrange,0)
        someFunctions.setButtonProperty(setteiButtonManual, x:x1but, y:by0+bh*5/3+sp, w:bw,h:bh,UIColor.systemGreen,0)
        autoRecordButton.frame=CGRect(x:x0but,           y:sp,width: wh/2,height: wh/2)
        positioningAutoRecordButton.frame=CGRect(x:x0but,y:wh/2-sp,width: wh/2,height: wh/2)
        let upCircleX0=sp+wh/4
        let downCircleX0=wh/2-sp+wh/4
        steelLabel.frame=CGRect(x:x0but,y:upCircleX0-wh/9-bh/2,width: wh/2,height: bh*3.5)
        postualLabel.frame=CGRect(x:x0but,y:downCircleX0-wh/9-bh/2,width: wh/2,height: bh*3.5)
       //下ボタンを有効にするとLandscapeLeft,Rightを変更可能となる。infoに(left home button),(right home button)両方指定
//        changeLandscapeSideButton.isHidden=true
        //以下2行ではRightに設定。leftに変更するときは、infoにもlandscape(left home button)を設定
        let landscapeSide=0//0:right 1:left
        UserDefaults.standard.set(landscapeSide,forKey: "landscapeSide")

        cameraButton.frame=CGRect( x: view.bounds.width-rightPadding-wh*5/13+sp, y:topPadding+wh*4/13,width:wh*5/13, height: wh*5/13)
        //高さ/20を上下に開ける
        tableView.frame = CGRect(x:leftPadding,y:topPadding+sp+wh/20,width: view.bounds.width-rightPadding-leftPadding-wh*3/4,height: wh-2*sp-wh/10)
        
        if someFunctions.firstLang().contains("ja"){
            how2Button.setTitle("使い方", for: .normal)
            setteiButtonAuto.setTitle("設定", for: .normal)
            setteiButtonManual.setTitle("設定", for: .normal)
            steelLabel.text="座って記録\n20秒"
            postualLabel.text="横になって記録\n90秒"
        }
    }
  
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear********")
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //            // 画面非表示直後の処理を書く
        //            print("画面非表示直後")
        //        UserDefaults.standard.set(0,forKey: "contentOffsetY")
        //
        let contentOffsetY = tableView.contentOffset.y
        print("offset:",contentOffsetY)
        UserDefaults.standard.set(contentOffsetY,forKey: "contentOffsetY")
    }
    //nuber of cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let topEndBlank=0//UserDefaults.standard.integer(forKey:"topEndBlank")
        if topEndBlank==0{
            return someFunctions.videoDate.count
        }else{
            return someFunctions.videoDate.count+2
        }
    }
    
    //set data on cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell{
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier:"cell",for :indexPath)
        let topEndBlank=0//UserDefaults.standard.integer(forKey:"topEndBlank")
        if topEndBlank==0{
            let number = (indexPath.row+1).description + ") "
            cell.textLabel!.text = number + someFunctions.videoDate[indexPath.row]
        }else{
            let number = (indexPath.row).description + ") "
            if indexPath.row==0 || indexPath.row==someFunctions.videoDate.count+1{
                cell.textLabel!.text = " "
            }else{
                cell.textLabel!.text = number + someFunctions.videoDate[indexPath.row-1]
            }
        }
        return cell
    }
    func requestAVAsset(asset: PHAsset)-> AVAsset? {
        guard asset.mediaType == .video else { return nil }
        let phVideoOptions = PHVideoRequestOptions()
        phVideoOptions.version = .original
        let group = DispatchGroup()
        let imageManager = PHImageManager.default()
        var avAsset: AVAsset?
        group.enter()
        imageManager.requestAVAsset(forVideo: asset, options: phVideoOptions) { (asset, _, _) in
            avAsset = asset
            group.leave()
            
        }
        group.wait()
        
        return avAsset
    }
    //play item
//    var contentOffsetY:CGFloat=0
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let topEndBlank=0//UserDefaults.standard.integer(forKey:"topEndBlank")
        var indexPathRow = indexPath.row
        if topEndBlank==1{
            if indexPath.row==0 || indexPath.row==someFunctions.videoDate.count+1{
                return
            }else{
             indexPathRow -= 1
            }
        }
//        let str=someFunctions.videoAlbumAssets[indexPath.row]?.a absoluteString
//        print(str as Any)
//        if str!.contains("temp.mp4"){
//            return
//        }
//        return
//        print("asset:",someFunctions.videoAlbumAssets[indexPath.row])
//        if someFunctions.videoURL[indexPath.row]==nil{
//            return
//        }
//        print(someFunctions.videoAlbumAssets[indexPath.row])
        videoCurrentCount=indexPathRow// indexPath.row
        print("video:",videoCurrentCount)
        let contentOffsetY = tableView.contentOffset.y
        print("offset:",contentOffsetY)
        UserDefaults.standard.set(contentOffsetY,forKey: "contentOffsetY")
        let phasset = someFunctions.videoPHAsset[indexPathRow]//indexPath.row]
        let avasset = requestAVAsset(asset: phasset)
        if avasset == nil {//なぜ？icloudから落ちてきていないのか？
            return
        }
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "playView") as! PlayViewController
      
//        nextView.videoURL = someFunctions.videoURL[indexPath.row]
        nextView.phasset = someFunctions.videoPHAsset[indexPathRow]// indexPath.row]
        nextView.avasset = avasset
        nextView.calcDate = someFunctions.videoDate[indexPathRow]
        
        self.present(nextView, animated: true, completion: nil)
        
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        print("set canMoveRowAt")
        return false
    }//not sort
    
    //セルの削除ボタンが押された時の処理
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let topEndBlank=0//UserDefaults.standard.integer(forKey:"topEndBlank")
        var indexPathRow:Int=indexPath.row
        if topEndBlank==1{
            if indexPath.row==0 || indexPath.row==someFunctions.videoDate.count+1{
                return
            }else{
                indexPathRow -= 1
            }
        }
        //削除するだけなのでindexPath_row = indexPath.rowをする必要はない。
        if editingStyle == UITableViewCell.EditingStyle.delete {
            someFunctions.eraseVideo(number: indexPathRow)
            print("erasevideo:",indexPathRow)
            while someFunctions.dialogStatus==0{
                sleep(UInt32(0.1))
            }
            if someFunctions.dialogStatus==1{
                someFunctions.videoPHAsset.remove(at: indexPathRow)
                someFunctions.videoDate.remove(at: indexPathRow)
                tableView.reloadData()
                if indexPath.row>4 && indexPath.row<someFunctions.videoDate.count{
                    tableView.reloadRows(at: [indexPath], with: .fade)
                }else if indexPath.row == someFunctions.videoDate.count && indexPath.row != 0{
                    let indexPath1 = IndexPath(row:indexPath.row-1,section:0)
                    tableView.reloadRows(at: [indexPath1], with: .fade)
                }
            }
        }
    }
   
}
