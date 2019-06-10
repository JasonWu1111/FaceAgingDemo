//
//  FaceService.swift
//  FaceDemo
//
//  Created by wuzhiqiang on 2019/2/25.
//  Copyright © 2019 wuzhiqiang. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

enum FaceError {
    case noFaceFound
    case networkFail
    case other
}


class FaceService {

    static let API_KEY = "gQ2llFkuQmEf5DpNVpy3FKZsO7QySOEx"
    static let API_SECRET = "6-OLrhszVuJEgW1dx8pJ8tvLYBJHkPIq"
    static let DETECT_URL = "https://api-cn.faceplusplus.com/facepp/v3/detect"
    static let MERGE_URL = "https://api-cn.faceplusplus.com/imagepp/v1/mergeface"
    
    static func uploadImage(image: UIImage, completion: @escaping (_ data: FaceBean?, _ error: FaceError?) -> ()) {
        let parameters = ["api_key": API_KEY, "api_secret": API_SECRET, "return_landmark": "1"]
        if image.jpegData(compressionQuality: 0.5) == nil {
            completion(nil, .other)
        }
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(image.jpegData(compressionQuality: 0.5)!, withName: "image_file", fileName: "profile.jpeg", mimeType: "image/jpeg")
            for (key, value) in parameters {
                multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
            }
        }, to: DETECT_URL) { (result) in
            switch result {
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    if response.result.isFailure {
                        completion(nil, .networkFail)
                        return
                    }
                    let json = JSON(response.value as Any)
                    debugPrint(json)
                    let faceBean = try? JSONDecoder().decode(FaceBean.self, from: json.rawData())
                    if faceBean == nil || (faceBean?.faces.count)! == 0 {
                        completion(nil, .noFaceFound)
                    } else {
                        completion(faceBean, nil)
                    }
                }
                
            case .failure:
                completion(nil, .networkFail)
            }
        }
    }
}
