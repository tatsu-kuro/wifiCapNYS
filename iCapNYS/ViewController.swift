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
    let TODO = ["abd","cddd","nanda"]
    var videoDate = Array<String>()
    @IBOutlet weak var how2Button: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBAction func unwindAction(segue: UIStoryboardSegue) {
        if segue.identifier=="fromRecord"{
            //            print("同じ")
        }
//        setPlayButtonEnable()//tempFilePathがあれば有効化
        UIApplication.shared.isIdleTimerDisabled = false//スリープする
        if let vc = segue.source as? RecordViewController{
            let Controller:RecordViewController = vc
            print("segue:","\(segue.identifier!)")
            Controller.motionManager.stopDeviceMotionUpdates()
            Controller.captureSession.stopRunning()
        }
    }
    //アルバムの一覧表示
    func getAlbumList(){
   //     let imgManager = PHImageManager.default()
        videoDate.removeAll()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // アルバムをフェッチ
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: nil)//<- Error returned frm daemon:
        
        assetCollections.enumerateObjects { assetCollection, _, _ in
            
            // アルバムタイトル
//            print(assetCollection.localizedTitle ?? "")
            
            // アセットをフェッチ
            let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            var cnt:Int=0
            assets.enumerateObjects { [self] asset, _, _ in
               
                
                if assetCollection.localizedTitle == "iCapNYS"{
                    cnt += 1
                    //print(asset.creationDate as Any,cnt)
                    let str = asset.creationDate!.description//2020-11-24 09:29:43 +0000
                    let str1 = str.components(separatedBy: " +")
                    let str2 = cnt.description + ") " + str1[0]
                    videoDate.append(str2)//asset.creationDate!.description)
                    print(str2)
                }
                // 画像のリクエスト
                //                imgManager.requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode:
                //                                            .aspectFill, options: requestOptions, resultHandler: { img, _ in
                //                                                if let img = img {
                //                                                    print("画像の取得に成功",cnt)
                //                                                    cnt += 1
                //                                                }
                //                                            })
            }
        }
    }
    //     if assetCollection.localizedTitle == "アルバム１"{
    //     imageArray.append(img)

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
//    func setPlayButtonEnable(){
//        let checkValidation = FileManager.default
//        if (checkValidation.fileExists(atPath: TempFilePath)){
//            playButton.setTitle("［ 再生 ］\n\n最新映像を再生します.\n\n眼振録画映像は\n\niCapNYSアルバムに\n\n保存されます.", for: .normal)
//            print("ファイルあり、FILE AVAILABLE");
//            playButton.isEnabled=true
//        }else{
//            playButton.setTitle("［ 再生 ］\n\nまだ映像がありません！\n\n眼振録画映像は\n\niCapNYSアルバムに\n\n保存されます.", for: .normal)
//            print("ファイル無し、FILE NOT AVAILABLE");
//            playButton.isEnabled=false
//        }
//    }
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.view.backgroundColor = UIColor.white// .cyanColor()
        camera_alert()
        let vw=view.bounds.width
        let bw=vw/4
        how2Button.frame=CGRect(x:0,y:0,width:bw,height:bw/2)
        how2Button.layer.position = CGPoint(x:vw-bw/2-10,y:bw/2+20)
        how2Button.layer.borderColor = UIColor.green.cgColor
        how2Button.layer.backgroundColor = UIColor.gray.cgColor
        how2Button.layer.borderWidth = 1.0
        how2Button.layer.cornerRadius = 10
        
        
        getAlbumList()
        how2Button.layer.cornerRadius=10
        cameraButton.setTitleColor(.white, for: .normal)
        cameraButton.backgroundColor=UIColor.systemGreen
        cameraButton.layer.cornerRadius = 30
        cameraButton.titleLabel!.numberOfLines = 11
        cameraButton.titleLabel!.textAlignment = NSTextAlignment.center
        cameraButton.setTitle("［ 録画 ］\n\nLEDは光量調節が出来ます.\n\n 明るすぎる機種の場合は\n\nLEDを紙等で覆って\n\n光量を調節して下さい.\n\nKuroda ENT Clinic", for: .normal)
        
//        playButton.setTitleColor(.white, for: .normal)
//        playButton.backgroundColor=UIColor.systemGreen
//        playButton.layer.cornerRadius = 30
//        playButton.titleLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
//        playButton.titleLabel!.numberOfLines = 9
//        playButton.titleLabel!.textAlignment = NSTextAlignment.center
//        setPlayButtonEnable()
        UIApplication.shared.isIdleTimerDisabled = false//スリープする
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewwillappear")
    }
    //    override func viewDidAppear(_ animated: Bool) {
    //    }
 
    //nuber of cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//最初に一回通る        print("collection -> int")
        return videoDate.count
    }
    //set data on cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell{
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier:"cell",for :indexPath)
        cell.textLabel!.text = videoDate[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(videoDate[indexPath.row])
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "playView") as! PlayViewController
        self.present(nextView, animated: true, completion: nil)
       }
}
