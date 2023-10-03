//
//  CollectionViewFooterLoadingView.swift
//  Moview
//
//  Created by Wallaby on 2023/03/08.
//

import UIKit
import SnapKit
import Then

class CollectionViewFooterLoadingView: UICollectionReusableView {
  
  // MARK: - Constants
  
  static let identifier = String(describing: CollectionViewFooterLoadingView.self)
  
  
  // MARK: - UI
  
  let loadingIndicatorView = UIActivityIndicatorView().then {
    $0.color = R.color.iconGray()
  }
  
  
  // MARK: - Initializers
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  // MARK: - Setups
  
  private func setup() {
    setupView()
  }
  
  private func setupView() {
    setupBackground()
    setupLoadingIndicatorView()
  }
  
  private func setupBackground() {
    backgroundColor = .clear
  }
  
  private func setupLoadingIndicatorView() {
    addSubview(loadingIndicatorView)
    loadingIndicatorView.snp.makeConstraints {
      $0.center.equalToSuperview()
    }
  }
  
  
  // MARK: - Methods
  
  public func startLoading() {
    loadingIndicatorView.isHidden = false
    loadingIndicatorView.startAnimating()
  }
  
  public func stopLoading() {
    loadingIndicatorView.isHidden = true
    loadingIndicatorView.stopAnimating()
  }
}
