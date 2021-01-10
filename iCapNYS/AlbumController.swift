//
//  AlbumController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2021/01/10.
//

import UIKit
import Photos
import AVFoundation
class AlbumController: NSObject {
    let albumName:String = "iCapNYS"
    var videoDate = Array<String>()
    var videoURL = Array<URL>()
    var albumExist:Bool = false
    func albumExists() -> Bool {
        // ここで以下のようなエラーが出るが、なぜか問題なくアルバムが取得できている
        let albums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype:
            PHAssetCollectionSubtype.albumRegular, options: nil)
        for i in 0 ..< albums.count {
            let album = albums.object(at: i)
            if album.localizedTitle != nil && album.localizedTitle == albumName {
                return true
            }
        }
        return false
    }
    
    //何も返していないが、ここで見つけたor作成したalbumを返したい。そうすればグローバル変数にアクセスせずに済む
    func createNewAlbum( callback: @escaping (Bool) -> Void) {
        if self.albumExists() {
            callback(true)
        } else {
            PHPhotoLibrary.shared().performChanges({ [self] in
                _ = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            }) { (isSuccess, error) in
                callback(isSuccess)
            }
        }
    }
    func makeAlbum(){
        if albumExists()==false{
            createNewAlbum() { [self] (isSuccess) in
                if isSuccess{
                    print(albumName," can be made,")
                } else{
                    print(albumName," can't be made.")
                }
            }
        }else{
            print(albumName," exist already.")
        }
    }
    func getPHAssetcollection()->PHAssetCollection{
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = false
        requestOptions.deliveryMode = .highQualityFormat //これでもicloud上のvideoを取ってしまう
        //アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", albumName)
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: assetFetchOptions)
        //アルバムはviewdidloadで作っているのであるはず？
//        if (assetCollections.count > 0) {
        //同じ名前のアルバムは一つしかないはずなので最初のオブジェクトを使用
        return assetCollections.object(at:0)
    }
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
}
