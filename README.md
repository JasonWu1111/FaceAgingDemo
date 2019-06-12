# 人脸变老实现
自己实现的一个人脸变老的方案，项目代码和算法相关均由 **Swift** 实现，最终的效果图如下：

![](https://user-gold-cdn.xitu.io/2019/6/10/16b4149fa9c71fb6?w=737&h=324&f=jpeg&s=35899)

本方案的实现步骤分为以下三步：
- 1、识别图片中的人脸区域并提取人脸特征点
- 2、根据人脸特征点来对皱纹纹理的各区域进行复杂变形
- 3、将变形后的皱纹纹理自然的贴合在原图识别出的人脸区域上  

本人提出的方案，优点在于不用考虑原图人脸的肤色、亮度等因素，一张预制的皱纹脸皮即可适用于大多数的人的图片，缺点则在于变老的效果仅体现在于有更多的“皱纹”，整体效果离真实变老有不少的差距。

在方案的实现上，使用了 Swfit 语言在 iOS 端实现，不过其中涉及的 Opengl 以及相关算法都能够轻松的在 Android 等其他平台复现，基于人脸特征点的 mls 变形算法还能够用来实现更多的功能，譬如美颜瘦脸、大眼、换装等，拓展性高。

方案流程的详细说明已发布到掘金：  
- [【干货】开源一个人脸变老方案实现（Swift）](https://juejin.im/post/5cfb84e66fb9a07efd46ff77)

