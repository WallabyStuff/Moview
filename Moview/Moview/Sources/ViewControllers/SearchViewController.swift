//
//  SearchViewController.swift
//  Moview
//
//  Created by Wallaby on 2023/02/05.
//

import UIKit

import Then
import SnapKit
import Hero
import Toast_Swift

import RxSwift
import RxCocoa
import RxDataSources

class SearchViewController: UIViewController {
  
  // MARK: - Constants
  
  struct Metric {
    static let regularInset = 20.f
    
    static let navigationViewHeight = 64.f
    
    static let backButtonSize = 32.f
    static let backButtonImageInset = 6.f
    
    static let searchButtonSize = 32.f
    static let searchButtonImageInset = 6.f
    static let searchButtonRightMargin = 6.f
    
    static let navigationBarItemBottomMargin = 16.f
    
    static let searchTextFieldHeight = 44.f
    static let searchTextFieldCornerRadius = 10.f
    static let searchTextFieldLeftPadding = 16.f
    static let searchTextFieldRightPadding = 44.f
    static let searchTextFieldBottomMargin = 8.f
    static let searchTextFieldLeftMargin = 12.f
    
    static let estimatedSearchResultCellHeight = 150.f
    static let searchResultCollectionViewTopInset = 12.f
    static let searchResultCollectionViewBottomInset = 100.f
    
    static let pageLoadingFooterHeight = 100.f
    
    static let loadNextPageThreshold = 1000.f
  }
  
  // MARK: - Properties
  
