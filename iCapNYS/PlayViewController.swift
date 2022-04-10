//
//  PlayViewController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2020/09/22.
//

import UIKit
import AVFoundation
import Photos
class PlayViewController: UIViewController{
    var phasset:PHAsset?
    var avasset:AVAsset?
    var videoPlayer: AVPlayer!
    var duration:Float=0
    var currTime:UILabel?
    var calcDate:String?
    lazy var seekBar = UISlider()
    var timer:Timer?
    @IBOutlet weak var exit2Button: UIButton!
    //    var videoURL:URL?
  
    let someFunctions = myFunctions()
    override var shouldAutorotate: Bool {
        return false
    }
/*
 let value = UIInterfaceOrientation.landscapeLeft.rawValue
 UIDevice.current.setValue(value, forKey: "orientation")
 
 
 override var shouldAutorotate: Bool {
     return true
 }
*/
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let landscapeSide=someFunctions.getUserDefaultInt(str: "landscapeSide", ret: 0)
        if landscapeSide==0{
            return UIInterfaceOrientationMask.landscapeRight
        }else{
            return UIInterfaceOrientationMask.landscapeLeft
        }
    }
    
    @objc func update(tm: Timer) {
        let min=Int(seekBar.value/60)
        let sec=Int(seekBar.value)%60
        let dura=Int(duration)
        currTime?.text=String(format:"%d:%02d / %d:%02d",min,sec,dura/60,dura%60)//seekBar.value)
    }
   
    func killTimer(){
        if timer?.isValid == true {
            timer!.invalidate()
        }
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    func setButtonProperty(button:UIButton,title:String,color:UIColor){
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1.0
        button.setTitle(title, for: UIControl.State.normal)

        button.layer.masksToBounds = true
        button.layer.cornerRadius = 5.0
        button.backgroundColor = color
    }
    /*
    func getURL(ofPhotoWith mPhasset: PHAsset) -> URL{
        
        let options: PHVideoRequestOptions = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.version = .original
        var urlStr2 = URL(string:"")
        
        let semaphore = DispatchSemaphore(value: 0)
        PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: options, resultHandler: { (asset, audioMix, info) in
            
            if let tokenStr = info?["PHImageFileSandboxExtensionTokenKey"] as? String {
                let tokenKeys = tokenStr.components(separatedBy: ";")
                let urlStr = tokenKeys.filter { $0.contains("/private/var/mobile/Media") }.first
                urlStr2 = URL(string:urlStr!)
                if let urlStr = urlStr {
                    if let url = URL(string: urlStr) {
                        print(url.lastPathComponent)
                        print(url.pathExtension)
                    }
                }
            }
            do {semaphore.signal() }
        })
//        semaphore.wait(timeout: DispatchTime.distantFuture)
        return urlStr2!
    }*/
    /*
    func requestAVAsset(asset: PHAsset) -> AVAsset? {
        // We only want videos here
        guard asset.mediaType == .video else { return nil }
        // Create your semaphore and allow only one thread to access it
        let semaphore = DispatchSemaphore.init(value: 1)
        let imageManager = PHImageManager()
        var avAsset: AVAsset?
        // Lock the thread with the wait() command
        semaphore.wait()
        // Now go fetch the AVAsset for the given PHAsset
        imageManager.requestAVAsset(forVideo: asset, options: nil) { (asset, _, _) in
            // Save your asset to the earlier place holder
            avAsset = asset
            // We're done, let the semaphore know it can unlock now
            semaphore.signal()
        }

        return avAsset
    }*/
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
    override func viewDidLoad() {
        super.viewDidLoad()
//        let mainBrightness = UIScreen.main.brightness
//        UserDefaults.standard.set(mainBrightness, forKey: "mainBrightness")

//        print("viewDidLoad*******")
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
        let by1=wh-(bh+sp)*2+1.5*sp
        let x0=leftPadding+sp*2
        duration=Float(phasset!.duration)// Float(CMTimeGetSeconds(avAsset.duration))

//        let videoURL=getURL(ofPhotoWith: phasset!)
//        let avAsset = AVURLAsset(url: videoURL)
//        let avAsset = requestAVAsset(asset: phasset!)
        
        let playerItem: AVPlayerItem = AVPlayerItem(asset: avasset!)
        // Create AVPlayer
        videoPlayer = AVPlayer(playerItem: playerItem)
        // Add AVPlayer
        let layer = AVPlayerLayer()
        layer.videoGravity = AVLayerVideoGravity.resizeAspect
        layer.player = videoPlayer
        print(self.view.bounds,":",view.bounds)
        layer.frame = self.view.bounds
        self.view.layer.addSublayer(layer)
        // Create Movie SeekBar
        seekBar.frame = CGRect(x: x0, y: by1, width: ww - 4*sp, height: bh)
//        seekBar.layer.position = CGPoint(x: view.bounds.midX, y: view.bounds.maxY - 100)
        seekBar.minimumValue = 0
        seekBar.maximumValue = duration
        seekBar.addTarget(self, action: #selector(onSliderValueChange), for: UIControl.Event.valueChanged)
        view.addSubview(seekBar)
        // Set SeekBar Interval
        let interval : Double = Double(0.5 * seekBar.maximumValue) / Double(seekBar.bounds.maxX)
        // ConvertCMTime
        let time : CMTime = CMTimeMakeWithSeconds(interval, preferredTimescale: Int32(NSEC_PER_SEC))
        // Observer
        videoPlayer.addPeriodicTimeObserver(forInterval: time, queue: nil, using: {time in
            // Change SeekBar Position
            let duration = CMTimeGetSeconds(self.videoPlayer.currentItem!.duration)
            let time = CMTimeGetSeconds(self.videoPlayer.currentTime())
            let value = Float(self.seekBar.maximumValue - self.seekBar.minimumValue) * Float(time) / Float(duration) + Float(self.seekBar.minimumValue)
            self.seekBar.value = value
        })
//        let ww=view.bounds.width
//        let butW=(ww-20*4)/3
        // Create Movie Start Button
        let toTopButton = UIButton(frame: CGRect(x: x0+3*bw+3*sp, y: by, width: bw, height: bh))
        setButtonProperty(button: toTopButton, title:"top",color: UIColor.orange)
        toTopButton.addTarget(self, action: #selector(onToTopButtonTapped), for: UIControl.Event.touchUpInside)
        view.addSubview(toTopButton)

        let startButton = UIButton(frame: CGRect(x: x0+4*bw+4*sp, y: by, width: bw, height: bh))
        setButtonProperty(button: startButton, title:"play",color: UIColor.orange)
        startButton.addTarget(self, action: #selector(onStartButtonTapped), for: UIControl.Event.touchUpInside)
        view.addSubview(startButton)

        let stopButton = UIButton(frame: CGRect(x: x0+5*bw+5*sp, y: by, width: bw, height: bh))
        setButtonProperty(button: stopButton, title:"stop",color: UIColor.orange)
        stopButton.addTarget(self, action: #selector(onStopButtonTapped), for: UIControl.Event.touchUpInside)
        view.addSubview(stopButton)

//       let exitButton = UIButton(frame:CGRect(x: x0+6*bw+6*sp, y: by, width:bw , height: bh))
//        setButtonProperty(button: exitButton, title:"Exit",color: UIColor.darkGray)
//        exitButton.addTarget(self, action: #selector(onExitButtonTapped), for: UIControl.Event.touchUpInside)
//        view.addSubview(exitButton)
        
        currTime = UILabel(frame:CGRect(x:x0,y:by,width:bw*2+sp,height:bh))
        currTime!.backgroundColor = UIColor.white
        currTime!.layer.masksToBounds = true
        currTime!.layer.cornerRadius = 5
        currTime!.textColor = UIColor.black
        currTime!.textAlignment = .center
        currTime!.font=UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .medium)
        currTime!.layer.borderColor = UIColor.black.cgColor
        currTime!.layer.borderWidth = 1.0
        view.addSubview(currTime!)
        videoPlayer.play()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        exit2Button.frame=CGRect(x: x0+6*bw+6*sp, y: by, width:bw , height: bh)
        setButtonProperty(button: exit2Button, title: "Exit", color: UIColor.darkGray)
        view.bringSubviewToFront(exit2Button)
//        view.bringSubviewToFront(toTopButton)
//        view.bringSubviewToFront(exitButton1)
//        view.bringSubviewToFront(playButton1)
//        view.bringSubviewToFront(stopButton)
//        view.bringSubviewToFront(timeLabel)
    }
     
//    func setButtons(){
//        let leftPadding=CGFloat( UserDefaults.standard.integer(forKey:"leftPadding"))
//        let rightPadding=CGFloat(UserDefaults.standard.integer(forKey:"rightPadding"))
//        let topPadding=CGFloat(UserDefaults.standard.integer(forKey:"topPadding"))
//        let bottomPadding=CGFloat(UserDefaults.standard.integer(forKey:"bottomPadding"))/2
//        let ww:CGFloat=view.bounds.width-leftPadding-rightPadding
//        let wh:CGFloat=view.bounds.height-topPadding-bottomPadding
//        let sp=ww/120//間隙
//        let bw=(ww-sp*10)/7//ボタン幅
//        let bh=bw*170/440
//        let by=wh-bh-sp
//        let by1=wh-(bh+sp)*2
//        let x0=leftPadding+sp*2
//    }
    // Start Button Tapped
    @objc func onToTopButtonTapped(){
        if (videoPlayer.rate != 0) && (videoPlayer.error == nil) {//playing
            videoPlayer.pause()
        }
//        }else{//stoped
//            if seekBar.value>seekBar.maximumValue-0.5{
            seekBar.value=0
//            }
            videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(seekBar.value), preferredTimescale: Int32(NSEC_PER_SEC)))
//            videoPlayer.play()
//        }
    }
    @objc func onStopButtonTapped(){
//        if (videoPlayer.rate != 0) && (videoPlayer.error == nil) {//playing
            videoPlayer.pause()
//        }else{//stoped
//            if seekBar.value>seekBar.maximumValue-0.5{
//            seekBar.value=0
//            }
//            videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(seekBar.value), preferredTimescale: Int32(NSEC_PER_SEC)))
//            videoPlayer.play()
//        }
    }
    @objc func onStartButtonTapped(){
//        if (videoPlayer.rate != 0) && (videoPlayer.error == nil) {//playing
//            videoPlayer.pause()
//        }else{//stoped
            if seekBar.value>seekBar.maximumValue-0.5{
            seekBar.value=0
            }
            videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(seekBar.value), preferredTimescale: Int32(NSEC_PER_SEC)))
            videoPlayer.play()
//        }
    }
    // SeekBar Value Changed
    @objc func onSliderValueChange(){
        videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(seekBar.value), preferredTimescale: Int32(NSEC_PER_SEC)))
        videoPlayer.pause()
    }
