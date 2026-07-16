
import UIKit

class FilterClass {
    
    let slices = 19
    
    var image = UIImage()
    
    init(image: UIImage) {
        self.image = image
    }
    
    func getImageFilter() -> UIImage? {
        let width = image.size.width
        let height = image.size.height
        let sliceWidth = width / CGFloat(slices)
        
        var array: [UIImage] = []
        
        for index in 0...(slices - 1) {
            let x = CGFloat(index) * sliceWidth
            let rect = CGRect(x: x, y: 0, width: sliceWidth, height: height)
            
            if let cgImage = image.cgImage, let slice = cgImage.cropping(to: rect) {
                let imageSlice = UIImage(cgImage: slice)
                array.append(imageSlice)
            }
        }
        array = getReorderArray(array: array)
        
        UIGraphicsBeginImageContext(image.size)
        
        for (index, each) in array.enumerated() {
            let x = CGFloat(index) * sliceWidth
            let point = CGPoint(x: x, y: 0)
            each.draw(at: point)
        }
        let watermark = UIImage(named: "icon_watermark")
        let rect = getWatermarkRect()
        watermark?.draw(in: rect)
        
        let filteredImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return filteredImage
    }
    
    func getReorderArray(array: [UIImage]) -> [UIImage] {
        var reorderedArray: [UIImage] = []
        
        for index in 0...(array.count - 1) {
            let slice = array[array.count - 1 - index]
            reorderedArray.append(slice)
        }
        return reorderedArray
    }
    
    func getWatermarkRect() -> CGRect {
        let width = image.size.width
        let height = image.size.height
        
        if width > height {
            let x = (width - height) / 2
            let rect = CGRect(x: x, y: 0, width: height, height: height)
            return rect
        } else {
            let y = (height - width) / 2
            let rect = CGRect(x: 0, y: y, width: width, height: width)
            return rect
        }
    }
}
