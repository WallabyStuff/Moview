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
    let removeHistory = PublishRelay<IndexPath>()
  }
  
  struct Output {
    let searchHistories = BehaviorRelay<[SearchHistory]>(value: [])
  }
  
  private(set) var input: Input!
  private(set) var output: Output!
  private(set) var disposeBag = DisposeBag()
  
  
  // MARK: - Initializers
  
  init() {
    setupInputOutput()
  }
  
  
  // MARK: - Methods
  
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
      .flatMap { indexPath in
        // remove search history locally
        var histories = output.searchHistories.value
        histories.remove(at: indexPath.row)
        output.searchHistories.accept(histories)
        
        let searchHistory = output.searchHistories.value[indexPath.row]
        return historyManager.deleteData(searchHistory)
      }
      .subscribe()
      .disposed(by: disposeBag)
    
    self.output = Output()
  }
}
