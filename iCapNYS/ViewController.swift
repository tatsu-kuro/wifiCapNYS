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
//    let album = AlbumController()
    let TempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
    let albumName:String = "iCapNYS"
    var videoArrayCount:Int = 0
    var videoDate = Array<String>()
    var videoURL = Array<URL>()
//    var albumExist:Bool=false
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
        if #available(iOS 11.0, *) {
            // viewDidLayoutSubviewsではSafeAreaの取得ができている
            let topPadding = self.view.safeAreaInsets.top
            let bottomPadding = self.view.safeAreaInsets.bottom
            let leftPadding = self.view.safeAreaInsets.left
            let rightPadding = self.view.safeAreaInsets.right
            UserDefaults.standard.set(topPadding,forKey: "topPadding")
            UserDefaults.standard.set(bottomPadding,forKey: "bottomPadding")
            UserDefaults.standard.set(leftPadding,forKey: "leftPadding")
            UserDefaults.standard.set(rightPadding,forKey: "rightPadding")
//            print("in viewDidLayoutSubviews")
            let left=UserDefaults.standard.integer(forKey:"leftPadding")
            print("top,bottom,right,left,(int Left)",topPadding,bottomPadding,rightPadding,leftPadding,left)    // iPhoneXなら44, その他は20.0
        }
