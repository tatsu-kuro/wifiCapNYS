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
    var videoTitleofAlbum = Array<String>()
    let TempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoTitle.count//fruits.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得する
        let videoCount=videoTitle.count
                let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "videoFileCell", for: indexPath)
                
                // セルに表示する値を設定する
//        print("videoTitle:",videoCount,indexPath.row)
        let ww=view.bounds.width//414 320-18
//        print(ww)
        cell.textLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 18*ww/320, weight: .medium)

        cell.textLabel!.text = videoTitle[videoCount - 1 - indexPath.row]
                
                return cell
    }
//    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var cameraView: UIImageView!
//    @IBOutlet weak var currentTime: UILabel!
//    private var users: [tableView] = [] {
//        didSet {
//            tableView?.reloadData()
//        }
//    }
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBAction func unwindAction(segue: UIStoryboardSegue) {
//        let lastCnt=videoTitle.count
        if segue.identifier=="fromRecord"{
//            print("同じ")
        }
        setPlayButtonEnable()//tempFilePathがあれば有効化
        UIApplication.shared.isIdleTimerDisabled = false//スリープする
        if let vc = segue.source as? RecordViewController{
            let Controller:RecordViewController = vc
            print("segue:","\(segue.identifier!)")
            Controller.motionManager.stopDeviceMotionUpdates()
//            if Controller.recordedFlag==true{//Exitの時はsearchAlbumしない
//                setTitleofAlbum()
//                while lastCnt == videoTitle.count{
//                    sleep(UInt32(0.5))
//                    setTitleofAlbum()
////                    print("videoCnt:",lastCnt,videoTitle.count)
//                }
            }
//        }
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
            playButton.setTitle("iCapNYSアルバム\n\nの最新映像を\n\n再生します。", for: .normal)
            print("ファイルあり、FILE AVAILABLE");
            playButton.isEnabled=true
        }else{
            playButton.setTitle("眼振映像は\n\niCapNYSアルバムに\n\n保存されます。", for: .normal)
            print("ファイル無し、FILE NOT AVAILABLE");
            playButton.isEnabled=false
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        camera_alert()
//        cameraButton.layer.borderColor = UIColor.white.cgColor
        cameraButton.setTitleColor(.white, for: .normal)
        cameraButton.backgroundColor=UIColor.systemGreen
//        cameraButton.layer.borderWidth = 2.0
        cameraButton.layer.cornerRadius = 30
//        playButton.layer.borderColor = UIColor.white.cgColor
        playButton.setTitleColor(.white, for: .normal)
        playButton.backgroundColor=UIColor.systemGreen
//        playButton.layer.borderWidth = 2.0
        playButton.layer.cornerRadius = 30
        playButton.titleLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        playButton.titleLabel!.numberOfLines = 5
        playButton.titleLabel!.textAlignment = NSTextAlignment.center
        setPlayButtonEnable()
//        videoTitleofAlbum.removeAll()
//        setTitleofAlbumArray()
//        print(videoTitleofAlbum.count)
//        let TempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
//        let fileURL = NSURL(fileURLWithPath: TempFilePath)
//        tableView.dataSource = self
//        tableView.delegate = self
//        print(getFilesindoc())
//        setArrays()
//        print(getFilesindoc())
    }
    override func viewWillAppear(_ animated: Bool) {
        setPathTitleArray()
//        searchAlbum()
//        tableView.reloadData()
        super.viewWillAppear(animated)
        print("viewwillappear")
    }
