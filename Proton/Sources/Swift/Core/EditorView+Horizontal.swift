//
//  File.swift
//  
//
//  Created by polaris dev on 2023/7/6.
//

import UIKit

public enum HorizontalLineStyle {
    case normal
    case dash
}

public struct HorizontalLine {
    public let lineColor: UIColor
    public let lineStyle: HorizontalLineStyle
    public let lineSpacing: CGFloat
    public let lineWidth: CGFloat
    
    public init(lineColor: UIColor, lineStyle: HorizontalLineStyle, lineSpacing: CGFloat, lineWidth: CGFloat) {
        self.lineColor = lineColor
        self.lineStyle = lineStyle
        self.lineSpacing = lineSpacing
        self.lineWidth = lineWidth
    }
}

private var horizontalLineStyleKey: UInt8 = 0
private var horizontalShapeLayerKey: UInt8 = 0

public extension EditorView {
    
    var horizontalLineStyle: HorizontalLine? {
        get {
            return objc_getAssociatedObject(self, &horizontalLineStyleKey) as? HorizontalLine
        }
        
        set {
            objc_setAssociatedObject(self, &horizontalLineStyleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if newValue == nil {
                horizontalShapeLayer?.removeFromSuperlayer()
                horizontalShapeLayer = nil
            } else {
                self.drawHorizontalLines()
            }
        }
    }
    
    var horizontalShapeLayer: CAShapeLayer? {
        get {
            return objc_getAssociatedObject(self, &horizontalShapeLayerKey) as? CAShapeLayer
        }
        
        set {
            objc_setAssociatedObject(self, &horizontalShapeLayerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func drawHorizontalLines() {
        if horizontalShapeLayer == nil {
            horizontalShapeLayer = CAShapeLayer()
            self.richTextView.layer.insertSublayer(horizontalShapeLayer!, at: 0)
        }

        guard let horizontalShapeLayer else { return }
        
        let textView = self.richTextView
        guard let horizontalLineStyle = self.horizontalLineStyle else {
            return
        }
        
        let path = UIBezierPath()
        
        let lineHeight = horizontalLineStyle.lineSpacing
        let lineSpacing = horizontalLineStyle.lineSpacing
        let numberOfLines = Int(textView.contentSize.height / lineHeight + 1)
        
        let originY = self.textContainerInset.top
        for i in 1..<numberOfLines {
            let lineY = originY + lineHeight * CGFloat(i) + lineSpacing
            path.move(to: CGPoint(x: textView.textContainerInset.left, y: lineY))
            path.addLine(to: CGPoint(x: textView.bounds.width - textView.textContainerInset.right, y: lineY))
        }
        
        horizontalShapeLayer.path = path.cgPath
        horizontalShapeLayer.lineWidth = horizontalLineStyle.lineWidth
        horizontalShapeLayer.lineDashPattern = [2, 1]
        horizontalShapeLayer.strokeColor = horizontalLineStyle.lineColor.cgColor
    }
    
}
