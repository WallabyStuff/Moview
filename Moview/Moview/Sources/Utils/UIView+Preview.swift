//
//  UIView+Preview.swift
//  Moview
//
//  Created by 이승기 on 2023/10/08.
//

#if DEBUG
import UIKit
import SwiftUI


public struct UIViewPreview<View: UIView>: UIViewRepresentable {
  public let view: View
  public init(_ builder: @escaping () -> View) {
    view = builder()
  }
  
  public func makeUIView(context: Context) -> UIView {
    return view
  }
  
  public func updateUIView(_ view: UIView, context: Context) {
    view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    view.setContentHuggingPriority(.defaultHigh, for: .vertical)
  }
}
#endif
