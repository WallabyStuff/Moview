//
//  MainViewModel.swift
//  Moview
//
//  Created by Wallaby on 2023/02/05.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources

class MainViewModel: ViewModelType {
  
  // MARK: - Constants
  
  static let PAGE_ITEM_LIMIT = 30
  
  struct SectionName {
    static let carouselSection = "TopCarouselSection"
    static let recommendForYouSection = "RecommendForYouSection"
  }
  
  
  // MARK: - Properties
  
  struct Input {
    let viewDidLoad = PublishRelay<Void>()
    let didMovieItemSelected = PublishRelay<IndexPath>()
    let reachToBottom = BehaviorRelay<Bool>(value: false)
  }
  
  struct Output {
    let movieList = BehaviorRelay<[MovieDataSection]>(value: fakeMovieItems)
    let presentMovieDetail = PublishRelay<Movie>()
    let isLoading = BehaviorRelay<Bool>(value: true)
    let isPaging = BehaviorRelay<Bool>(value: false)
    let currentPage = BehaviorRelay(value: 0)
  }
  
  private(set) var input: Input!
  private(set) var output: Output!
  private(set) var disposeBag = DisposeBag()
  private let ytsApiService = YTSApiService()
  static var fakeMovieItems: [MovieDataSection] {
    let newMovieSection = MovieDataSection(
      sectionName: SectionName.carouselSection,
      items: Movie.fakeItems(count: 2))
    let recommendedMovieSection = MovieDataSection(
      sectionName: SectionName.recommendForYouSection,
      items: Movie.fakeItems(count: 3))
    return [newMovieSection, recommendedMovieSection]
  }
  
  
  // MARK: - Initializers
  
  init() {
    setupInputOutput()
  }
  
  
  // MARK: - Setups
  
  private func setupInputOutput() {
    self.input = Input()
    let output = Output()
    
    input.viewDidLoad
      .flatMap { self.ytsApiService.getMovieList() }
      .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { movies in
        // Success to load movies
        let newMovieSection = MovieDataSection(
          sectionName: SectionName.carouselSection,
          items: Array(movies[...10]))
        let recommendedMovieSection = MovieDataSection(
          sectionName: SectionName.recommendForYouSection,
          items: Array(movies[11...]))
        
        output.movieList.accept([newMovieSection, recommendedMovieSection])
        output.isLoading.accept(false)
        output.currentPage.accept(1)
      })
      .disposed(by: disposeBag)
    
    input.didMovieItemSelected
      .map { output.movieList.value[$0.section].items[$0.row] }
      .subscribe(onNext: { selectedMovie in
        output.presentMovieDetail.accept(selectedMovie)
      })
      .disposed(by: disposeBag)
    
    input.reachToBottom
      .map { didReachToBottom in
        if didReachToBottom == true &&
            output.isPaging.value == false &&
            output.currentPage.value != 0 {
          return true
        } else {
          return false
        }
      }
      .flatMap { [weak self] isPageable -> Single<[Movie]> in
        guard let self = self else { return .just([]) }
        if isPageable {
          output.isPaging.accept(true)
          let nextPage = output.currentPage.value + 1
          return self.ytsApiService.getMovieList(
            limit: Self.PAGE_ITEM_LIMIT,
            page: nextPage)
        } else {
          return .just([])
        }
      }
      .subscribe(onNext: { movies in
        if movies.isEmpty {
          return
        }
        
        // Success to load next page
        let originalMovieSection = output.movieList.value[1]
        let newMovieSection = originalMovieSection.append(items: movies)
        let pagedSection = [output.movieList.value[0], newMovieSection]
        
        // Success to update next page
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 1, execute: .init(block: {
          output.movieList.accept(pagedSection)
          let nextPage = output.currentPage.value + 1
          output.currentPage.accept(nextPage)
          output.isPaging.accept(false)
        }))
      })
      .disposed(by: disposeBag)
    
    self.output = output
  }
}
