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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fruits.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得する
                let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "videoFileCell", for: indexPath)
                
                // セルに表示する値を設定する
                cell.textLabel!.text = fruits[indexPath.row]
                
                return cell
    }
    
    let fruits = ["apple", "orange", "melon", "banana", "pineapple", "orange", "melon", "banana", "pineapple", "orange", "melon", "banana", "pineapple", "orange", "melon", "banana", "pineapple"]
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBAction func unwindAction(segue: UIStoryboardSegue) {
        print("\(segue.identifier!)")//通らないが帰ってくる。
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

        let str=getFilesindoc()
        print(str)
    }
 

    override func viewDidAppear(_ animated: Bool) {
        setButtons(type: true)
    }
    @IBOutlet weak var dammyBottom: UILabel!
    func setButtons(type:Bool){
        let ww:CGFloat=view.bounds.width
        let wh:CGFloat=view.bounds.height//dammyBottom.frame.maxY// view.bounds.height
        let startButWidth=ww*9/10
        let startButHeight=ww*4/10
        let playButWidth=ww*3/10//bw//:Int=60
        let playButHeight=ww*2/10
//        currentTime.frame = CGRect(x:0,y: 0 ,width:ww/3, height: bh/2)
//        currentTime.layer.position=CGPoint(x:ww/2,y:wh-bh*2-bh/4)
//        currentTime.layer.masksToBounds = true
//        currentTime.layer.cornerRadius = 5

        //startButton
//        startButton.frame=CGRect(x:0,y:0,width:startButWidth,height:startButHeight)
//        startButton.layer.position = CGPoint(x:ww/2,y:wh-startButHeight)
//        playButton.frame=CGRect(x:0,y:0,width:playButWidth,height:playButHeight)
//        playButton.layer.position = CGPoint(x:ww/2,y:wh-startButHeight*3/2-playButHeight)
//        playButton.layer.borderColor = UIColor.green.cgColor
//        playButton.layer.borderWidth = 2.0
//        playButton.layer.cornerRadius = 10
        startButton.layer.borderColor = UIColor.green.cgColor
        startButton.layer.borderWidth = 2.0
        startButton.layer.cornerRadius = 10
        startButton.isHidden=false
        playButton.isHidden=true
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

