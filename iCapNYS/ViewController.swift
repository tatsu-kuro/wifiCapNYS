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
    let albumName:String = "iCapNYS"
    var videoArrayCount:Int = 0
    var videoDate = Array<String>()
    var videoURL = Array<URL>()
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
            }else{//recorded
                while Controller.saved2album == false{//albumに保存されるのを待つ
                    sleep(UInt32(0.1))
                }
                getAlbumList()
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
            albumExist=true
            if assets.count == 0{
                gettingAlbumF=false
                albumExist=false
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
            albumExist=false
            gettingAlbumF=false
        }
    }
//
//    func camera_alert(){
//        if PHPhotoLibrary.authorizationStatus() != .authorized {
//            PHPhotoLibrary.requestAuthorization { status in
//                if status == .authorized {
//                    // フォトライブラリに写真を保存するなど、実施したいことをここに書く
//                } else if status == .denied {
//                }
//            }
//        } else {
//            // フォトライブラリに写真を保存するなど、実施したいことをここに書く
//        }
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        how2Button.layer.borderColor = UIColor.black.cgColor
        how2Button.layer.borderWidth = 1.0
        how2Button.layer.cornerRadius = 10
        getAlbumList()
        videoArrayCount = videoURL.count
        tableView.reloadData()
        UIApplication.shared.isIdleTimerDisabled = false//スリープする
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewwillappear")
    }
    //nuber of cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if albumExist==false{
            return 0
        }else{
            return videoURL.count
        }
    }
    //set data on cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell{
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier:"cell",for :indexPath)
        let number = (indexPath.row+1).description + ") "
        cell.textLabel!.text = number + videoDate[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "playView") as! PlayViewController
        nextView.videoURL = videoURL[indexPath.row]
        self.present(nextView, animated: true, completion: nil)
    }
}
