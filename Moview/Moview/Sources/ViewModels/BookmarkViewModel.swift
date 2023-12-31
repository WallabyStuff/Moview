//
//  BookmarkViewModel.swift
//  Moview
//
//  Created by Wallaby on 2023/02/05.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources


final class BookmarkViewModel: ViewModelType {
  
  // MARK: - Constants
  
  struct SectionName {
    static let bookmarkSection = "BookmarkSection"
  }
  
  
  // MARK: - Properties
  
  struct Input {
    let viewWillAppear = PublishRelay<Void>()
    let bookmarkMovieItemSelected = PublishRelay<IndexPath>()
  }
  
  struct Output {
    var bookmarkMovies = BehaviorRelay<[MovieDataSection]>(value: [])
    var presentMovieDetail = PublishRelay<Movie>()
  }
  
  private(set) var input: Input!
  private(set) var output: Output!
  private(set) var disposeBag = DisposeBag()
  private var bookmarkManager = BookmarkManager()
  
  
  // MARK: - Initializers
  
  init() {
    setupInputOutput()
  }
  
  
  // MARK: - Setups
  
  private func setupInputOutput() {
    self.input = Input()
    let output = Output()
    
    input.viewWillAppear
      .flatMap { [weak self] () -> Single<[MovieBookmark]> in
        guard let self = self else { return .just([]) }
        return self.bookmarkManager.fetchDatas()
      }
      .subscribe(onNext: { bookmarkMovies in
        let movies = bookmarkMovies.map { $0.toMovieType() }
        let section = MovieDataSection(sectionName: SectionName.bookmarkSection, items: movies)
        output.bookmarkMovies.accept([section])
      })
      .disposed(by: disposeBag)
    
    input.bookmarkMovieItemSelected
      .map { output.bookmarkMovies.value[0].items[$0.item] }
      .subscribe(onNext: { movie in
        output.presentMovieDetail.accept(movie)
      })
      .disposed(by: disposeBag)
    
    self.output = output
  }
}
