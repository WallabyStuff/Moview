//
//  MovieBookmarkManager.swift
//  Moview
//
//  Created by Wallaby on 2023/02/05.
//

import Foundation

import RealmSwift
import RxSwift


final class BookmarkManager: RealmManager {
  
  // MARK: - Properties
  
  typealias Item = MovieBookmark
  
  
  // MARK: - Methods
  
  public func addData(_ item: Movie) -> Completable {
    return Completable.create { observer  in
      do {
        let realmInstance = try Realm()
        try realmInstance.write {
          realmInstance.add(item.toMovieBookmarkType(), update: .modified)
        }
        
        observer(.completed)
      } catch {
        observer(.error(error))
      }
      
      return Disposables.create()
    }
  }
  
  public func deleteData(id: String) -> Completable {
    return Completable.create { observer in
      do {
        let realmInstance = try Realm()
        
        for bookmark in Array(realmInstance.objects(MovieBookmark.self)) {
          if bookmark.id == id {
            try realmInstance.write {
              realmInstance.delete(bookmark)
            }
            break
          }
        }

        observer(.completed)
      } catch {
        observer(.error(error))
      }
      
      return Disposables.create()
    }
  }

  public func isBookmarked(id: String) -> Bool {
    do {
      let realmInstance = try Realm()
      
      for bookmark in Array(realmInstance.objects(MovieBookmark.self)) {
        if bookmark.id == id { return true }
      }

      return false
    } catch {
      return false
    }
  }
}

