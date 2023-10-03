//
//  MovieDataSection.swift
//  Moview
//
//  Created by Wallaby on 2023/02/05.
//

import RxDataSources


struct MovieDataSection: AnimatableSectionModelType {
  
  // MARK: - Types
  
  typealias Item = Movie
  typealias Identity = String
  
  
  // MARK: - Properties
  
  var items: [Item]
  var sectionName: String
  var identity: String {
    get { return sectionName }
  }
  
  
  // MARK: - Initializers
  
  init(sectionName: String, items: [Movie]) {
    self.sectionName = sectionName
    self.items = items
  }
  
  init(original: MovieDataSection, items: [Movie]) {
    self = original
    self.items = items
  }
  
  
  // MARK: - Methods
  
  public func append(items: [Movie]) -> MovieDataSection {
    let originalItems = self.items
    let newItems = originalItems + Set(items).subtracting(originalItems)
    let newSection = MovieDataSection(sectionName: sectionName, items: newItems)
    
    return newSection
  }
}
