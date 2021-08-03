//
//  NSBezierPath.swift
//  NSBezierPath
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation
#if os(macOS)
import AppKit

extension NSBezierPath {
    func addLine(to point: CGPoint) {
        line(to: point)
    }
    
    /// A `CGPath` object representing the current `NSBezierPath`.
    /// Credit: https://gist.github.com/juliensagot/9749c3a1df28c38fb9f9
    var cgPath: CGPath {
        let path = CGMutablePath()
        let points = UnsafeMutablePointer<NSPoint>.allocate(capacity: 3)
        
        if elementCount > 0 {
            var didClosePath = true
            
            for index in 0..<elementCount {
                let pathType = element(at: index, associatedPoints: points)
                
                switch pathType {
                case .moveTo:
                    path.move(to: points[0])
                case .lineTo:
                    path.addLine(to: points[0])
                    didClosePath = false
                case .curveTo:
                    path.addCurve(to: points[2], control1: points[0], control2: points[1])
                    didClosePath = false
                case .closePath:
                    path.closeSubpath()
                    didClosePath = true
                @unknown default:
                    break
                }
            }
            
            if !didClosePath { path.closeSubpath() }
        }
        
        points.deallocate()
        return path
    }
    
    convenience init(roundedRect rect: CGRect, byRoundingCorners corners: RectCorner, cornerRadii: CGSize) {
        // TODO: macOS
        fatalError()
    }
}

#endif
