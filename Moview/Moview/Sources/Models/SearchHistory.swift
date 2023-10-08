//
//  SearchHistory.swift
//  Moview
//
//  Created by 이승기 on 2023/10/08.
//

import Foundation

import RealmSwift
import RxDataSources


final class SearchHistory: Object {
  
  // MARK: - Properties
  
  @Persisted var id: String = UUID().uuidString
  @Persisted var date: Date
  @Persisted var term: String
  
  
  // MARK: - Initializers
  
  convenience init(date: Date, term: String) {
    self.init()
    self.date = date
    self.term = term
  }
  
  
  // MARK: - Methods
  
  override class func primaryKey() -> String? {
    return "id"
  }
}
