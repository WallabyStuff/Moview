//
//  UIViewController+Preview.swift
//  Moview
//
//  Created by 이승기 on 2023/10/08.
//

#if DEBUG
import UIKit
import SwiftUI


extension UIViewController {
  private struct Preview: UIViewControllerRepresentable {
    let viewController: UIViewController
    
    func makeUIViewController(context: Context) -> UIViewController {
      return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
  }
  
  public func toPreview() -> some View {
    Preview(viewController: self)
  }
}
#endif
