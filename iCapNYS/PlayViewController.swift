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

    var videoPlayer: AVPlayer!
    var duration:Float=0
    var currTime:UILabel?
    lazy var seekBar = UISlider()
    var timer:Timer?
//    var pHAsset: PHAsset?
    var videoURL:URL?
    @objc func update(tm: Timer) {
//        currTime?.text=String(format:"%.1fs",seekBar.value)
        let min=Int(seekBar.value/60)
        let sec=Int(seekBar.value)%60
        currTime?.text=String(format:"%d:%02d",min,sec)//seekBar.value)
    }
    func addVideoLayer(){//(playerItem:AVPlayerItem?, _: [AnyHashable : Any]?) {
//        duration=Float(CMTimeGetSeconds(playerItem!.duration))
//        // Create AVPlayer
//        videoPlayer = AVPlayer(playerItem: playerItem)
//        // Add AVPlayer
//        let layer = AVPlayerLayer()
        
//        let fileURL = URL(fileURLWithPath: TempFilePath)
        //    let fileURL = URL(fileURLWithPath: path)
        let avAsset = AVURLAsset(url: videoURL!)
        duration=Float(CMTimeGetSeconds(avAsset.duration))
        let playerItem: AVPlayerItem = AVPlayerItem(asset: avAsset)
        // Create AVPlayer
        videoPlayer = AVPlayer(playerItem: playerItem)
        // Add AVPlayer
        let layer = AVPlayerLayer()
        
        
        layer.videoGravity = AVLayerVideoGravity.resizeAspect
        layer.player = videoPlayer
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        // Create Movie SeekBar
        seekBar.frame = CGRect(x: 0, y: 0, width: view.bounds.maxX - 40, height: 50)
        seekBar.layer.position = CGPoint(x: view.bounds.midX, y: view.bounds.maxY - 100)
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
        let ww=view.bounds.width
        let butW=(ww-20*4)/3
        // Create Movie Start Button
        let startButton = UIButton(frame: CGRect(x: 0, y: 0, width: butW, height: 40))
        startButton.frame = CGRect(x: 0, y: 0, width: butW, height: 40)
        startButton.layer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.maxY - 50)
        startButton.layer.masksToBounds = true
        startButton.layer.cornerRadius = 5.0
        startButton.backgroundColor = UIColor.orange
        startButton.setTitle("停・再生", for: UIControl.State.normal)
        startButton.layer.borderColor = UIColor.black.cgColor
        startButton.layer.borderWidth = 1.0
        startButton.addTarget(self, action: #selector(onStartButtonTapped), for: UIControl.Event.touchUpInside)
        view.addSubview(startButton)
        
        let exitButton = UIButton(frame:CGRect(x: 0, y: 0, width:butW , height: 40))
        exitButton.layer.position = CGPoint(x: ww-20-butW/2, y: self.view.bounds.maxY - 50)
        exitButton.layer.masksToBounds = true
        exitButton.layer.cornerRadius = 5.0
        exitButton.backgroundColor = UIColor.darkGray
        exitButton.setTitle("戻る", for:UIControl.State.normal)
        exitButton.isEnabled=true
        exitButton.layer.borderColor = UIColor.black.cgColor
        exitButton.layer.borderWidth = 1.0
        exitButton.addTarget(self, action: #selector(onExitButtonTapped), for: UIControl.Event.touchUpInside)
        view.addSubview(exitButton)
        currTime = UILabel(frame:CGRect(x:0,y:0,width:butW,height:40))
        currTime!.layer.position = CGPoint(x: 20+butW/2, y: self.view.bounds.maxY - 50)
        currTime!.backgroundColor = UIColor.white
        currTime!.layer.masksToBounds = true
        currTime!.layer.cornerRadius = 5
        currTime!.textColor = UIColor.black
        currTime!.textAlignment = .center
        currTime!.font=UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .medium)
//        currTime!.text = String(format:"%.1fs",duration)
        currTime!.layer.borderColor = UIColor.black.cgColor
        currTime!.layer.borderWidth = 1.0
//        currTime1=currTime
        view.addSubview(currTime!)
        videoPlayer.play()
    }
    func killTimer(){
        if timer?.isValid == true {
            timer!.invalidate()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        addVideoLayer()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
//        let option = PHVideoRequestOptions()
//        option.deliveryMode = .highQualityFormat
//        let manager = PHImageManager.default()
//        manager.requestPlayerItem(forVideo: pHAsset!, options: option, resultHandler: addVideoLayer)
        
        // Create AVPlayerItem
        //            guard let path = Bundle.main.path(forResource: "movie", ofType: "mp4") else {
        //    fatalError("Movie file can not find.")
        //            }
        //        let fileURL = URL(fileURLWithPath: TempFilePath)
        //        //    let fileURL = URL(fileURLWithPath: path)
        //        let avAsset = AVURLAsset(url: fileURL)
        //        duration=Float(CMTimeGetSeconds(avAsset.duration))
        //        let playerItem: AVPlayerItem = AVPlayerItem(asset: avAsset)
        //        // Create AVPlayer
        //        videoPlayer = AVPlayer(playerItem: playerItem)
        //        // Add AVPlayer
        //        let layer = AVPlayerLayer()
        //        layer.videoGravity = AVLayerVideoGravity.resizeAspect
        //        layer.player = videoPlayer
        //        layer.frame = view.bounds
        //        view.layer.addSublayer(layer)
        //        // Create Movie SeekBar
        //        seekBar.frame = CGRect(x: 0, y: 0, width: view.bounds.maxX - 40, height: 50)
        //        seekBar.layer.position = CGPoint(x: view.bounds.midX, y: view.bounds.maxY - 100)
        //        seekBar.minimumValue = 0
        //        seekBar.maximumValue = Float(CMTimeGetSeconds(avAsset.duration))
        //        seekBar.addTarget(self, action: #selector(onSliderValueChange), for: UIControl.Event.valueChanged)
        //        view.addSubview(seekBar)
        //        // Processing to synchronize the seek bar with the movie.
        //
        //        // Set SeekBar Interval
        //        let interval : Double = Double(0.5 * seekBar.maximumValue) / Double(seekBar.bounds.maxX)
        //        // ConvertCMTime
        //        let time : CMTime = CMTimeMakeWithSeconds(interval, preferredTimescale: Int32(NSEC_PER_SEC))
        //        // Observer
        //        videoPlayer.addPeriodicTimeObserver(forInterval: time, queue: nil, using: {time in
        //            // Change SeekBar Position
        //            let duration = CMTimeGetSeconds(self.videoPlayer.currentItem!.duration)
        //            let time = CMTimeGetSeconds(self.videoPlayer.currentTime())
        //            let value = Float(self.seekBar.maximumValue - self.seekBar.minimumValue) * Float(time) / Float(duration) + Float(self.seekBar.minimumValue)
        //            self.seekBar.value = value
        //        })
    }

    // Start Button Tapped
    @objc func onStartButtonTapped(){
        if (videoPlayer.rate != 0) && (videoPlayer.error == nil) {//playing
            videoPlayer.pause()
        }else{//stoped
            if seekBar.value>seekBar.maximumValue-0.5{
            seekBar.value=0
            }
            videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(seekBar.value), preferredTimescale: Int32(NSEC_PER_SEC)))
            videoPlayer.play()
        }
    }
    // SeekBar Value Changed
    @objc func onSliderValueChange(){
        videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(seekBar.value), preferredTimescale: Int32(NSEC_PER_SEC)))
        videoPlayer.pause()
    }
    @objc func onExitButtonTapped(){//このボタンのところにsegueでunwindへ行く
        killTimer()
        self.performSegue(withIdentifier: "fromPlay", sender: self)
    }
}

