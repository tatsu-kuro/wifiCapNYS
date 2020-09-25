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

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    var videoTitle = Array<String>()
    var videoPath = Array<String>()
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoTitle.count//fruits.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得する
        let videoCount=videoTitle.count
                let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "videoFileCell", for: indexPath)
                
                // セルに表示する値を設定する
//        print("videoTitle:",videoCount,indexPath.row)
        cell.textLabel!.text = videoTitle[videoCount - 1 - indexPath.row]
                
                return cell
    }
    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var cameraView: UIImageView!
//    @IBOutlet weak var currentTime: UILabel!

    @IBOutlet weak var cameraButton: UIButton!
    @IBAction func unwindAction(segue: UIStoryboardSegue) {
        print("segue:","\(segue.identifier!)")//通らないが帰ってくる。
        searchAlbum()
        tableView?.reloadData()
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
        camera_alert()
        cameraButton.layer.borderColor = UIColor.green.cgColor
        cameraButton.layer.borderWidth = 2.0
        cameraButton.layer.cornerRadius = 10
        let str=getFilesindoc()
        print(str)
        searchAlbum()
        tableView.reloadData()
    }
 
    func searchAlbum(){
        videoPath.removeAll()
        videoTitle.removeAll()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        collections.enumerateObjects { (collection: PHAssetCollection, index: Int, stop) in
//            print("index,collection::::",index, collection)
            if collection.localizedTitle == "iCapNYS" { //アルバム名
                let assets = PHAsset.fetchAssets(in: collection, options: nil)
                assets.enumerateObjects({ [self] (asset, index, stop) in
                    let date=formatter.string(from: asset.creationDate!)
                    let duration=generateDuration(timeInterval: asset.duration)
                    videoTitle.append(date + "(" + duration + ")")
                })
                //stop.pointee = true //同じ名前のアルバムが複数存在出来るようなのでstopしない
            } else {
//                print(index, "skip")
            }
        }
    }
   
    func generateDuration(timeInterval: TimeInterval) -> String {

           let min = Int(timeInterval / 60)
           let sec = Int(round(timeInterval.truncatingRemainder(dividingBy: 60)))
           let duration = String(format: "%02d:%02d", min, sec)
           return duration
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