  private var viewModel: SearchViewModel
  private var disposeBag = DisposeBag()
  private var searchResultCollectionViewLayout: UICollectionViewCompositionalLayout {
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
  
  private var searchTerm: String {
    return (searchTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
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
  
  
  // MARK: - UI
  
  let navigationView = NavigationView()
  let backButton = UIButton().then {
    $0.setImage(R.image.back(), for: .normal)
    $0.tintColor = R.color.iconWhite()
    $0.imageEdgeInsets = .init(common: Metric.backButtonImageInset)
  }
  let searchTextField = UITextField().then {
    $0.attributedPlaceholder = NSAttributedString(
      string: "Quick search",
      attributes: [NSAttributedString.Key.foregroundColor: R.color.textGrayDarker()!]
    )
    $0.backgroundColor = R.color.backgroundBlackLight()
    $0.layer.cornerRadius = Metric.searchTextFieldCornerRadius
    $0.returnKeyType = .search
    $0.tintColor = R.color.accentRed()
  }
  let searchButton = UIButton().then {
    $0.hero.id = "SearchButton"
    $0.setImage(R.image.loupe(), for: .normal)
    $0.tintColor = R.color.iconWhite()
    $0.imageEdgeInsets = .init(common: Metric.searchButtonImageInset)
    $0.backgroundColor = .clear
    $0.layer.cornerRadius = Metric.searchTextFieldCornerRadius
  }
  var searchResultCollectionView: UICollectionView!
  var searchResultPlaceholder = UILabel().then {
    $0.textColor = R.color.textGrayDarker()
  }
  
  
  // MARK: - LifeCycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    searchTextField.becomeFirstResponder()
  }
  
  // MARK: - Initializers
  
  init(viewModel: SearchViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
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
    isHeroEnabled = true
    
    setupBackground()
    setupNavigationView()
    setupSearchButton()
    setupSearchResultCollectionView()
    bindSearchResultPlaceholder()
  }
  
  private func setupBackground() {
    view.backgroundColor = R.color.backgroundBlack()
  }
  
  private func setupNavigationView() {
    view.addSubview(navigationView)
    navigationView.snp.makeConstraints {
      $0.top.leading.trailing.equalToSuperview()
      $0.height.equalTo(Metric.navigationViewHeight + SafeAreaGuide.top)
    }
    
    navigationView.addSubview(backButton)
    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().inset(Metric.regularInset)
      $0.bottom.equalToSuperview().inset(Metric.navigationBarItemBottomMargin)
      $0.width.height.equalTo(Metric.backButtonSize)
    }
    
    navigationView.addSubview(searchTextField)
    searchTextField.snp.makeConstraints {
      $0.leading.equalTo(backButton.snp.trailing).offset(Metric.searchTextFieldLeftMargin)
      $0.bottom.equalToSuperview().inset(Metric.searchTextFieldBottomMargin)
      $0.height.equalTo(Metric.searchTextFieldHeight)
      $0.trailing.equalToSuperview().inset(Metric.regularInset)
    }
    
    let leftPadding = UIView(frame: .init(x: 0, y: 0, width: Metric.searchTextFieldLeftPadding, height: Metric.searchTextFieldHeight))
    searchTextField.leftView = leftPadding
    searchTextField.leftViewMode = .always
    
    let rightPadding = UIView(frame: .init(x: 0, y: 0, width: Metric.searchTextFieldRightPadding, height: Metric.searchTextFieldHeight))
    searchTextField.rightView = rightPadding
    searchTextField.rightViewMode = .always
  }
  
  private func setupSearchButton() {
    searchButton.hero.id = "SearchButton"
    view.addSubview(searchButton)
    searchButton.snp.makeConstraints {
      $0.trailing.equalTo(searchTextField).inset(Metric.searchButtonRightMargin)
      $0.centerY.equalTo(searchTextField)
      $0.width.height.equalTo(Metric.searchButtonSize)
    }
  }
  
  private func setupSearchResultCollectionView() {
    /// Register cell
    searchResultCollectionView = UICollectionView(frame: .zero, collectionViewLayout: searchResultCollectionViewLayout)
    searchResultCollectionView.register(SearchResultCollectionCell.self, forCellWithReuseIdentifier: SearchResultCollectionCell.identifier)
    searchResultCollectionView.register(CollectionViewFooterLoadingView.self,
                                        forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: CollectionViewFooterLoadingView.identifier)
    
    /// Setup constraints
    view.insertSubview(searchResultCollectionView, at: 0)
    searchResultCollectionView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
    /// Setup insets
    searchResultCollectionView.contentInset = .init(
      top: Metric.navigationViewHeight + Metric.searchResultCollectionViewTopInset,
      bottom: Metric.searchResultCollectionViewBottomInset)
    searchResultCollectionView.scrollIndicatorInsets = .init(
      top: Metric.navigationViewHeight + Metric.searchResultCollectionViewTopInset)
    
    /// Configure navigation bar opaque threshold
    navigationView.configureScrollView(
      searchResultCollectionView,
      threshold: Metric.navigationViewHeight + SafeAreaGuide.top)
    
    // Etc
    searchResultCollectionView.delaysContentTouches = false
  }
  
  private func bindSearchResultPlaceholder() {
    view.addSubview(searchResultPlaceholder)
    searchResultPlaceholder.snp.makeConstraints {
      $0.centerX.centerY.equalToSuperview()
    }
  }
  
  
  // MARK: - Binds
  
  private func bind() {
    bindInputs()
    bindOutputs()
    bindCollectionViewScrollToEndEditing()
  }
  
  private func bindInputs() {
    backButton.rx.tap
      .asDriver()
      .drive(with: self, onNext: { vc, _ in
        vc.dismiss()
      })
      .disposed(by: disposeBag)
    
    searchTextField.rx.controlEvent([.editingDidEndOnExit])
      .map { [weak self] in
        guard let self = self else { return "" }
        return self.searchTerm
      }
      .bind(to: viewModel.input.search)
      .disposed(by: disposeBag)
    
    searchButton.rx.tap
      .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
      .map { [weak self] in
        guard let self = self else { return "" }
        return self.searchTerm
      }
      .bind(to: viewModel.input.search)
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
        vc.searchResultCollectionView.scrollToTop(animated: false, offset: .init(x: 0, y: -(Metric.searchResultCollectionViewTopInset + Metric.navigationViewHeight + vc.view.safeAreaInsets.top)))
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
    viewModel.output.isLoading
      .asDriver(onErrorDriveWith: .empty())
      .drive(with: self, onNext: { vc, isLoading in
        vc.searchButton.isEnabled = !isLoading
      })
      .disposed(by: disposeBag)
    
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
  
  private func bindCollectionViewScrollToEndEditing() {
    searchResultCollectionView.rx.didScroll
      .subscribe(with: self, onNext: { vc, _  in
        vc.view.endEditing(true)
      })
      .disposed(by: disposeBag)
  }
  
  
  // MARK: - Methods
  
  private func dismiss() {
    heroModalAnimationType = .zoomOut
    dismiss(animated: true)
  }
  
  private func presentMovieDetailVC(movie: Movie) {
    let viewModel = MovieDetailViewModel(movie: movie)
    let vc = MovieDetailViewController(
      viewModel: viewModel,
      thumbnailImageViewHeroId: movie.id)
    vc.modalPresentationStyle = .fullScreen
    present(vc, animated: true)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    view.endEditing(true)
  }
}
