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
    
    private var checked: Bool = false
    
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
    
    func render(with type: ListItemViewType) {
        switch type {
        case let .image(image, checked):
            textLabel.isHidden = true
            imageView.isHidden = false
            self.checked = checked
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
            if let characterRange = richView.rangeOfCharacter(at: location) {
                if (characterRange.location + 1) < richView.contentLength, let lineRange = richView.lineRange(from: characterRange.location + 1) {
                    let item = ListItemModel(range: lineRange, selected: checked)
                    NotificationCenter.default.post(name: checklistTapKey, object: item)
                } else {
                    NotificationCenter.default.post(name: checklistTapKey, object: ListItemModel(range: NSRange(location: richView.contentLength, length: 0), selected: checked))
                }
            }
        }
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
