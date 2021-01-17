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
    let album = AlbumController()
    let TempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
    let albumName:String = "iCapNYS"
    var videoArrayCount:Int = 0
    var videoDate = Array<String>()
    var videoURL = Array<URL>()
//    var albumExist:Bool=false
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
        album.getAlbumList()
        tableView.reloadData()
        videoArrayCount=album.videoURL.count
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        how2Button.layer.borderColor = UIColor.black.cgColor
        how2Button.layer.borderWidth = 1.0
        how2Button.layer.cornerRadius = 10
//        let album = AlbumController()
        album.getAlbumList()
//        getAlbumList()
        videoArrayCount = album.videoURL.count
        tableView.reloadData()
        UIApplication.shared.isIdleTimerDisabled = false//スリープする
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewwillappear")
    }
    //nuber of cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if album.albumExist==false{
            return 0
        }else{
//            let album = AlbumController()
            return album.videoURL.count
        }
    }
    //set data on cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell{
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier:"cell",for :indexPath)
        let number = (indexPath.row+1).description + ") "
        cell.textLabel!.text = number + album.videoDate[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "playView") as! PlayViewController
        nextView.videoURL = album.videoURL[indexPath.row]
        self.present(nextView, animated: true, completion: nil)
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }//not sort
    
    //セルの削除ボタンが押された時の処理
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //削除するだけなのでindexPath_row = indexPath.rowをする必要はない。
        if editingStyle == UITableViewCell.EditingStyle.delete {
            album.eraseVideo(number: indexPath.row)
            while album.dialogStatus==0{
                sleep(UInt32(0.1))
            }
            if album.dialogStatus==1{
                album.videoURL.remove(at: indexPath.row)
                album.videoDate.remove(at: indexPath.row)
                tableView.reloadData()
            }
        }
    }
}
