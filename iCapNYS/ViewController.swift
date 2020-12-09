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
import Photos
import AssetsLibrary

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    let TempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
    var videoAssets:PHFetchResult<PHAsset>?
    var videoArrayCount:Int = 0
    var videoDate = Array<String>()
    var videoURL = Array<URL>()
    var iCapNYSAlbum: PHAssetCollection? // アルバムをオブジェクト化
//    let ALBUMTITLE = "iCapNYS" // アルバム名
    var albumExist:Bool=false
    @IBOutlet weak var how2Button: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topLabel: UILabel!
    private var videoCnt: [Int] = [] {
        didSet {
            tableView?.reloadData()
        }
    }
    @IBAction func unwindAction(segue: UIStoryboardSegue) {
        UIApplication.shared.isIdleTimerDisabled = false//スリープする
        if let vc = segue.source as? RecordViewController{
            let Controller:RecordViewController = vc
            if Controller.stopButton.isHidden==true{//Exit
                print("Exit")
            }else{//videoが増えるのを待
                getAlbumList()
                videoURL.count
                while videoArrayCount == videoURL.count{
                    sleep(UInt32(0.1))
                    getAlbumList()
                }
                print(videoArrayCount,videoURL.count)
                print("recorded")
                tableView.reloadData()
                videoArrayCount=videoURL.count
            }
            print("segue:","\(segue.identifier!)")
            Controller.motionManager.stopDeviceMotionUpdates()
            Controller.captureSession.stopRunning()
        }
    }
    //アルバムの一覧取得
    var gettingAlbumF:Bool=true
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
        requestOptions.isNetworkAccessAllowed = false
//        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
//        requestOptions.isNetworkAccessAllowed = false //これでもicloud上のvideoを取ってしまう
        // "iCapNYS"という名前のアルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", "iCapNYS")
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: assetFetchOptions)
        
        //アルバムが存在しない事もある？
        if (assetCollections.count > 0) {
            //同じ名前のアルバムは一つしかないはずなので最初のオブジェクトを使用
            let assetCollection = assetCollections.object(at:0)
            
            // creationDate降順でアルバム内のアセットをフェッチ
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            videoAssets = assets
            albumExist=true
            for i in 0..<videoAssets!.count{
                let asset=videoAssets![i]//str += files[i] + "\n"
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let date_sub = asset.creationDate
                let date = formatter.string(from: date_sub!)
                let duration = String(format:"%.1fs",asset.duration)
                let options=PHVideoRequestOptions()
                PHImageManager.default().requestAVAsset(forVideo:asset,
                                                        options: options){ [self](asset:AVAsset?,audioMix, info:[AnyHashable:Any]?)->Void in
                    
                    if let urlAsset = asset as? AVURLAsset{//not on iCloud
                        videoURL.append(urlAsset.url)
                        print(urlAsset.url)
                        videoDate.append(date + "(" + duration + ")")
                        print(videoDate.last as Any)
                        if i == videoAssets!.count - 1{
                            gettingAlbumF=false
                        }
                    }else{//on icloud
                        if i == videoAssets!.count - 1{
                            gettingAlbumF=false
                        }
                    }
                }
            }
        }else{
            albumExist=false
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        how2Button.layer.borderColor = UIColor.green.cgColor
        how2Button.layer.borderWidth = 1.0
        how2Button.layer.cornerRadius = 10
        getAlbumList()
        videoArrayCount = videoURL.count
        tableView.reloadData()
//        cameraButton.setTitleColor(.white, for: .normal)
//        cameraButton.backgroundColor=UIColor.systemGreen
//        cameraButton.layer.cornerRadius = 30
//        cameraButton.titleLabel!.numberOfLines = 11
//        cameraButton.titleLabel!.textAlignment = NSTextAlignment.center
//        cameraButton.setTitle("［ 録画 ］\n\nLEDは光量調節が出来ます.\n\n 明るすぎる機種の場合は\n\nLEDを紙等で覆って\n\n光量を調節して下さい.\n\nKuroda ENT Clinic", for: .normal)
        UIApplication.shared.isIdleTimerDisabled = false//スリープする
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewwillappear")
//        DispatchQueue.main.async{
//            self.tableView.reloadData()
//        }
    }
 
    //nuber of cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if albumExist==false{
            return 0
        }else{
//            print("cell number:",videoURL.count)
            return videoURL.count
        }
    }
    //set data on cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell{
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier:"cell",for :indexPath)
        print("set data on cell:",indexPath.row)
        let number = (indexPath.row+1).description + ") "
        cell.textLabel!.text = number + videoDate[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "playView") as! PlayViewController
        nextView.videoURL = videoURL[indexPath.row]
//        nextView.pHAsset = videoAssets!.object(at: indexPath.row)
//        if (videoAssets?.object(at: indexPath.row).duration)! < 0.1{
//            //playViewでduration周りで、エラーが出るのでとりあえず、こうしてみた。
//            return
//        }
        self.present(nextView, animated: true, completion: nil)
    }
}
