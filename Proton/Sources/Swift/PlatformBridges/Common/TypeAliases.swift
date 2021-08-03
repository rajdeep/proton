//
//  TypeAliases.swift
//  TypeAliases
//
//  Created by Michał Śmiałko on 03/08/2021.
//

import Foundation

#if os(iOS)
import UIKit
public typealias PlatformColor = UIColor
public typealias FontDescriptor = UIFontDescriptor
public typealias PlatformFont = UIFont
public typealias NativeView = UIView
public typealias PlatformView = UIView
public typealias PlatformTextView = UITextView
public typealias EdgeInsets = UIEdgeInsets
public typealias PlatformImage = UIImage
public typealias PlatformImageView = UIImageView
public typealias GestureRecognizer = UIGestureRecognizer
public typealias BezierPath = UIBezierPath
public typealias KeyModifierFlags = UIKeyModifierFlags
public typealias PlatformLabel = UILabel
public typealias TextStorageEditAcitons = NSTextStorage.EditActions
public typealias TextAttachment = NSTextAttachment
public typealias TextContentType = UITextContentType
public typealias RectCorner = UIRectCorner
public typealias PlatformViewController = UIViewController
#else

import AppKit
public typealias PlatformColor = NSColor
public typealias FontDescriptor = NSFontDescriptor
public typealias PlatformFont = NSFont
public typealias NativeView = NSView
public typealias EdgeInsets = NSEdgeInsets
public typealias PlatformImage = NSImage
public typealias PlatformImageView = NSImageView
public typealias GestureRecognizer = NSGestureRecognizer
public typealias BezierPath = NSBezierPath
public typealias PlatformLabel = NSLabel
public typealias TextStorageEditAcitons = NSTextStorageEditActions
public typealias TextAttachment = NSTextAttachment
public typealias TextContentType = NSTextContentType
public typealias RectCorner = NSRectCorner
public typealias PlatformViewController = NSViewController
#endif

public typealias ParagraphStyle = NSParagraphStyle
public typealias MutableParagraphStyle = NSMutableParagraphStyle
public typealias UnderlineStyle = NSUnderlineStyle
public typealias PlatformTextContainer = NSTextContainer
