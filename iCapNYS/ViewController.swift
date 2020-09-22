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
import AVFoundation
import GLKit
import Photos
import CoreMotion
import AssetsLibrary
//import MessageUI



class ViewController: UIViewController{
//import UIKit
//import CoreMotion
//class ViewController: UIViewController {
    var soundIdstart:SystemSoundID = 1117
    var soundIdstop:SystemSoundID = 1118
    var soundIdpint:SystemSoundID = 1109//1009//7
    var recordedFlag:Bool = false
    var recordingFlag:Bool = false
    let motionManager = CMMotionManager()
    var session: AVCaptureSession!
    var videoDevice: AVCaptureDevice?
    var filePath:String?
    var fileOutput = AVCaptureMovieFileOutput()
    var gyro = Array<Double>()
    var recStart = CFAbsoluteTimeGetCurrent()
    var counter:Int=0
    var timer:Timer?
    var quater0:Double=0
    var quater1:Double=0
    var quater2:Double=0
    var quater3:Double=0
    var readingF=false
    @IBOutlet weak var cameraView: UIImageView!
    
    @IBOutlet weak var currentTime: UILabel!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var stopButton: UIButton!
  
    
    @IBOutlet weak var startButton: UIButton!
   
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
            print("\(segue.identifier!)")
        }
/*    func savePhoto() {
        let albumTitle = "iCapNYS" // アルバム名
        let savingImage = UIImage(named: "a.png")! // 保存するイメージ
        var theAlbum: PHAssetCollection? // アルバムをオブジェクト化
        // フォトライブラリからMyAlbumを検索
        let result = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.any, options: nil)
        result.enumerateObjects({(object, index, stop) in
            if let theCollection = object as? PHAssetCollection,
            theCollection.localizedTitle == albumTitle
            {
                theAlbum = theCollection // 見つかったら、theAlbumに代入
            }
        })
        // アルバムにイメージを保存する
        if let anAlbum = theAlbum {
            PHPhotoLibrary.shared().performChanges({
                let createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: savingImage)
                let assetPlaceholder = createAssetRequest.placeholderForCreatedAsset!
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: anAlbum)
                albumChangeRequest!.addAssets([assetPlaceholder] as NSFastEnumeration)
            }, completionHandler: nil)
        } else {
            print("MyAlbum was not found.")
        }
    }*/
   

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

        camera_alert()

        let str=getFilesindoc()
        print(str)
    }
 

    override func viewDidAppear(_ animated: Bool) {
        setButtons(type: true)
    }
    @IBOutlet weak var dammyBottom: UILabel!
    func setButtons(type:Bool){
        let ww:CGFloat=view.bounds.width
        let wh:CGFloat=dammyBottom.frame.maxY// view.bounds.height
        let bw=(ww-20)/4
        let bh=bw//:Int=60
        currentTime.frame = CGRect(x:0,y: 0 ,width:ww/3, height: bh/2)
        currentTime.layer.position=CGPoint(x:ww/2,y:wh-bh*2-bh/4)
        currentTime.layer.masksToBounds = true
        currentTime.layer.cornerRadius = 5

        //startButton
        startButton.frame=CGRect(x:0,y:0,width:bw*2,height:bw*2)
        startButton.layer.position = CGPoint(x:ww/2,y:wh-bh)
        playButton.frame=CGRect(x:0,y:0,width:bw,height:bh*2/3)
        playButton.layer.position = CGPoint(x:ww-bw/2-10,y:wh-bh/2)
        playButton.layer.borderColor = UIColor.green.cgColor
        playButton.layer.borderWidth = 1.0
        playButton.layer.cornerRadius = 5
        startButton.isHidden=false
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
            return String(str2)
        } catch {
            return ""
        }
    }
}

