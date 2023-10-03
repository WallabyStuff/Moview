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

class SearchViewModel: ViewModelType {
  
  // MARK: - Constants
  
  struct SectionName {
    static let fakeSection = "FakeSection"
    static let searchResultSection = "SearchResultSection"
  }
  
  
  // MARK: - Properties
  
  struct Input {
    let search = PublishRelay<String>()
    let didSelectItem = PublishRelay<IndexPath>()
    let reachToBottom = BehaviorRelay(value: false)
  }
  
  struct Output {
    let isLoading = PublishRelay<Bool>()
    let searchResultMovie = BehaviorRelay<[MovieDataSection]>(value: [])
    let presentMoviewDetailVC = PublishRelay<Movie>()
    let showToastMessage = PublishRelay<String>()
    let isPaging = BehaviorRelay(value: false)
    let currentPage = BehaviorRelay(value: 0)
    let currentSearchTerm = BehaviorRelay(value: "")
  }
  
  private(set) var input: Input!
  private(set) var output: Output!
  private(set) var disposeBag = DisposeBag()
  private let ytsApiService = YTSApiService()
  static var fakeMovieItems: [MovieDataSection] {
    return [MovieDataSection(sectionName: SectionName.fakeSection, items: Movie.fakeItems(count: 10))]
  }
  
  
  // MARK: - Initializers
  
  init() {
    setupInputOutput()
  }
  
  
  // MARK: - Setups
  
  private func setupInputOutput() {
    self.input = Input()
    let output = Output()
    
    input.search
      .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
      .observe(on: MainScheduler.instance)
      .map { term in
        output.currentPage.accept(0)
        output.currentSearchTerm.accept(term)
        output.searchResultMovie.accept(Self.fakeMovieItems)
        output.isLoading.accept(true)
        return term
      }
      .flatMap {
        self.ytsApiService.searchMovie(term: $0)
          .catch { error in
            /// ERROR state
            if let error = error as? YTSApiService.YTSApiServiceError,
               error == .lessThenMinimumTermLength {
              output.showToastMessage.accept("Please enter at least two letter")
            }
            
            return .just([])
          }
      }
      .subscribe(onNext: { movies in
        /// SUCCESS state
        let resultMovieSection = MovieDataSection(sectionName: SectionName.searchResultSection, items: movies)
        output.searchResultMovie.accept([resultMovieSection])
        output.isLoading.accept(false)
        output.currentPage.accept(1)
      })
      .disposed(by: disposeBag)
    
    input.didSelectItem
      .map { output.searchResultMovie.value[0].items[$0.row] }
      .subscribe(onNext: { movie in
        output.presentMoviewDetailVC.accept(movie)
      })
      .disposed(by: disposeBag)
    
    input.reachToBottom
      .map { didReachToBottom -> Bool in
        if didReachToBottom == true &&
            output.isPaging.value == false &&
            output.currentPage.value != 0 {
          return true
        } else {
          return false
        }
      }
      .flatMap { isPageable -> Single<[Movie]> in
        if isPageable {
          output.isPaging.accept(true)
          let nextPage = output.currentPage.value + 1
          return self.ytsApiService.searchMovie(
            term: output.currentSearchTerm.value,
            page: nextPage)
          .catch { error in
            print(error)
            return .just([])
          }
        } else {
          return .just([])
        }
      }
      .subscribe(onNext: { movies in
        if movies.isEmpty {
          return
        }

        // Success to load next search result page
        let originalSection = output.searchResultMovie.value[0]
        let nextPageMovieSection = originalSection.append(items: movies)
        output.searchResultMovie.accept([nextPageMovieSection])

        // Success to emit next search result page
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 1, execute: .init(block: {
          let nextPage = output.currentPage.value + 1
          output.currentPage.accept(nextPage)
          output.isPaging.accept(false)
        }))
      })
      .disposed(by: disposeBag)
    
    self.output = output
  }
}
