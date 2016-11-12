//
//  CustomPhotoAlbum.swift
//  Hypercron
//
//  Created by Dennis Beatty on 11/12/16.
//  Copyright © 2016 Dennis Beatty. All rights reserved.
//

import Foundation
import Photos

extension PHPhotoLibrary {
    
    typealias PhotoAsset = PHAsset
    typealias PhotoAlbum = PHAssetCollection
    
    static func saveImage(image: UIImage, albumName: String, completion: @escaping (PHAsset?)->()) {
        if let album = self.findAlbum(albumName: albumName) {
            self.saveImage(image: image, album: album, completion: completion)
            return
        }
        createAlbum(albumName: albumName) { album in
            if let album = album {
                self.saveImage(image: image, album: album, completion: completion)
            }
            else {
                assert(false, "Album is nil")
            }
        }
    }
    
    static private func saveImage(image: UIImage, album: PhotoAlbum, completion: @escaping (PHAsset?)->()) {
        var placeholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            // Request creating an asset from the image
            let createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            // Request editing the album
            guard let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) else {
                assert(false, "Album change request failed")
                return
            }
            // Get a placeholder for the new asset and add it to the album editing request
            guard let photoPlaceholder = createAssetRequest.placeholderForCreatedAsset else {
                assert(false, "Placeholder is nil")
                return
            }
            placeholder = photoPlaceholder
            let fastEnumeration = NSArray(array: [photoPlaceholder] as [PHObjectPlaceholder])
            albumChangeRequest.addAssets(fastEnumeration)
        }, completionHandler: { success, error in
            guard let placeholder = placeholder else {
                assert(false, "Placeholder is nil")
                completion(nil)
                return
            }
            
            if success {
                completion(PHAsset.fetchAssets(withLocalIdentifiers: [placeholder.localIdentifier], options: nil).firstObject)
            } else {
                print(error!)
                completion(nil)
            }
        })
    }
    
    static func findAlbum(albumName: String) -> PhotoAlbum? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
        guard let photoAlbum = fetchResult.firstObject else {
            return nil
        }
        return photoAlbum
    }
    
    static func createAlbum(albumName: String, completion: @escaping (PhotoAlbum?)->()) {
        var albumPlaceholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            // Request creating an album with parameter name
            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            // Get a placeholder for the new album
            albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
        }, completionHandler: { success, error in
            guard let placeholder = albumPlaceholder else {
                assert(false, "Album placeholder is nil")
                completion(nil)
                return
            }
            
            
            let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
            guard let album = fetchResult.firstObject else {
                assert(false, "FetchResult has no PHAssetCollection")
                completion(nil)
                return
            }
            
            if success {
                completion(album)
            }
            else {
                print(error!)
                completion(nil)
            }
        })
    }
    
    static func loadThumbnailFromLocalIdentifier(localIdentifier: String, completion: @escaping (UIImage?)->()) {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject else {
            completion(nil)
            return
        }
        loadThumbnailFromAsset(asset: asset, completion: completion)
    }
    
    static func loadThumbnailFromAsset(asset: PhotoAsset, completion: @escaping (UIImage?)->()) {
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 100.0, height: 100.0), contentMode: .aspectFit, options: PHImageRequestOptions(), resultHandler: { result, info in
            completion(result)
        })
    }
    
    static func loadLatestFromAlbum(albumName: String, size: CGSize, completion: @escaping (UIImage?) -> ()) {
        // Get the album to get images from
        let album = self.findAlbum(albumName: albumName)! as PHAssetCollection
        
        // Sort the images by creation date
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        if let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions).firstObject {
            // Note that if the request is not set to synchronous
            // the requestImageForAsset will return both the image
            // and thumbnail; by setting synchronous to true it
            // will return just the thumbnail
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            
            PHImageManager.default().requestImage(for: fetchResult, targetSize: size, contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: {
                (image, _) in
                completion(image)
            })
        }
    }
}
