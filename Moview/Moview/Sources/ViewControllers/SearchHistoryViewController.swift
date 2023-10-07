//
//  SearchHistoryViewController.swift
//  Moview
//
//  Created by 이승기 on 2023/10/08.
//

import UIKit


final class SearchHistoryViewController: UIViewController {
  
  // MARK: - Constants
  
  enum Metric {
    static let celHeight = 56.f
  }
  
  
  // MARK: - Types
  
  typealias ViewModel = SearchHistoryViewModel
  
  
  // MARK: - Properties
  
  private let viewModel: ViewModel
  
  private var collectionViewLayout: UICollectionViewCompositionalLayout = {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .absolute(Metric.celHeight))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    
    let group = NSCollectionLayoutGroup.vertical(
      layoutSize: itemSize,
      subitems: [item])
    
    let section = NSCollectionLayoutSection(group: group)
    return .init(section: section)
  }()
  
  
  // MARK: - UI
  
  lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
  
  
  // MARK: - Initializers
  
  init(viewModel: SearchHistoryViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
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
    setupCollectionView()
  }
  
  private func setupBackground() {
    view.backgroundColor = R.color.backgroundBlack()!
  }
  
  private func setupCollectionView() {
    view.addSubview(collectionView)
    collectionView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    collectionView.backgroundColor = .white
  }
  
  
  // MARK: - Bindings
  
  private func bind() {
    
  }
}


// MARK: - Preview

import SwiftUI
struct SearchHistoryViewController_Preview: PreviewProvider {
  static var previews: some View {
    SearchHistoryViewController(viewModel: .init()).toPreview()
      .edgesIgnoringSafeArea(.all)
  }
}
