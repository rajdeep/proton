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
            default:
                imageView.tintColor = .clear
            }
            imageView.image = image
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
