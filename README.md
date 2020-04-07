# Proton

> **Note:** While Proton is already a very powerful and flexible framework, it is still in early stages of development. The APIs and public interfaces are still undergoing revisions and may introduce breaking changes with every version bump before reaching stable version 1.0.0. 

Proton is a simple library that allows you to extend the behavior of a textview to add rich content that you always wanted. It provides simple API that allows you to extend the textView to include complex content like nested textViews or for that matter, any other UIView. In the simplest terms - It's what you always wanted `UITextView` to be.

Proton is designed keeping the following requirements in mind:

* Be a standalone component with nothing that is specific to anything that is required in complex Text Editor. At it's most basic form, it should be able to be used as a UITextView and in most complex form, it should be able to provide rich text editing capabilities which are beyond just text formatting.
* Should be extensible to support adding any view as content in the Editor such that it flows with the text.
* Resizing of content views should automatically resize the containing Editor and support this to nth nesting level.
* Should support extending the appearance of text as the content is typed - for e.g. changing text as it is typed using mark-up syntax and yet, not be aware of any of these requirements directly.
* Should allow for working on multiple editors through the same toolbar based on where the focus is, and yet not be aware of the toolbar itself.
* Respect the bounds of the container i.e. resize to change bounds when the device orientation changes.
* Support a default font and styling like alignment and head indentation.
* Have a Native Renderer based on the Editor similar to analogy of `UITextView` and `UILabel`.
* And of course, support all this on macOS as well with almost no additional effort.

## Core Concepts

At it's core, Proton constitutes of following key components:

* **EditorView:** A substitute for `UITextView` that can be extended to add custom views including other EditorViews.
* **TextProcessor:** Allows you to inject a behavior that is invoked as you type text in the EditorView. This can be used to change text, add/remove attributes like color or replace the added text with an entirely different text/view. For e.g. as you type markup syntax, you can convert the markup text into a formatted text by adding corresponding behavior to the `TextProcessor`.
* **EditorCommand:** Allows you to add a behavior that can be invoked on demand on the given EditorView. For e.g. selecting some text and making it bold.
* **Attachment:** A container capable of hosting a custom view including another `EditorView`. Attachment is a supercharged `NSTextAttachment` that can have automatic constraints applied on it to size it in various configurations like matching content, range of width, fixed width and so on. It also has helper functions to get it's range in it's container as well as to remove itself from the container.
* **RendererView:** Composes `EditorView` to provide a read-only behavior with an API that is suited for rendering the content.
* **RendererCommand:** Similar to `EditorCommand` but works on a `RendererView`.

## A practical use case

The power of `EditorView` to host rich content is made possible by the use of `Attachment` which allows hosting any `UIView` in the `EditorView`. This is further enhanced by use of `TextProcessor` and `EditorCommand` to add interactive behavior to the editing experience.

Let's take an example of a `TextPanel` and see how that can be created in the `EditorView`. Following are the key requirements for a `TextPanel`:

1. A text block that is indented and has a custom UI besides the `Editor`.
2. Change height based on the content being typed.
3. Have a different font color than the main text.   
4. Able to be inserted using a button.
5. Able to be inserted by selecting text and clicking a button.
6. Able to be inserted in a given Editor by use of `>> ` char.
7. Nice to have: delete using `backspace` key when empty similar to a `Blockquote`.

### TextPanel view

1. The first thing that is required is to create a view that represents the `TextPanel`. Once we have created this view, we can add it to an attachment and insert it in the `EditorView`.

   ``` Swift
   extension EditorContent.Name {
       static let panel = EditorContent.Name("panel")
   }

   class PanelView: UIView, BlockContent, EditorContentView {
       let container = UIView()
       let editor: EditorView
       let iconView = UIImageView()

       var name: EditorContent.Name {
           return .panel
       }

       override init(frame: CGRect) {
           self.editor = EditorView(frame: frame)
           super.init(frame: frame)

           setup()
       }

       var textColor: UIColor {
           get { editor.textColor }
           set { editor.textColor = newValue }
       }

       override var backgroundColor: UIColor? {
           get { container.backgroundColor }
           set {
               container.backgroundColor = newValue
               editor.backgroundColor = newValue
           }
       }

       private func setup() {
           // setup view by creating required constraints
       }
   }
   ```

2. Since the `Panel` contains an `Editor` inside itself, the height will automatically change based on the content as it is typed in. To restrict the height to a given maximum value, an absolute size or autolayout constraint may be used.
3. Using the `textColor` property, the default font color may be changed.
4. For the ability to add `Panel` to the `Editor` using a button, we can make use of `EditorCommand`. A `Command` can be executed on a given `EditorView` or via `CommandExecutor` that automatically takes care of executing the command on the focussed `EditorView`. To insert an `EditorView` inside another, we need to first create an `Attachment` and then used a `Command` to add to the desired position:

   ```Swift

   class PanelAttachment: Attachment {
       var view: PanelView

       init(frame: CGRect) {
           view = PanelView(frame: frame)
           super.init(view, size: .fullWidth)
           view.delegate = self
           view.boundsObserver = self
       }

       var attributedText: NSAttributedString {
           get { view.attributedText }
           set { view.attributedText = newValue }
       }   
   }

   class PanelCommand: EditorCommand {
       func execute(on editor: EditorView) {
           let selectedText = editor.selectedText

           let attachment = PanelAttachment(frame: .zero)
           attachment.selectBeforeDelete = true
           editor.insertAttachment(in: editor.selectedRange, attachment: attachment)

           let panel = attachment.view
           panel.editor.maxHeight = 300
           panel.editor.replaceCharacters(in: .zero, with: selectedText)
           panel.editor.selectedRange = panel.editor.textEndRange
       }
   }
   ```

5. The code in `PanelCommand.execute` reads the `selectedText` from `editor` and sets it back in `panel.editor`. This makes it possible to take the selected text from main editor, wrap it in a panel and then insert the panel in the main editor replacing the selected text.
6. To allow insertion of a `Panel` using a shortcut text input instead of clicking a button, you can use a `TextProcessor`:
   ```Swift
   class PanelTextProcessor: TextProcessing {

    private let trigger = ">> "
    var name: String {
        return "PanelTextProcessor"
    }

    var priority: TextProcessingPriority {
        return .medium
    }

    func process(editor: EditorView, range editedRange: NSRange, changeInLength delta: Int, processed: inout Bool) {
        let line = editor.currentLine
        guard line.text.string == trigger else {
            return
        }
        let attachment = PanelAttachment(frame: .zero)
        attachment.selectBeforeDelete = true        
        editor.insertAttachment(in: line.range, attachment: attachment)
    }
   ```
7. For a requirement like deleting the `Panel` when backspace is tapped at index 0 on an empty Panel, `EdtiorViewDelegate` may be utilized:
    
    ```swift
    extension PanelAttachment: PanelViewDelegate {
    
    func panel(_ panel: PanelView, didReceiveKey key: EditorKey, at range: NSRange, handled: inout Bool) {
        if key == .backspace, range == .zero, panel.editor.attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            removeFromContainer()
            handled = true
            } 
        }
    }    
    ```
    In the code above, `PanelViewDelegate` is acting as a passthrough for `EditorViewDelegate` for the `Editor` inside the `PanelView`.

Checkout the complete code in the ExamplesApp.

## Questions and feature requests
Feel free to create issues in github should you have any questions or feature requests. While Proton is created as a side project, I'll endeavour to respond to your issues at earliet possible. 
