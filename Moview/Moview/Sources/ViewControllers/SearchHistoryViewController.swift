//
//  SearchHistoryViewController.swift
//  Moview
//
//  Created by 이승기 on 2023/10/08.
//

import UIKit

import Then
import SnapKit

import RxSwift
import RxCocoa
import RxDataSources


final class SearchHistoryViewController: UIViewController {
  
  // MARK: - Constants
  
  enum Metric {
    static let celHeight = 56.f
    static let collectionViewVerticalInset = 28.f
  }
  
  
  // MARK: - Types
  
  typealias ViewModel = SearchHistoryViewModel
  
  
  // MARK: - Properties
  
  private let viewModel: ViewModel
  private var disposeBag = DisposeBag()
  
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
  
  private lazy var searchHistoryCollectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout).then {
    $0.register(SearchHistoryCollectionCell.self,
                forCellWithReuseIdentifier: SearchHistoryCollectionCell.identifier)
    $0.alwaysBounceVertical = true
    $0.contentInset = .init(top: Metric.collectionViewVerticalInset,
                            left: 0,
                            bottom: Metric.collectionViewVerticalInset,
                            right: 0)
  }
  private let emptyStateLabel = UILabel().then {
    $0.font = .systemFont(ofSize: 17, weight: .semibold)
    $0.text = "Empty search history"
    $0.textColor = R.color.textGrayDarker()!
  }
  
  
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
    bind()
  }
  
  private func setupView() {
   setupBackground()
    setupCollectionView()
    setupEmptyStateLabel()
  }
  
  private func setupBackground() {
    view.backgroundColor = R.color.backgroundBlack()!
  }
  
  private func setupCollectionView() {
    view.addSubview(searchHistoryCollectionView)
    searchHistoryCollectionView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }
  
  private func setupEmptyStateLabel() {
    view.addSubview(emptyStateLabel)
    emptyStateLabel.snp.makeConstraints {
      $0.center.equalToSuperview()
    }
  }
  
  
  // MARK: - Bindings
  
  private func bind() {
    bindInputs()
    bindOutputs()
  }
  
  private func bindInputs() {
    rx.viewWillAppear
      .map { _ in }
      .bind(to: viewModel.input.viewWillAppear)
      .disposed(by: disposeBag)
    
    searchHistoryCollectionView.rx.didScroll
      .asDriver()
      .drive(with: self, onNext: { vc, _ in
        vc.view.endEditing(true)
      })
      .disposed(by: disposeBag)
    
    searchHistoryCollectionView.rx.itemSelected
      .bind(to: viewModel.input.selectItem)
      .disposed(by: disposeBag)
  }
  
  private func bindOutputs() {
    viewModel.output
      .searchHistories
      .bind(to: searchHistoryCollectionView.rx.items(cellIdentifier: SearchHistoryCollectionCell.identifier, cellType: SearchHistoryCollectionCell.self)) { index, item, cell in
        cell.configure(item) { [weak self] in
          self?.viewModel.deleteHistory(item)
        }
      }
      .disposed(by: disposeBag)
    
    viewModel.output
      .searchHistories
      .asDriver()
      .drive(with: self, onNext: { vc, histories in
        if histories.isEmpty {
          vc.emptyStateLabel.isHidden = false
        } else {
          vc.emptyStateLabel.isHidden = true
        }
      })
      .disposed(by: disposeBag)
  }
}


// MARK: - Preview

import SwiftUI
struct SearchHistoryView_Preview: PreviewProvider {
  static var previews: some View {
    SearchHistoryViewController(viewModel: .init()).toPreview()
      .edgesIgnoringSafeArea(.all)
  }
}
