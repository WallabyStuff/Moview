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


final class SearchViewController: UIViewController {
  
  // MARK: - Constants
  
  enum Metric {
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
  }
  
  
  // MARK: - Properties
  
  private var viewModel: SearchViewModel
  private var disposeBag = DisposeBag()
  
  private var searchTerm: String {
    return (searchTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  private var viewDidAppear = false
  
  
  // MARK: - UI
  
  private let navigationView = NavigationView()
  private let backButton = UIButton().then {
    $0.setImage(R.image.back(), for: .normal)
    $0.tintColor = R.color.iconWhite()
    $0.imageEdgeInsets = .init(common: Metric.backButtonImageInset)
  }
  private let searchTextField = UITextField().then {
    $0.attributedPlaceholder = NSAttributedString(
      string: "Quick search",
      attributes: [NSAttributedString.Key.foregroundColor: R.color.textGrayDarker()!]
    )
    $0.backgroundColor = R.color.backgroundBlackLight()
    $0.layer.cornerRadius = Metric.searchTextFieldCornerRadius
    $0.returnKeyType = .search
    $0.tintColor = R.color.accentRed()
  }
  private let searchButton = UIButton().then {
    $0.hero.id = "SearchButton"
    $0.setImage(R.image.loupe(), for: .normal)
    $0.tintColor = R.color.iconWhite()
    $0.imageEdgeInsets = .init(common: Metric.searchButtonImageInset)
    $0.backgroundColor = .clear
    $0.layer.cornerRadius = Metric.searchTextFieldCornerRadius
  }
  private let containerView = UIView()
  private var searchHistoryVC: SearchHistoryViewController?
  private var searchResultVC: SearchResultViewController?
  
  
  // MARK: - LifeCycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    if viewDidAppear == false {
      searchTextField.becomeFirstResponder()
      viewDidAppear = true
    }
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
    setupContainerView()
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
  
  private func setupContainerView() {
    view.addSubview(containerView)
    containerView.snp.makeConstraints {
      $0.top.equalTo(navigationView.snp.bottom)
      $0.horizontalEdges.bottom.equalToSuperview()
    }
  }
  
  
  // MARK: - Binding
  
  private func bind() {
    bindInputs()
    bindOutputs()
  }
  
  private func bindInputs() {
    rx.viewWillAppear
      .map { _ in }
      .bind(to: viewModel.input.viewWillAppear)
      .disposed(by: disposeBag)
    
    backButton.rx.tap
      .asDriver()
      .drive(with: self, onNext: { vc, _ in
        vc.dismiss()
      })
      .disposed(by: disposeBag)
    
    Observable.merge([
      searchTextField.rx.controlEvent([.editingDidEndOnExit]).asObservable(),
      searchButton.rx.tap.throttle(.milliseconds(300), scheduler: MainScheduler.instance)
    ])
    .map { [weak self] in
      if (self?.searchTerm ?? "").count < 2 {
        self?.view.makeToast("Please enter at least two letter")
        return nil
      }
      
      return self?.searchTerm
    }
    .bind(to: viewModel.input.search)
    .disposed(by: disposeBag)
    
    searchTextField.rx.controlEvent([.editingDidBegin])
      .asDriver()
      .drive(onNext: { [weak self] in
        self?.showSearchHistory()
      })
      .disposed(by: disposeBag)
  }
  
  private func bindOutputs() {
    viewModel.output
      .searchHistoryViewModel
      .subscribe(with: self) { vc, viewModel in
        vc.configureSearchHistoryVC(viewModel: viewModel)
      }
      .disposed(by: disposeBag)
    
    viewModel.output
      .searchResultViewModel
      .subscribe(with: self) { vc, viewModel in
        vc.view.endEditing(true)
        vc.showSearchResult()
        vc.configureSearchResultVC(viewModel: viewModel)
      }
      .disposed(by: disposeBag)
  }
  
  
  // MARK: - Methods
  
  private func dismiss() {
    heroModalAnimationType = .zoomOut
    dismiss(animated: true)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    view.endEditing(true)
  }
  
  private func configureSearchHistoryVC(viewModel: SearchHistoryViewModel) {
    if searchHistoryVC != nil { return }
    
    let viewController = SearchHistoryViewController(viewModel: viewModel)
    addChild(viewController)
    containerView.addSubview(viewController.view)
    viewController.view.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
    self.searchHistoryVC = viewController
  }
  
  private func configureSearchResultVC(viewModel: SearchResultViewModel) {
    if searchResultVC != nil { return }
    
    let viewController = SearchResultViewController(viewModel: viewModel)
    addChild(viewController)
    containerView.addSubview(viewController.view)
    viewController.view.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
    self.searchResultVC = viewController
  }
  
  private func showSearchHistory() {
    searchHistoryVC?.view.isHidden = false
    searchResultVC?.view.isHidden = true
  }
  
  private func showSearchResult() {
    searchHistoryVC?.view.isHidden = true
    searchResultVC?.view.isHidden = false
  }
}


// MARK: - Preview

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct SearchView_Preview: PreviewProvider {
  static var previews: some View {
    SearchViewController(viewModel: .init())
      .toPreview()
      .edgesIgnoringSafeArea(.all)
  }
}
#endif