//    override func viewDidAppear(_ animated: Bool) {
//        tableView.reloadData()
//    }
    func getVideofns()->String{
        let str=getFilesindoc().components(separatedBy: "\n")
//        if !str[0].contains("iCapNYS"){
//            return ""
//        }
        var retStr:String=""
        for i in 0..<str.count{
            if str[i].contains(".MOV"){
                retStr += str[i] + ","
            }
        }
        //ifretStr += str[str.count-1]
        let retStr2=retStr.dropLast()
        return String(retStr2)
    }
    
    func getDuration(doc:String,path:String)->String{//for で回すのでdocumentsdirはgetgetしておる
        let vidpath = doc + "/" + path
        let fileURL = URL(fileURLWithPath: vidpath)
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let asset = AVURLAsset(url: fileURL, options: options)
//        print("duration:",asset.duration)
        
        
        let sec10 = Int(10*asset.duration.seconds)
        let duration = "\(sec10/10)" + "." + "\(sec10%10)" + "s"
        return duration
    }
    func getTitle(path:String)->String{
        let str0=path.components(separatedBy: "iCapNYS")
//        print(str0,str0[0],str0[1])
        let str1=str0[1].components(separatedBy: ".")
        return(str1[0])
    }
    func setPathTitleArray(){
        let fileNames = getVideofns()//videoPathtxt()
        var str = fileNames.components(separatedBy: ",")
        str.sort()//descend? ascend ?
        if str[0]==""{//"*.MOV"でstr.countは１,"*.MOV,*.MOV"で2
            return//""と何も無くてもstr.countは1   !!!!!
        }
        videoPath.removeAll()
        videoTitle.removeAll()
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        
        for i in 0..<str.count{
            videoPath.append(str[i])
            let duration = getDuration(doc: documentsDirectory, path: str[i])
            let date = getTitle(path: str[i])
            videoTitle.append(date + " (" + duration + ")")
        }
    }
    func setTitleofAlbumArray(){
//        videoPath.removeAll()
        videoTitleofAlbum.removeAll()
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
                    videoTitleofAlbum.append(date)
//                    print(date)
                })
                //stop.pointee = true //同じ名前のアルバムが複数存在出来るようなのでstopしない
            } else {
//                print(index, "skip")
            }
        }
    }
    /*
    @IBAction func eraseVideo(_ sender: Any) {
        let str=getFsindoc().components(separatedBy: ",")
        if !str[0].contains("vHIT96da"){
            return
        }
        let str1=vidPath[vidCurrent].components(separatedBy: ".MOV")
        //str1[0]=vHIT96da*(.MOVを削ったもの)
        let lastvidCurrent=vidCurrent
        for i in 0..<str.count{
            if str[i].contains(str1[0]){
                if removeFile(delFile: str[i])==true{
                    print("remove completed:",str[i])
                    eyeVeloOrig.removeAll()
                    eyeVeloFiltered.removeAll()
                    faceVeloOrig.removeAll()
                    faceVeloFiltered.removeAll()
                    eyePosOrig.removeAll()
                    eyePosFiltered.removeAll()
                    gyroMoved.removeAll()
                }
            }
        }
        setArrays()//vidCurrent -> lastoneにセットされる
        vidCurrent=lastvidCurrent-1
        if vidCurrent<0{
            vidCurrent=0
        }
        startFrame=0
        showCurrent()
        showBoxies(f: false)
        dispWakuImages()
    }*/
    /*func setVideoPathDate(num:Int){//0:sample.MOV 1-n はアルバムの中の古い順からの　*.MOV のパス
        let result:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular , options: nil)
        let assetCollection = result.firstObject;
        // アルバムからアセット一覧を取得
        let fetchAssets = PHAsset.fetchAssets(in: assetCollection!, options: nil)
        print(fetchAssets.count)
        if num > fetchAssets.count {//その番号のビデオがないとき
            return
        }
        // アセットを取得
        let asset = fetchAssets.object(at: num-1)
        //        let option = PHVideoRequestOptions()
        //print(Int(10*asset.duration))
        let sec10 = Int(10*asset.duration)
        //videoDuration = "\(sec10/10)" + "." + "\(sec10%10)" + "s"
        let temp = "\(sec10/10)" + "." + "\(sec10%10)" + "s"
        //        slowDura.append(temp)
        //        slowDuraorg.append(temp)
        //        startPoints.append(0)
        let dateFormatter = DateFormatter()
        //To prevent displaying either date or time, set the desired style to NoStyle.
        dateFormatter.timeStyle = .medium //Set time style
        dateFormatter.dateStyle = .medium //Set date style
        dateFormatter.timeZone = NSTimeZone() as TimeZone?//TimeZone(identifier: "ja")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let localDate = dateFormatter.string(from: asset.creationDate!)
        //       videoDate.text = localDate + " (\(num))"
        //        slowDate.append(localDate + " (\(num))")
        //       freecntLabel.text = "\(freeCounter)"
        // アセットの情報を取得
        let videoDate=localDate + temp
        let options=PHVideoRequestOptions()
        options.version = .original
        PHImageManager.default().requestAVAsset(forVideo: asset,
                                                options: options){(asset:AVAsset?,audioMix, info:[AnyHashable:Any]?)->Void in
            
            if let urlAsset = asset as? AVURLAsset{
                let localURL=urlAsset.url as URL
                self.videoPath.append(localURL.path)
                self.videoTitle.append(videoDate)
                //                                                          self.appendingFlag=false
                
            }else{
                self.videoPath.append("delete")
                self.videoTitle.append(videoDate)

                //                                                          self.appendingFlag=false
            }
        }
    }*/
    func generateDuration(timeInterval: TimeInterval) -> String {

           let min = Int(timeInterval / 60)
           let sec = Int(round(timeInterval.truncatingRemainder(dividingBy: 60)))
           let duration = String(format: "%01d:%02d", min, sec)
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
                str += files[i] + "\n"
            }
            let str2=str.dropLast()
            return String(str2)
        } catch {
            return ""
        }
    }
}
//UIApplication.shared.isIdleTimerDisabled = true//スリープしない
