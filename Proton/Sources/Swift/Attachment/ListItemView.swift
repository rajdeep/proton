//
//  ListItemImageView.swift
//  
//
//  Created by polaris dev on 2023/6/6.
//

import UIKit

enum ListItemViewType {
    case image(UIImage, Bool)
    case text(NSAttributedString, CGRect)
}

public struct ListItemModel {
    public let range: NSRange
    public let selected: Bool
}

public let checklistTapKey = Notification.Name("ChecklistTap")

class ListItemView: UIView {
    
    var checked: Bool = false
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    lazy var textLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setUp()
    }
    
    func update(with image: UIImage) {
        imageView.image = image
    }
    
    func render(with type: ListItemViewType, attrValue: String) {
        self.isUserInteractionEnabled = attrValue == "listItemCheckList" || attrValue == "listItemSelectedChecklist"
        switch type {
        case let .image(image, checked):
            textLabel.isHidden = true
            imageView.isHidden = false
            self.checked = checked
            switch image.renderingMode {
            case .alwaysTemplate:
                imageView.tintColor = .white
                imageView.image = image
            default:
                imageView.tintColor = .clear
                if #available(iOS 13.0, *), attrValue == "listItemBullet" {
                    imageView.image = image.withRenderingMode(.alwaysOriginal).withTintColor(UIColor(hex: "#001C30")!)
                } else {
                    imageView.image = image
                }
            }
            imageView.frame = CGRect(x: frame.midX - image.size.width / 2, y: (frame.height - image.size.height) / 2, width: image.size.width, height: image.size.height)
        case let .text(attr, rect):
            textLabel.attributedText = attr
            let markerSize = attr.boundingRect(with: CGSize(width: 24, height: rect.height), options: [], context: nil).size
            textLabel.frame = CGRect(x: (frame.width - markerSize.width) / 2, y: (frame.height - rect.height) / 2, width: markerSize.width, height: rect.height)
            textLabel.isHidden = false
            imageView.isHidden = true
        }
    }
    
    private func setUp() {
        addSubview(imageView)
        addSubview(textLabel)
        imageView.frame = CGRect(x: 8, y: 8, width: 16, height: 16)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true
    }
    
    @objc func tapAction() {
        checked.toggle()
        if let richView = self.superview as? RichTextView {
            let location = CGPoint(x: 30, y: frame.midY)
            if let characterRange = richView.rangeOfCharacter(at: location), (characterRange.location + 1) < richView.contentLength {
                let location: Int
                if richView.attributedText.substring(from: NSRange(location: characterRange.location, length: 1)) == ListTextProcessor.blankLineFiller {
                    location = characterRange.location
                } else {
                    location = characterRange.location + 1
                }
                if location < richView.contentLength, let lineRange = currentLine(on: richView, at: location) {
                    let range = lineRange
                    let item = ListItemModel(range: range, selected: checked)
                    NotificationCenter.default.post(name: checklistTapKey, object: item)
                } else {
                    NotificationCenter.default.post(name: checklistTapKey, object: ListItemModel(range: NSRange(location: richView.contentLength, length: 0), selected: checked))
                }
            }
        }
    }
    
    private func currentLine(on textView: RichTextView, at location: Int) -> NSRange? {
        guard textView.contentLength > location else { return nil }
        var loc = location
        while loc < textView.contentLength {
            if textView.attributedText.substring(from: NSRange(location: loc, length: 1)) == "\n" {
                loc += 1
                break
            }
            loc += 1
        }
        return NSRange(location: location, length: loc - location)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension UIView {
    func toImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            return image
        }
        
        return nil
    }
}

extension UIColor {
    convenience init?(hex: String, alpha: CGFloat = 1) {
        let characterSet = CharacterSet.whitespacesAndNewlines
        var string = hex.trimmingCharacters(in: characterSet).uppercased()
        
        if string.count < 6 {
            return nil
        }

        if string.hasPrefix("0X") {
            let ns = string as NSString
            string = ns.substring(from: 2)
        }
        if string.hasPrefix("#") {
            let ns = string as NSString
            string = ns.substring(from: 1)
        }

        let r, g, b, a: CGFloat

        let hexColor = string

        if hexColor.count == 8 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0

            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                a = CGFloat(hexNumber & 0x000000ff) / 255

                self.init(red: r, green: g, blue: b, alpha: a)
                return
            }
        } else if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0

            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat((hexNumber & 0x0000ff)) / 255

                self.init(red: r, green: g, blue: b, alpha: alpha)
                return
            }
        }

        return nil
    }
}
