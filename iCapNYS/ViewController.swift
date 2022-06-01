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

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
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
    @IBOutlet weak var setteiButton: UIButton!
    
    @IBOutlet weak var setteiButton2: UIButton!
    
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
    @IBAction func onSetteiButton(_ sender: Any) {
        let nextView = storyboard?.instantiateViewController(withIdentifier: "RECORD") as! RecordViewController
        nextView.setteiMode=true
        self.present(nextView, animated: true, completion: nil)
    }
    
    @IBAction func onSetteiButton2(_ sender: Any) {
        onSetteiButton(0)
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
            UIScreen.main.brightness = CGFloat(UserDefaults.standard.float(forKey: "mainBrightness"))
            print("segue:","\(segue.identifier!)")
            Controller.motionManager.stopDeviceMotionUpdates()
            Controller.captureSession.stopRunning()
        }
        UIApplication.shared.isIdleTimerDisabled = false//スリープする.監視する
        print("unwind")
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
        let bw=(ww-sp*10)/7//ボタン幅
        let bh=bw*170/440
        let by=wh-bh-sp
        let by0=topPadding+sp
        let x0=leftPadding+sp*2
        
        someFunctions.setButtonProperty(how2Button, x:x0+bw*6+sp*6, y: by, w: bw, h: bh, UIColor.darkGray)
        someFunctions.setButtonProperty(setteiButton, x:x0+bw*6+sp*6, y: by0, w: bw, h: bh, UIColor.darkGray)
        setteiButton2.frame=CGRect(x:x0+bw*6+sp*6, y: 0, width: bw, height: bh*3)
        //下ボタンを有効にするとLandscapeLeft,Rightを変更可能となる。infoに(left home button),(right home button)両方指定
//        changeLandscapeSideButton.isHidden=true
        //以下2行ではRightに設定。leftに変更するときは、infoにもlandscape(left home button)を設定
        let landscapeSide=0//0:right 1:left
        UserDefaults.standard.set(landscapeSide,forKey: "landscapeSide")

        cameraButton.frame=CGRect( x: view.bounds.width-rightPadding-wh*3/4, y: topPadding+wh/8, width:wh*3/4, height: wh*3/4)
        //高さ/20を上下に開ける
        tableView.frame = CGRect(x:leftPadding,y:topPadding+sp+wh/20,width: view.bounds.width-rightPadding-leftPadding-wh*3/4,height: wh-2*sp-wh/10)
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
