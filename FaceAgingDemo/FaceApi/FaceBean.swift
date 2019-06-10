//
//  FaceData.swift
//  FaceDemo
//
//  Created by wuzhiqiang on 2019/2/26.
//  Copyright © 2019 wuzhiqiang. All rights reserved.
//

import Foundation

// MARK: - FaceBean
class FaceBean: Codable {
    let imageID: String
    let faces: [Face]
    let requestID: String
    let timeUsed: Int
    
    enum CodingKeys: String, CodingKey {
        case imageID = "image_id"
        case faces
        case requestID = "request_id"
        case timeUsed = "time_used"
    }
    
    init(imageID: String, faces: [Face], requestID: String, timeUsed: Int) {
        self.imageID = imageID
        self.faces = faces
        self.requestID = requestID
        self.timeUsed = timeUsed
    }
}

// MARK: - Face
class Face: Codable {
    let landmark: [String: Landmark]
    let faceRectangle: FaceRectangle
    let faceToken: String
    
    enum CodingKeys: String, CodingKey {
        case landmark
        case faceRectangle = "face_rectangle"
        case faceToken = "face_token"
    }
    
    init(landmark: [String: Landmark], faceRectangle: FaceRectangle, faceToken: String) {
        self.landmark = landmark
        self.faceRectangle = faceRectangle
        self.faceToken = faceToken
    }
}

// MARK: - FaceRectangle
class FaceRectangle: Codable {
    let top, width, faceRectangleLeft, height: Int
    
    enum CodingKeys: String, CodingKey {
        case top, width
        case faceRectangleLeft = "left"
        case height
    }
    
    init(top: Int, width: Int, faceRectangleLeft: Int, height: Int) {
        self.top = top
        self.width = width
        self.faceRectangleLeft = faceRectangleLeft
        self.height = height
    }
}

// MARK: - Landmark
class Landmark: Codable {
    let x, y: Int
    
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}
