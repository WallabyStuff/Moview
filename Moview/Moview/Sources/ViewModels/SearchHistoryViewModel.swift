//
//  SearchHistoryViewModel.swift
//  Moview
//
//  Created by 이승기 on 2023/10/08.
//

import UIKit

import RxSwift
import RxCocoa


final class SearchHistoryViewModel: ViewModelType {

  // MARK: - Properties
  
  struct Input {
    let viewWillAppear = PublishRelay<Void>()
    let addHistory = PublishRelay<String>()
    let removeHistory = PublishRelay<SearchHistory>()
    let selectItem = PublishRelay<IndexPath>()
  }
  
  struct Output {
    let searchHistories = BehaviorRelay<[SearchHistory]>(value: [])
    let selectedItem = PublishRelay<SearchHistory>()
  }
  
  private(set) var input: Input!
  private(set) var output: Output!
  private(set) var disposeBag = DisposeBag()
  
  
  // MARK: - Initializers
  
  init() {
    setupInputOutput()
  }
  
  
  // MARK: - Public
  
  public func addHistory(_ term: String) {
    input.addHistory.accept(term)
  }
  
  public func deleteHistory(_ item: SearchHistory) {
    input.removeHistory.accept(item)
  }
  
  
  // MARK: - Private
  
  private func setupInputOutput() {
    self.input = Input()
    let output = Output()
    
    let historyManager = SearchHistoryManager()
    
    input.viewWillAppear
      .flatMap { _ in
        return historyManager.fetchDatas()
      }
      .subscribe { histories in
        output.searchHistories.accept(histories)
      }
      .disposed(by: disposeBag)
    
    input.addHistory
      .flatMap { term in
        // add search history locally
        var histories = output.searchHistories.value
        let newHistory = SearchHistory(date: Date(), term: term)
        
        if histories.isEmpty {
          histories.append(newHistory)
        } else {
          histories.insert(newHistory, at: 0)
        }
        output.searchHistories.accept(histories)
        
        return historyManager.addData(newHistory)
      }
      .subscribe()
      .disposed(by: disposeBag)
    
    input.removeHistory
      .flatMap { item in
        // remove search history locally
        var histories = output.searchHistories.value
        if let index = histories.firstIndex(of: item) {
          histories.remove(at: index)
          output.searchHistories.accept(histories)
        }
        
        return historyManager.deleteData(item)
      }
      .subscribe()
      .disposed(by: disposeBag)
    
    input.selectItem
      .map { output.searchHistories.value[$0.row] }
      .subscribe(onNext: { item in
        output.selectedItem.accept(item)
      })
      .disposed(by: disposeBag)
    
    self.output = output
  }
}
