/// Copyright (c) 2019 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import Firebase

// Detecting Frames

struct ScaledElement {
    let frame: CGRect
    let shapeLayer: CALayer
}

// Creating a Text Detector

class ScaledElementProcessor {
    
    let vision = Vision.vision()
    
    // the main object to detect text in images
    var textRecognizer: VisionTextRecognizer!
    
//    let options = VisionCloudTextRecognizerOptions()
    
    init() {
//        options.languageHints = ["en", "ko"]
//        textRecognizer = vision.cloudTextRecognizer(options: options)
        textRecognizer = vision.onDeviceTextRecognizer()
    }
    
    func process(
        in imageView: UIImageView,
        callback: @escaping (_ text: String, _ scaledElements: [ScaledElement]) -> Void
        ) {
        // 1.
        guard let image = imageView.image else { return }
        // 2.
        let visionImage = VisionImage(image: image)
        // 3.
        textRecognizer.process(visionImage) { (result, error) in
            // 4.
            guard error == nil,
                let result = result,
                !result.text.isEmpty
                else {
                    callback("", [])
                    return
            }
            
            // detecting frames
            
            var scaledElements: [ScaledElement] = []
            
            for block in result.blocks {
                for line in block.lines {
                    for element in line.elements {
                        let frame = self.createScaledFrame(featureFrame: element.frame, imageSize: image.size, viewFrame: imageView.frame)
                        
                        let shapeLayer = self.createShapeLayer(frame: frame)
                        let scaledElement = ScaledElement(frame: frame, shapeLayer: shapeLayer)
                        
                        scaledElements.append(scaledElement)
                    }
                }
            }
            
            callback(result.text, scaledElements)
        }
    }
    
    

    // MARK: - private
    
    private func createShapeLayer(frame: CGRect) -> CAShapeLayer {
        // 1.
        let bpath = UIBezierPath(rect: frame)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = bpath.cgPath
        // 2.
        shapeLayer.strokeColor = Constants.lineColor
        shapeLayer.fillColor = Constants.fillColor
        shapeLayer.lineWidth = Constants.lineWidth
        
        return shapeLayer
    }
    
    //3.
    private enum Constants {
        static let lineWidth: CGFloat = 3.0
        static let lineColor = UIColor.yellow.cgColor
        static let fillColor = UIColor.clear.cgColor
    }
    
    
    // Calculating the Scale
    
    private func createScaledFrame(
        featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect) -> CGRect {
        
        let viewSize = viewFrame.size
        
        let resolutionView = viewSize.width / viewSize.height
        let resolutionImage = imageSize.width / imageSize.height
        
        var scale: CGFloat
        if resolutionView > resolutionImage {
            scale = viewSize.height / imageSize.height
        } else {
            scale = viewSize.width / imageSize.width
        }
        
        let featureWidthScaled = featureFrame.size.width * scale
        let featureHeightScaled = featureFrame.size.height * scale
        
        let imageWidthScaled = imageSize.width * scale
        let imageHeightScaled = imageSize.height * scale
        let imagePointXScaled = (viewSize.width - imageWidthScaled) / 2
        let imagePointYScaled = (viewSize.height - imageHeightScaled) / 2
        
        let featurePointXScaled = imagePointXScaled + featureFrame.origin.x * scale
        let featurePointYScaled = imagePointYScaled + featureFrame.origin.y * scale
        
        return CGRect(x: featurePointXScaled,
                      y: featurePointYScaled,
                      width: featureWidthScaled,
                      height: featureHeightScaled)
    }
}