//        setButtons()
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    //これは.isHiddenとする
    @IBOutlet weak var changeLandscapeSideButton: UIButton!
    
    
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
    
    @IBAction func onChangeLandscapeSide(_ sender: Any) {
        var landscapeSide=someFunctions.getUserDefaultInt(str: "landscapeSide", ret: 0)
        if landscapeSide==0{
            landscapeSide=1
        }else{
            landscapeSide=0
        }
        UserDefaults.standard.set(landscapeSide,forKey: "landscapeSide")
        let nextView = storyboard?.instantiateViewController(withIdentifier: "HOW2") as! How2ViewController
        nextView.helpNum=999
        self.present(nextView, animated: true, completion: nil)
    }
    
    @IBAction func unwindAction(segue: UIStoryboardSegue) {
        //        camera.getAlbumList()
        //        tableView.reloadData()
        //        videoArrayCount=ca.videoURL.count
        if let vc = segue.source as? RecordViewController{
            let Controller:RecordViewController = vc
            if Controller.stopButton.isHidden==true{//Exit
                print("Exit")
                //            }else{//recorded
                //                while Controller.saved2album == false{//albumに保存されるのを待つ
                //                    sleep(UInt32(0.1))
                //                }
                //                getAlbumList()
                //                print("recorded")
                //                tableView.reloadData()
                //                videoArrayCount=videoURL.count
            }
            print("segue:","\(segue.identifier!)")
            Controller.motionManager.stopDeviceMotionUpdates()
            Controller.captureSession.stopRunning()
        }
        UIScreen.main.brightness = CGFloat(UserDefaults.standard.float(forKey: "mainBrightness"))
        UIApplication.shared.isIdleTimerDisabled = false//スリープする.監視する
        print("unwi")
    }
    //アルバムの一覧取得
 /*   var gettingAlbumF:Bool=true
    func getAlbumList(){//最後のvideoを取得するまで待つ
        gettingAlbumF = true
        getAlbumList_sub()
        while gettingAlbumF == true{
            sleep(UInt32(0.1))
        }
    }
    func getAlbumList_sub(){
        //     let imgManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        videoURL.removeAll()
        videoDate.removeAll()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = false//これでもicloud上のvideoを取ってしまう
        requestOptions.deliveryMode = .highQualityFormat
        // アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", albumName)
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: assetFetchOptions)
        
        //アルバムが存在しない事もある？
        if (assetCollections.count > 0) {
            //同じ名前のアルバムは一つしかないはずなので最初のオブジェクトを使用
            let assetCollection = assetCollections.object(at:0)
            // creationDate降順でアルバム内のアセットをフェッチ
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
//            albumExist=true
            if assets.count == 0{
                gettingAlbumF=false
//                albumExist=false
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            for i in 0..<assets.count{
                let asset=assets[i]                
                let date_sub = asset.creationDate
                let date = formatter.string(from: date_sub!)
                let duration = String(format:"%.1fs",asset.duration)
                let options=PHVideoRequestOptions()
                options.version = .original
                PHImageManager.default().requestAVAsset(forVideo:asset,
                                                        options: options){ [self](asset:AVAsset?,audioMix, info:[AnyHashable:Any]?)->Void in
                    
                    if let urlAsset = asset as? AVURLAsset{//not on iCloud
                        videoURL.append(urlAsset.url)
                        videoDate.append(date + "(" + duration + ")")
                        if i == assets.count - 1{
                            gettingAlbumF=false
                        }
                    }else{//on icloud
                        if i == assets.count - 1{
                            gettingAlbumF=false
                        }
                    }
                }
            }
        }else{
//            albumExist=false
            gettingAlbumF=false
        }
    }
*/
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
    override func viewDidAppear(_ animated: Bool) {
        if UIApplication.shared.isIdleTimerDisabled == true{
            UIApplication.shared.isIdleTimerDisabled = false//監視する
        }
        print("didappear")
        someFunctions.getAlbumAssets()
//        let landscapeSide=0//landscapeRight
//        UserDefaults.standard.set(landscapeSide,forKey: "landscapeSide")
        for i in 0..<someFunctions.videoURL.count{//cloud のURL->nilを入れる
            someFunctions.videoURL[i] = someFunctions.getURLfromPHAsset(asset: someFunctions.videoAlbumAssets[i])
            let str = someFunctions.videoURL[i]?.absoluteString
            if str!.contains("temp.mp4"){
                someFunctions.videoURL[i] = nil
           }
        }
        for i in (0..<someFunctions.videoURL.count).reversed(){//cloud(nil) のものは削除する
            if someFunctions.videoURL[i] == nil{
                someFunctions.videoURL.remove(at: i)
                someFunctions.videoDate.remove(at: i)
                someFunctions.videoAlbumAssets.remove(at: i)
            }
        }
        videoArrayCount=someFunctions.videoURL.count
        print(videoArrayCount,someFunctions.videoURL.count,someFunctions.videoDate.count)
        tableView.reloadData()
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        let mainBrightness = UIScreen.main.brightness
        UserDefaults.standard.set(mainBrightness, forKey: "mainBrightness")

//        how2Button.layer.borderColor = UIColor.black.cgColor
//        how2Button.layer.borderWidth = 1.0
//        how2Button.layer.cornerRadius = 10
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
//        let by1=wh-(bh+sp)*2
        let x0=leftPadding+sp*2
        
        someFunctions.setButtonProperty(how2Button, x:x0+bw*6+sp*6, y: by, w: bw, h: bh, UIColor.darkGray)
        someFunctions.setButtonProperty(changeLandscapeSideButton, x:x0+bw*6+sp*6, y: by0, w: bw, h: bh, UIColor.darkGray)
        //下ボタンを有効にするとLandscapeLeft,Rightを変更可能となる。
        changeLandscapeSideButton.isHidden=true
        //以下2行ではRightに設定。leftに変更するときは、infoにもlandscape(left home button)を設定
        let landscapeSide=0//0:right 1:left
        UserDefaults.standard.set(landscapeSide,forKey: "landscapeSide")

        cameraButton.frame=CGRect( x: view.bounds.width-rightPadding-2*sp-wh+2*bh, y: topPadding+bh, width:wh-2*bh, height: wh-2*bh)
        tableView.frame = CGRect(x:leftPadding,y:topPadding+sp,width: view.bounds.width-rightPadding-2*sp-wh+2*bh-leftPadding,height: wh-2*sp)
//        camera.setLabelProperty(focusLabel,x:x0,y:by,w:bw,h:bh,UIColor.darkGray)
//        focusBar.frame = CGRect(x:x0+bw+sp, y: by, width:bw*2+sp, height: bh)
//        camera.setLabelProperty(lightLabel,x:x0,y:by1,w:bw,h:bh,UIColor.darkGray)
//        lightBar.frame = CGRect(x:x0+bw+sp,y:by1,width:bw*2+sp,height:bh)
//
//        camera.setLabelProperty(zoomLabel,x:x0+bw*3+sp*3,y:by,w:bw,h:bh,UIColor.darkGray)
//        zoomBar.frame = CGRect(x:x0+bw*4+sp*4,y:by,width:bw*2+sp,height: bh)
//        camera.setButtonProperty(exitButton,x:x0+bw*6+sp*6,y:by,w:bw,h:bh,UIColor.darkGray)
//        camera.setButtonProperty(cameraChangeButton,x:x0+bw*6+sp*6,y:by1,w:bw,h:bh,UIColor.darkGray)
////        speakerSwitch.frame = CGRect(x:x0+bw*4+sp*4,y:y1,width:bw,height:bh)
//        speakerSwitch.frame = CGRect(x:x0+bw*4*sp*4,y:by1,width:bw,height:bh)
////        //switchの大きさは規定されているので、作ってみてそのサイズを得て、再設定
//        let switchWidth=speakerSwitch.frame.width
//        let switchHeight=speakerSwitch.frame.height
//        let d=(bh-switchHeight)/2
//        speakerSwitch.frame = CGRect(x:x0+bw*4+sp*4,y:by1+d,width:switchWidth,height: bh)
//        speakerLabel.frame = CGRect(x:x0+bw*4+sp*4+switchWidth,y:by1,width:bw/2,height:bh)
//        setProperty(label: currentTime, radius: 2)
//        currentTime.font = UIFont.monospacedDigitSystemFont(ofSize: view.bounds.width/20, weight: .medium)
//        currentTime.frame = CGRect(x:x0+sp*6+bw*6, y: sp, width: bw, height: bh)
//

//        let album = AlbumController()
//        album.getAlbumList()
//        getAlbumList()
//        videoArrayCount = album.videoURL.count
//        tableView.reloadData()
        UIApplication.shared.isIdleTimerDisabled = false//スリープする
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewwillappear")
    }
 /*   //nuber of cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if album.albumExist==false{
            return 0
        }else{
//            let album = AlbumController()
            return album.videoURL.count
        }
    }
    //set data on cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell{
        album.getAlbumList()

        videoArrayCount=album.videoURL.count
        
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier:"cell",for :indexPath)
        let number = (indexPath.row+1).description + ") "
        cell.textLabel!.text = number + album.videoDate[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "playView") as! PlayViewController
        nextView.videoURL = album.videoURL[indexPath.row]
        self.present(nextView, animated: true, completion: nil)
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }//not sort
    
    //セルの削除ボタンが押された時の処理
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //削除するだけなのでindexPath_row = indexPath.rowをする必要はない。
        if editingStyle == UITableViewCell.EditingStyle.delete {
            album.eraseVideo(number: indexPath.row)
            while album.dialogStatus==0{
                sleep(UInt32(0.1))
            }
            if album.dialogStatus==1{
                album.videoURL.remove(at: indexPath.row)
                album.videoDate.remove(at: indexPath.row)
                tableView.reloadData()
            }
        }
    }*/
    //nuber of cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return someFunctions.videoURL.count
    }
    
    //set data on cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell{
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier:"cell",for :indexPath)
        let number = (indexPath.row+1).description + ") "
        cell.textLabel!.text = number + someFunctions.videoDate[indexPath.row]
        return cell
    }
    //play item
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "playView") as! PlayViewController
        nextView.videoURL = someFunctions.videoURL[indexPath.row]
        nextView.calcDate = someFunctions.videoDate[indexPath.row]
        self.present(nextView, animated: true, completion: nil)
        
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        print("set canMoveRowAt")
        return false
    }//not sort
    
    //セルの削除ボタンが押された時の処理
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        //削除するだけなのでindexPath_row = indexPath.rowをする必要はない。
        if editingStyle == UITableViewCell.EditingStyle.delete {
            someFunctions.eraseVideo(number: indexPath.row)
            while someFunctions.dialogStatus==0{
                sleep(UInt32(0.1))
            }
            if someFunctions.dialogStatus==1{
                someFunctions.videoURL.remove(at: indexPath.row)
                someFunctions.videoDate.remove(at: indexPath.row)
                tableView.reloadData()
                if indexPath.row>4 && indexPath.row<someFunctions.videoURL.count{
                    tableView.reloadRows(at: [indexPath], with: .fade)
                }else if indexPath.row == someFunctions.videoURL.count && indexPath.row != 0{
                    let indexPath1 = IndexPath(row:indexPath.row-1,section:0)
                    tableView.reloadRows(at: [indexPath1], with: .fade)
                }
            }
        }
    }
}
