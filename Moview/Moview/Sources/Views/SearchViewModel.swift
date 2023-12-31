//
//  SearchViewModel.swift
//  Moview
//
//  Created by Wallaby on 2023/02/05.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources


final class SearchViewModel: ViewModelType {
  
  // MARK: - Properties
  
  struct Input {
    let viewWillAppear = PublishRelay<Void>()
    let search = PublishRelay<String?>()
  }
  
  struct Output {
    let searchHistoryViewModel = PublishRelay<SearchHistoryViewModel>()
    let searchResultViewModel = PublishRelay<SearchResultViewModel>()
  }
  
  private(set) var input: Input!
  private(set) var output: Output!
  private(set) var disposeBag = DisposeBag()
  
  private var searchHistoryViewModel = SearchHistoryViewModel()
  private var searchResultViewModel = SearchResultViewModel()
  
  
  // MARK: - Initializers
  
  init() {
    setupInputOutput()
  }
  
  
  // MARK: - Setups
  
  private func setupInputOutput() {
    let input = Input()
    let output = Output()
    
    input.viewWillAppear
      .subscribe(with: self, onNext: { strongSelf, _ in
        output.searchHistoryViewModel.accept(strongSelf.searchHistoryViewModel)
      })
      .disposed(by: disposeBag)
    
    input.search
      .subscribe(with: self, onNext: { strongSelf, term in
        guard let term else { return }
        output.searchResultViewModel.accept(strongSelf.searchResultViewModel)
        
        strongSelf.searchResultViewModel.search(term)
        strongSelf.searchHistoryViewModel.addHistory(term)
      })
      .disposed(by: disposeBag)
    
    searchHistoryViewModel.output
      .selectedItem
      .subscribe(onNext: { item in
        input.search.accept(item.term)
      })
      .disposed(by: disposeBag)
    
    self.input = input
    self.output = output
  }
}
