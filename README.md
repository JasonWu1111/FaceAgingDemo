# 人脸变老实现
自己实现的一个人脸变老的方案，项目代码和算法相关均由 **Swift** 实现，
完整的 Demo 代码会附在本文末尾，最终的效果图如下：

![](https://user-gold-cdn.xitu.io/2019/6/10/16b4149fa9c71fb6?w=737&h=324&f=jpeg&s=35899)

该方案实现的原理是将一张**预制作好的皱纹纹理**“贴在”原图的人脸区域上，听起来很简单，不过在具体实现上则需要考虑不少问题，让我们从后往前去推导哪些要需要解决的问题：首先，预制作好的皱纹纹理如何和原图中的人脸**自然的贴合**？考虑到不同原图中的人脸肤色和亮度会有很大的差异，如果针对不同的肤色来提供不同的皱纹纹理显然是不可行的。其次，预制好的皱纹纹理的五官区域明显是和原图中的人脸不符合，那么就需要针对不同的人脸特征点来对皱纹纹理进行**复杂变形**。考虑到以上种种，本方案的实现步骤分为以下三步：
- 1、识别图片中的人脸区域并提取人脸特征点
- 2、根据人脸特征点来对皱纹纹理的各区域进行复杂变形
- 3、将变形后的皱纹纹理自然的贴合在原图识别出的人脸区域上  

让我们一步步来实现：

## 识别人脸关键点
这一步的实现方案比较简单，借助的是 [Face++](https://www.faceplusplus.com.cn/) 平台的技术实现，只需要简单的申请注册就可以免费使用人脸识别功能，客户端只需要上传图片调用相关的Api即可，返回的人脸识别特征点信息大致如下图所示（图片源自Face++）：
![Face++](https://user-gold-cdn.xitu.io/2019/6/8/16b367f3946133ad?w=635&h=664&f=png&s=555963)

## 对皱纹纹理进行变形处理
### 提取皱纹纹理特征点坐标
变形前需要先获取皱纹纹理上对应的人脸特征点坐标，由于皱纹纹理是提前准备的，所以可以直接通过[获取图片点坐标工具](https://www.mobilefish.com/services/record_mouse_coordinates/record_mouse_coordinates.php)来提取特性点坐标数据：
![](https://user-gold-cdn.xitu.io/2019/6/10/16b414dbf001aa26?w=665&h=516&f=jpeg&s=43190)

### 变形算法实现
考虑到这是基于特征点的复杂变形，所以皱纹纹理图片的渲染选择了用 [OpenGL](https://www.opengl.org/)，iOS SDK 提供了封装好的 [GLKit](https://developer.apple.com/documentation/glkit) 来方便使用 OpenGL ，只需要创建一个 ``GLKViewController``:
![](https://user-gold-cdn.xitu.io/2019/6/8/16b369cd46e05f42?w=756&h=567&f=png&s=103758)
然后重写 ``glkView`` 方法：
```swift
import UIKit
import GLKit
class FaceGLKViewController: GLKViewController {
    ···
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        ···
    }
    ···
}
```
&nbsp;
新建一个 ``ImageMesh`` 类，用来记录皱纹纹理内坐标网格点信息：
```swift
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
    ···
}
```
然后调用 Opengl Api 完成渲染工作：
```swift
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
```
接下来是实现基于关键点的变形，变形的算法实现是根据 [Image Deformation Using Moving Least Squares](http://faculty.cs.tamu.edu/schaefer/research/mls.pdf) 论文来编写的，论文的内容和推导过程比较简洁，侧重于给出最终的数学公式，有兴趣的可以去详读。为了方便，本方案用 Swift 来实现该算法。以皱纹纹理上的特征点作为变形原点， Face++ 返回的人脸特征点作为变形目标点，对皱纹纹理进行变形：
```swift
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

    let q = target_vertices
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
```
最终得到变形后的皱纹纹理如下：
![](https://user-gold-cdn.xitu.io/2019/6/10/16b414bf417b46d6?w=1006&h=372&f=jpeg&s=34829)
## 皱纹纹理与人脸“贴合”
直接将皱纹纹理覆盖在人脸上显然是不可取的，我们要做的是将人脸原图和皱纹纹理进行适当的**图片混合**。

图片混合常用的模式有很多种，如叠加、柔光、强光等，各混合模式的算法实现起来也都比较简单，具体的算法公式可以看这篇知乎总结：[Photoshop图层混合模式计算公式大全](https://www.zhihu.com/question/20293077)。更方便的是 CGContext 内置了这些常用的混合模式的实现，可以直接通过 ``UIImage#draw`` 方法 调用，本人测试下来，**柔光混合**（soft light blend mode）的效果是最为理想：
```swift
/// 人脸变老
///
/// - Parameters:
///   - face: 人脸图片
///   - wrinkle: 皱纹纹理图片
///   - faceRect: 人脸区域
/// - Returns: 合成结果
func softlightMerge(face: UIImage, wrinkle: UIImage, faceRect: CGRect) -> UIImage? {
    let rendererRect = CGRect(x: 0, y: 0, width: face.size.width, height: face.size.height)
    let renderer = UIGraphicsImageRenderer(bounds: rendererRect)
    let outputImage = renderer.image { ctx in
        UIColor.white.set()
        ctx.fill(rendererRect)
        face.draw(in: rendererRect, blendMode: .normal, alpha: 1)
        // 柔光混合
        wrinkle.draw(in: faceRect, blendMode: .softLight, alpha: 1)
    }
    return outputImage
}
```
经过柔光混合，无需考虑原图人脸的肤色如何，混合后的人脸会保持原肤色，最后的效果如下：
![](https://user-gold-cdn.xitu.io/2019/6/10/16b4123a02d27caa?w=773&h=322&f=jpeg&s=36800)

## 总结
实现人脸变老的方案有很多，本人提出的方案，优点在于不用考虑原图人脸的肤色、亮度等因素，一张预制的皱纹脸皮即可适用于大多数的人的图片，缺点则在于变老的效果仅体现在于有更多的“皱纹”，整体效果离真实变老有不少的差距。

在方案的实现上，使用了 Swfit 语言在 iOS 端实现，不过其中涉及的 Opengl 以及相关算法都能够轻松的在 Android 等其他平台复现，基于人脸特征点的 mls 变形算法还能够用来实现更多的功能，譬如美颜瘦脸、大眼、换装等，拓展性高。
