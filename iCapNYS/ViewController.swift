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

class ViewController: UIViewController{
    
    let TempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
    
    @IBOutlet weak var soguButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBAction func unwindAction(segue: UIStoryboardSegue) {
        if segue.identifier=="fromRecord"{
            //            print("同じ")
        }
        setPlayButtonEnable()//tempFilePathがあれば有効化
        UIApplication.shared.isIdleTimerDisabled = false//スリープする
        if let vc = segue.source as? RecordViewController{
            let Controller:RecordViewController = vc
            print("segue:","\(segue.identifier!)")
            Controller.motionManager.stopDeviceMotionUpdates()
            Controller.captureSession.stopRunning()
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
    func setPlayButtonEnable(){
        let checkValidation = FileManager.default
        if (checkValidation.fileExists(atPath: TempFilePath)){
            playButton.setTitle("［ 再生 ］\n\n最新映像を再生します.\n\n眼振録画映像は\n\niCapNYSアルバムに\n\n保存されます.", for: .normal)
            print("ファイルあり、FILE AVAILABLE");
            playButton.isEnabled=true
        }else{
            playButton.setTitle("［ 再生 ］\n\nまだ映像がありません！\n\n眼振録画映像は\n\niCapNYSアルバムに\n\n保存されます.", for: .normal)
            print("ファイル無し、FILE NOT AVAILABLE");
            playButton.isEnabled=false
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.view.backgroundColor = UIColor.white// .cyanColor()
        camera_alert()
        soguButton.layer.cornerRadius=10
        cameraButton.setTitleColor(.white, for: .normal)
        cameraButton.backgroundColor=UIColor.systemGreen
        cameraButton.layer.cornerRadius = 30
        cameraButton.titleLabel!.numberOfLines = 11
        cameraButton.titleLabel!.textAlignment = NSTextAlignment.center
        cameraButton.setTitle("［ 録画 ］\n\nLEDは光量調節が出来ます.\n\n 明るすぎる機種の場合は\n\nLEDを紙等で覆って\n\n光量を調節して下さい.\n\nKuroda ENT Clinic", for: .normal)
        
        playButton.setTitleColor(.white, for: .normal)
        playButton.backgroundColor=UIColor.systemGreen
        playButton.layer.cornerRadius = 30
        playButton.titleLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        playButton.titleLabel!.numberOfLines = 9
        playButton.titleLabel!.textAlignment = NSTextAlignment.center
        setPlayButtonEnable()
        UIApplication.shared.isIdleTimerDisabled = false//スリープする
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewwillappear")
    }
    //    override func viewDidAppear(_ animated: Bool) {
    //    }
}