//    @objc func onExitButtonTapped(){//このボタンのところにsegueでunwindへ行く
//        killTimer()
//        let mainView = storyboard?.instantiateViewController(withIdentifier: "mainView") as! ViewController
//        if UIApplication.shared.isIdleTimerDisabled == true{
//            UIApplication.shared.isIdleTimerDisabled = false//スリープする
//        }
////        self.present(mainView, animated: false, completion: nil)
//
//        performSegue(withIdentifier: "toMainView", sender: self)
//
//    }
 /*   func playVideo (view: UIViewController, videoAsset: PHAsset) {

        guard (videoAsset.mediaType == .video) else {
            print("Not a valid video media type")
            return
        }

        PHCachingImageManager().requestAVAsset(forVideo: videoAsset, options: nil) { (asset, audioMix, args) in
            let asset = asset as! AVURLAsset

            DispatchQueue.main.async {
                let player = AVPlayer(url: asset.url)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                view.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
            }
        }
    }*/
   
}

/*
 
 let requestOptions = PHVideoRequestOptions()
 requestOptions.version = PHVideoRequestOptionsVersion.current
 requestOptions.deliveryMode = PHVideoRequestOptionsDeliveryMode.highQualityFormat
 requestOptions.isNetworkAccessAllowed = true
         
 PHImageManager.default().requestPlayerItem(forVideo: avAsset,
                                            options: options) { playerItem, info in

 }
 
 
 
 func playVideo (view: UIViewController, videoAsset: PHAsset) {

     guard (videoAsset.mediaType == .video) else {
         print("Not a valid video media type")
         return
     }

     PHCachingImageManager().requestAVAsset(forVideo: videoAsset, options: nil) { (asset, audioMix, args) in
         let asset = asset as! AVURLAsset

         DispatchQueue.main.async {
             let player = AVPlayer(url: asset.url)
             let playerViewController = AVPlayerViewController()
             playerViewController.player = player
             view.present(playerViewController, animated: true) {
                 playerViewController.player!.play()
             }
         }
     }
 }
 static func playVideo (view:UIViewController, asset:PHAsset) {

         guard (asset.mediaType == PHAssetMediaType.Video)

             else {
                 print("Not a valid video media type")
                 return
         }

         PHCachingImageManager().requestAVAssetForVideo(asset, options: nil, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [NSObject : AnyObject]?) in

             let asset = asset as! AVURLAsset

             dispatch_async(dispatch_get_main_queue(), {

                 let player = AVPlayer(URL: asset.URL)
                 let playerViewController = AVPlayerViewController()
                 playerViewController.player = player
                 view.presentViewController(playerViewController, animated: true) {
                     playerViewController.player!.play()
                 }
             })
         })
     }
 */

