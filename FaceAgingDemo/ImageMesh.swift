//
//  ImageMesh.swift
//  FaceDemo
//
//  Created by wuzhiqiang on 2019/3/12.
//  Copyright © 2019 wuzhiqiang. All rights reserved.
//

import Foundation
import GLKit

class ImageMesh: NSObject {
    
    var verticalDivisions = 0
    var horizontalDivisions = 0
    var indexArrSize = 0
    var vertexIndices: [Int]? = nil
    
    // Opengl坐标点数组
    var verticesArr: [Float]? = nil
    var textureCoordsArr: [Float]? = nil
    var texture: GLKTextureInfo? = nil
    
    var image_width: Float = 0.0
    var image_height: Float = 0.0
    
    var numVertices: Int = 0
    
    var xy: [vector_float2]? = nil
    var ixy: [vector_float2]? = nil
    
    convenience init(vd: Int, hd: Int) {
        self.init()
        verticalDivisions = vd
        horizontalDivisions = hd
        
        numVertices = (verticalDivisions + 1) * (horizontalDivisions + 1)
        indexArrSize = 2 * verticalDivisions * (horizontalDivisions + 1)
        
        verticesArr = [Float](repeating: 0.0, count: 2 * indexArrSize)
        textureCoordsArr = [Float](repeating: 0.0, count: 2 * indexArrSize)
        vertexIndices = [Int](repeating: 0, count: indexArrSize)
        
        xy = [vector_float2](repeating: [0.0, 0.0], count: numVertices)
        ixy = [vector_float2](repeating: [0.0, 0.0], count: numVertices)
        
        var count = 0
        for i in 0..<verticalDivisions {
            for j in 0...horizontalDivisions {
                vertexIndices![count] = (i + 1) * (horizontalDivisions + 1) + j; count += 1
                vertexIndices![count] = i * (horizontalDivisions + 1) + j; count += 1
            }
        }
        
        let xIncrease = 1.0 / Float(horizontalDivisions)
        let yIncrease = 1.0 / Float(verticalDivisions)
        count = 0
        for i in 0..<verticalDivisions {
            for j in 0...horizontalDivisions {
                let currX = Float(j) * xIncrease;
                let currY = 1 - Float(i) * yIncrease;
                textureCoordsArr![count] = currX; count += 1
                textureCoordsArr![count] = currY - yIncrease; count += 1
                textureCoordsArr![count] = currX; count += 1
                textureCoordsArr![count] = currY; count += 1
            }
        }
    }
    
    
    func loadImage(image: UIImage, width: CGFloat, height: CGFloat) -> UIImage? {

        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let pngImage = UIImage(data: newImage!.pngData()!)
        
        do {
            texture = try GLKTextureLoader.texture(with: pngImage!.cgImage!)
        } catch {
            debugPrint("error: \(error)")
        }
        
        image_width = Float(newImage!.size.width)
        image_height = Float(newImage!.size.height)
    
        initialize()
        
        return newImage
    }
    
    func initialize() {
        let stX = -image_width / 2
        let stY = -image_height / 2
        var count = 0
        let width = image_width / Float(horizontalDivisions)
        let height = image_height / Float(verticalDivisions)
        for i in 0...verticalDivisions {
            for j in 0...horizontalDivisions {
                xy![count] = [Float(j) * width + stX, Float(i) * height + stY]
                ixy![count] = xy![count]
                count += 1
            }
        }

        deform()
    }
    
    
    /// 重置坐标数组以实现变形
    func deform() {
        for i in 0..<indexArrSize {
            verticesArr![2 * i] = xy![vertexIndices![i]][0]
            verticesArr![2 * i + 1] = xy![vertexIndices![i]][1]
        }
    }
}
