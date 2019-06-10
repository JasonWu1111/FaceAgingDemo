//
//  FaceAgingController.swift
//  FaceDemo
//
//  Created by wuzhiqiang on 2019/3/12.
//  Copyright © 2019 wuzhiqiang. All rights reserved.
//

import UIKit
import GLKit
import CoreML

class FaceAgingController: UIViewController {
    
    // 预设皱纹特征点坐标
    let face_df_vertices: [vector_float2] = [
        [1,295], [2,345], [2,396], [10,454], [26,508],
        [58,566], [100,621], [139,650], [180,674], [239,682],
        [294,676], [340,649], [375,620], [416,568], [444,513],
        [463,458], [475,399], [478,350], [475,297],
        
        [67,296], [119,269], [171,296], [121,318], [120,293],
        [305,296], [354,269], [408,295], [355,316], [353,293],
        
        [213,296], [192,389], [167,441], [206,480], [239,482],
        [275,480], [312,444], [282,389], [266,293], [239,440],
        
        [138,533], [239,512], [342,529], [239,561]
    ]
    
    @IBOutlet weak var originalImageView: UIImageView!
    @IBOutlet weak var agingImageView: UIImageView!

    var faceImage: UIImage?
    var faceBean: FaceBean?
    var glkViewController: FaceGLKViewController? = nil
    
    override func viewDidLoad() {
        faceImage = UIImage(named: "Face")
        originalImageView.image = faceImage
        FaceService.uploadImage(image: faceImage!) { (faceBean, error) in
            guard let faceBean = faceBean else {
                return
            }
            
            self.startAging(faceImage: self.faceImage!, faceBean: faceBean)
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GLKView", let glkViewController = segue.destination as? FaceGLKViewController {
            self.glkViewController = glkViewController
        }
    }
    
    
    @IBAction func share(_ sender: Any) {
        ImageUtil.shareImage(parent: self, image: agingImageView.image!)
    }
}

// MARK: 人脸老化处理相关
extension FaceAgingController {
    
    func startAging(faceImage: UIImage, faceBean: FaceBean) {
        // 人脸变老处理
        let faceRect = faceBean.faces.first?.faceRectangle
        let left = (faceRect?.faceRectangleLeft)!
        let top = (faceRect?.top)! - (faceRect?.height)! * 2 / 5
        let rect = CGRect(x: left, y: top, width: (faceRect?.width)!, height: (faceRect?.height)! * 9 / 5)
        
        var vertexData = [float2]()
        let landmarks = faceBean.faces.first?.landmark
        for vertex in (self.glkViewController?.face_vertices)! {
            let data: float2 = [Float(landmarks![vertex]!.x - left) - Float(rect.size.width / 2), Float(rect.size.height / 2) - Float(landmarks![vertex]!.y - top)]
            vertexData.append(data)
        }
        
        let squareRect = CGRect(x: left - (Int(rect.height - rect.width)) / 2, y: top, width: Int(rect.height), height: Int(rect.height))
        let wrinkle_orignal = UIImage(named: "Wrinkle")!
        self.glkViewController?.setupImage(image: wrinkle_orignal, width: rect.size.width, height: rect.size.height, original_vertices: self.face_df_vertices, target_vertices: vertexData)
        
        let wrinkle = (self.glkViewController?.view as! GLKView).snapshot
        let agingResult = self.faceAging(face: faceImage, wrinkle: wrinkle, faceRect: squareRect)
        
        self.agingImageView.image = agingResult
    }
    

    /// 人脸变老
    ///
    /// - Parameters:
    ///   - face: 人脸图片
    ///   - wrinkle: 皱纹纹理图片
    ///   - faceRect: 人脸区域
    /// - Returns: 合成结果
    func faceAging(face: UIImage, wrinkle: UIImage, faceRect: CGRect) -> UIImage? {
        let rendererRect = CGRect(x: 0, y: 0, width: face.size.width, height: face.size.height)
        let renderer = UIGraphicsImageRenderer(bounds: rendererRect)
        let outputImage = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(rendererRect)
            face.draw(in: rendererRect, blendMode: .normal, alpha: 1)
            // 柔光融合
            wrinkle.draw(in: faceRect, blendMode: .softLight, alpha: 1)
        }
        return outputImage
    }
}
