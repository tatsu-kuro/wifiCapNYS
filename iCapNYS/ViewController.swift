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
    var videoArrayCount:Int = 0
    var videoDate = Array<String>()
    var videoURL = Array<URL>()
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
            let left=UserDefaults.standard.integer(forKey:"leftPadding")
            print("top,bottom,right,left,(int Left)",topPadding,bottomPadding,rightPadding,leftPadding,left)    // iPhoneXなら44, その他は20.0
        }
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

        if let vc = segue.source as? RecordViewController{
            let Controller:RecordViewController = vc
            if Controller.stopButton.isHidden==true{//Exit
                print("Exit")
           
            }
            print("segue:","\(segue.identifier!)")
            Controller.motionManager.stopDeviceMotionUpdates()
            Controller.captureSession.stopRunning()
        }
        UIScreen.main.brightness = CGFloat(UserDefaults.standard.float(forKey: "mainBrightness"))
        UIApplication.shared.isIdleTimerDisabled = false//スリープする.監視する
        print("unwi")
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
        someFunctions.setButtonProperty(changeLandscapeSideButton, x:x0+bw*6+sp*6, y: by0, w: bw, h: bh, UIColor.darkGray)
        //下ボタンを有効にするとLandscapeLeft,Rightを変更可能となる。infoに(left home button),(right home button)両方指定
        changeLandscapeSideButton.isHidden=true
        //以下2行ではRightに設定。leftに変更するときは、infoにもlandscape(left home button)を設定
        let landscapeSide=0//0:right 1:left
        UserDefaults.standard.set(landscapeSide,forKey: "landscapeSide")

        cameraButton.frame=CGRect( x: view.bounds.width-rightPadding-2*sp-wh+2*bh, y: topPadding+bh, width:wh-2*bh, height: wh-2*bh)
        tableView.frame = CGRect(x:leftPadding,y:topPadding+sp,width: view.bounds.width-rightPadding-2*sp-wh+2*bh-leftPadding,height: wh-2*sp)

        UIApplication.shared.isIdleTimerDisabled = false//スリープする
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewwillappear")
    }

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
