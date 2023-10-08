//
//  SearchResultViewController.swift
//  Moview
//
//  Created by 이승기 on 2023/10/08.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources


final class SearchResultViewController: UIViewController {
  
  // MARK: - Constants
  
  enum Metric {
    static let estimatedSearchResultCellHeight = 150.f
    static let searchResultCollectionViewTopInset = 12.f
    static let searchResultCollectionViewBottomInset = 100.f
    
    static let pageLoadingFooterHeight = 100.f
    
    static let loadNextPageThreshold = 1000.f
  }
  
  
  // MARK: - Types
  
  typealias ViewModel = SearchResultViewModel
  
  
  // MARK: - Properties
  
  private var disposeBag = DisposeBag()
  private let viewModel: ViewModel
  
  // Datasources
  private var dataSource: RxCollectionViewSectionedAnimatedDataSource<MovieDataSection> {
    return .init(configureCell: { dataSource, collectionView, indexPath, item in
      guard let searchResultCell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchResultCollectionCell.identifier, for: indexPath) as? SearchResultCollectionCell else {
        return .init()
      }
      
      searchResultCell.configure(movie: item, thumbnailImageViewHeroId: item.id)
      return searchResultCell
    }, configureSupplementaryView: { section, collectionView, supplementaryType, indexPath in
      if supplementaryType == UICollectionView.elementKindSectionFooter {
        guard let loadingFooterView = collectionView.dequeueReusableSupplementaryView(
          ofKind: UICollectionView.elementKindSectionFooter,
          withReuseIdentifier: CollectionViewFooterLoadingView.identifier,
          for: indexPath) as? CollectionViewFooterLoadingView else {
          return .init()
        }
        
        loadingFooterView.stopLoading()
        return loadingFooterView
      }
      
      return .init()
    })
  }
  
  private var collectionViewLayout: UICollectionViewCompositionalLayout {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .estimated(Metric.estimatedSearchResultCellHeight))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    
    let group = NSCollectionLayoutGroup.vertical(
      layoutSize: itemSize,
      subitems: [item])
    
    let section = NSCollectionLayoutSection(group: group)
    // Footer view layout
    section.boundarySupplementaryItems = [
      .init(layoutSize: .init(
        widthDimension: .fractionalWidth(1),
        heightDimension: .absolute(Metric.pageLoadingFooterHeight)),
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom)
    ]
    
    let layout = UICollectionViewCompositionalLayout(section: section)
    return layout
  }
  
  
  // MARK: - UI
  
  private lazy var searchResultCollectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout).then {
    $0.register(SearchResultCollectionCell.self, forCellWithReuseIdentifier: SearchResultCollectionCell.identifier)
    $0.register(CollectionViewFooterLoadingView.self,
                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: CollectionViewFooterLoadingView.identifier)
  }
  private let searchResultPlaceholder = UILabel().then {
    $0.textColor = R.color.textGrayDarker()
  }
  
  
  // MARK: - Initializers
  
  init(viewModel: ViewModel) {
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
    setupSearchResultCollectionView()
    setupSearchResultPlaceholder()
  }
  
  private func setupSearchResultCollectionView() {
    /// Setup constraints
    view.addSubview(searchResultCollectionView)
    searchResultCollectionView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
//    /// Setup insets
//    searchResultCollectionView.contentInset = .init(
//      top: Metric.navigationViewHeight + Metric.searchResultCollectionViewTopInset,
//      bottom: Metric.searchResultCollectionViewBottomInset)
//    searchResultCollectionView.scrollIndicatorInsets = .init(
//      top: Metric.navigationViewHeight + Metric.searchResultCollectionViewTopInset)
//    
//    /// Configure navigation bar opaque threshold
//    navigationView.configureScrollView(
//      searchResultCollectionView,
//      threshold: Metric.navigationViewHeight + SafeAreaGuide.top)
    
    // Etc
    searchResultCollectionView.delaysContentTouches = false
  }
  
  private func setupSearchResultPlaceholder() {
    view.addSubview(searchResultPlaceholder)
    searchResultPlaceholder.snp.makeConstraints {
      $0.centerX.centerY.equalToSuperview()
    }
  }
  
  
  // MARK: - Binding
  
  private func bind() {
    bindInputs()
    bindOutputs()
  }
  
  private func bindInputs() {
    searchResultCollectionView.rx.didScroll
      .subscribe(with: self, onNext: { vc, _  in
        vc.view.endEditing(true)
      })
      .disposed(by: disposeBag)
    
    searchResultCollectionView.rx.itemSelected
      .map { [weak self] indexPath in
        self?.searchResultCollectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
        return indexPath
      }
      .bind(to: viewModel.input.didSelectItem)
      .disposed(by: disposeBag)
    searchResultCollectionView.backgroundColor = .clear

    searchResultCollectionView.rx.contentOffset
      .map { [weak self] offset in
        guard let self = self else { return false }
        if offset.y > self.searchResultCollectionView.contentSize.height - Metric.loadNextPageThreshold {
          return true
        } else {
          return false
        }
      }
      .bind(to: viewModel.input.reachToBottom)
      .disposed(by: disposeBag)

    searchResultCollectionView.rx.willDisplaySupplementaryView
      .asDriver()
      .drive(with: self, onNext: { vc, supplementary in
        if let footerView = supplementary.supplementaryView as? CollectionViewFooterLoadingView {
          if vc.viewModel.output.isPaging.value {
            footerView.startLoading()
          } else {
            footerView.stopLoading()
          }
        }
      })
      .disposed(by: disposeBag)
  }
  
  private func bindOutputs() {
    /// Show skeleton views when loading search results
    viewModel.output.isLoading
      .asDriver(onErrorDriveWith: .empty())
      .drive(with: self, onNext: { vc, isLoading in
//        vc.searchResultCollectionView.scrollToTop(animated: false, offset: .init(x: 0, y: -(Metric.searchResultCollectionViewTopInset + Metric.navigationViewHeight + vc.view.safeAreaInsets.top)))
        vc.searchResultCollectionView.isUserInteractionEnabled = !isLoading
        vc.searchResultCollectionView.layoutIfNeeded()
        
        for cell in vc.searchResultCollectionView.visibleCells {
          guard let cell = cell as? SearchResultCollectionCell else { continue }
          
          if isLoading {
            cell.showSkeleton()
          } else {
            cell.hideSkeleton()
          }
        }
      })
      .disposed(by: disposeBag)
    
    /// Disable search button when loading search results
//    viewModel.output.isLoading
//      .asDriver(onErrorDriveWith: .empty())
//      .drive(with: self, onNext: { vc, isLoading in
//        vc.searchButton.isEnabled = !isLoading
//      })
//      .disposed(by: disposeBag)
    
    viewModel.output.searchResultMovie
      .asDriver(onErrorDriveWith: .empty())
      .drive(with: self, onNext: { vc, movies in
        if movies.isEmpty {
          vc.searchResultCollectionView.isHidden = true
          vc.searchResultPlaceholder.isHidden = false
          vc.searchResultPlaceholder.text = "No search result"
        } else {
          vc.searchResultCollectionView.isHidden = false
          vc.searchResultPlaceholder.isHidden = true
          vc.view.endEditing(true)
        }
      })
      .disposed(by: disposeBag)
    
    viewModel.output.searchResultMovie
      .bind(to: searchResultCollectionView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    viewModel.output.presentMoviewDetailVC
      .asDriver(onErrorDriveWith: .empty())
      .drive(with: self, onNext: { vc, movie in
        vc.presentMovieDetailVC(movie: movie)
      })
      .disposed(by: disposeBag)
    
    viewModel.output.showToastMessage
      .asDriver(onErrorDriveWith: .empty())
      .drive(with: self, onNext: { vc, message in
        vc.view.makeToast(message, position: .center)
      })
      .disposed(by: disposeBag)
  }
  
  private func presentMovieDetailVC(movie: Movie) {
    let viewModel = MovieDetailViewModel(movie: movie)
    let vc = MovieDetailViewController(
      viewModel: viewModel,
      thumbnailImageViewHeroId: movie.id)
    vc.modalPresentationStyle = .fullScreen
    present(vc, animated: true)
  }
}


// MARK: - Preview
import SwiftUI

struct SearchResultViewController_Preview: PreviewProvider {
  static var previews: some View {
    let viewModel = SearchResultViewModel()
    viewModel.search("we")
    return SearchResultViewController(viewModel: viewModel).toPreview()
  }
}
