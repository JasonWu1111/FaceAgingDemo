//
//  FaceWrinkle.swift
//  FaceDemo
//
//  Created by wuzhiqiang on 2019/3/14.
//  Copyright © 2019 wuzhiqiang. All rights reserved.
//

import UIKit
import GLKit

class FaceGLKViewController: GLKViewController {

    var context: EAGLContext?
    var effect: GLKBaseEffect?
    var mainImage: ImageMesh?
    var ratio_width: Float = 0.0, ratio_height: Float = 0.0
    var width: Float = 0.0, height: Float = 0.0
    
    /// 坐标点取自Face++：https://console.faceplusplus.com.cn/documents/5671270
    let face_vertices = [
        "contour_left1", "contour_left2", "contour_left3", "contour_left4", "contour_left5",
        "contour_left6", "contour_left7", "contour_left8", "contour_left9", "contour_chin",
        "contour_right9", "contour_right8", "contour_right7", "contour_right6", "contour_right5",
        "contour_right4", "contour_right3", "contour_right2", "contour_right1",
        
        "left_eye_left_corner", "left_eye_top", "left_eye_right_corner", "left_eye_bottom", "left_eye_center",
        "right_eye_left_corner", "right_eye_top", "right_eye_right_corner", "right_eye_bottom", "right_eye_center",
        
        "nose_contour_left1", "nose_contour_left2", "nose_left", "nose_contour_left3", "nose_contour_lower_middle",
        "nose_contour_right3", "nose_right", "nose_contour_right2", "nose_contour_right1", "nose_tip",
        
        "mouth_left_corner", "mouth_upper_lip_top", "mouth_right_corner", "mouth_lower_lip_bottom"
    ]

    private func setupGL() {
        context = EAGLContext(api: .openGLES3)
        EAGLContext.setCurrent(context)
        effect = GLKBaseEffect()
        if let view = self.view as? GLKView, let context = context {
            view.context = context
        }

    }

    func setupViewSize() {
        width = (mainImage?.image_width)!
        height = (mainImage?.image_height)!
        let rectRadius = (width >= height ? width : height) / 2
        effect?.transform.projectionMatrix = GLKMatrix4MakeOrtho(-rectRadius, rectRadius, -rectRadius, rectRadius, -1, 1)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.isOpaque = false
        mainImage = ImageMesh(vd: 15, hd: 22)
        setupGL()
    }

    var isSetup = false

    func setupImage(image: UIImage, width: CGFloat, height: CGFloat, original_vertices: [float2], target_vertices: [float2]) {
        let _ = mainImage?.loadImage(image: image, width: width, height: height)
        setupViewSize()
        let count = target_vertices.count
        var p = original_vertices
        // 转换坐标系
        for i in 0..<count {
            p[i] = [p[i].x - Float(image.size.width / 2), Float(image.size.height / 2) - p[i].y]
            p[i] = [p[i].x * Float(width) / Float(image.size.width), p[i].y * Float(height) / Float(image.size.height)]
        }

//        let q = target_vertices
        let q = p;
        var w = [Float](repeating: 0.0, count: count)
        
        // 计算变形权重
        for i in 0..<(self.mainImage?.numVertices)! {
            var ignore = false
            for j in 0..<count {
                let distanceSquare = ((self.mainImage?.ixy![i])! - p[j]).squaredNorm()
                if distanceSquare < 10e-6 {
                    self.mainImage?.xy![i] = p[j]
                    ignore = true
                }

                w[j] = 1 / distanceSquare
            }

            if ignore {
                continue
            }

            var pcenter = vector_float2()
            var qcenter = vector_float2()
            var wsum: Float = 0.0
            for j in 0..<count {
                wsum += w[j]
                pcenter += w[j] * p[j]
                qcenter += w[j] * q[j]
            }

            pcenter /= wsum
            qcenter /= wsum

            var ph = [vector_float2](repeating: [0.0, 0.0], count: count)
            var qh = [vector_float2](repeating: [0.0, 0.0], count: count)
            for j in 0..<count {
                ph[j] = p[j] - pcenter
                qh[j] = q[j] - qcenter
            }
            
            // 开始矩阵变换
            var M = matrix_float2x2()
            var P: matrix_float2x2? = nil
            var Q: matrix_float2x2? = nil
            var mu: Float = 0.0
            for j in 0..<count {
                P = matrix_float2x2([ph[j][0], ph[j][1]], [ph[j][1], -ph[j][0]])
                Q = matrix_float2x2([qh[j][0], qh[j][1]], [qh[j][1], -qh[j][0]])
                M += w[j] * Q! * P!
                mu += w[j] * ph[j].squaredNorm()
            }

            self.mainImage?.xy![i] = M * ((self.mainImage?.ixy![i])! - pcenter) / mu;
            self.mainImage?.xy![i] = ((self.mainImage?.ixy![i])! - pcenter).norm() * ((self.mainImage?.xy![i])!).normalized() + qcenter;
        }

        self.mainImage?.deform()

        isSetup = true
    }


    @IBAction func deform(_ sender: Any) {
        mainImage?.initialize()
    }

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        // 透明背景
        glClearColor(0.0, 0.0, 0.0, 0.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))

        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA));
        glEnable(GLenum(GL_BLEND));

        if (isSetup) {
            renderImage()
        }
    }

    func renderImage() {
        self.effect?.texture2d0.name = (mainImage?.texture?.name)!
        self.effect?.texture2d0.enabled = GLboolean(truncating: true)
        self.effect?.prepareToDraw()

        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.texCoord0.rawValue))

        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 8, mainImage?.verticesArr)
        glVertexAttribPointer(GLuint(GLKVertexAttrib.texCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 8, mainImage?.textureCoordsArr)

        for i in 0..<(mainImage?.verticalDivisions)! {
            glDrawArrays(GLenum(GL_TRIANGLE_STRIP), GLint(i * (self.mainImage!.horizontalDivisions * 2 + 2)), GLsizei(self.mainImage!.horizontalDivisions * 2 + 2))
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        if self.isViewLoaded && self.view.window != nil {
            self.view = nil

            self.tearDownGL()

            if EAGLContext.current() === self.context {
                EAGLContext.setCurrent(nil)
            }
            self.context = nil
        }
    }

    func tearDownGL() {
        EAGLContext.setCurrent(self.context)
        self.effect = nil
    }
}
