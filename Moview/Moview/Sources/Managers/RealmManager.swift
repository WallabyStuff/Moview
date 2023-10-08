//
//  RealmManager.swift
//  Moview
//
//  Created by 이승기 on 2023/10/08.
//

import RealmSwift
import RxSwift


protocol RealmManager {
  
  associatedtype Item: Object
  
  func addData(_ item: Item) -> Completable
  func fetchDatas() -> Single<[Item]>
  func deleteData(_ item: Item) -> Completable
  func deleteAll() -> Completable
}


// MARK: - Implementation

extension RealmManager {
  
  public func addData(_ item: Item) -> Completable {
    return Completable.create { observer  in
      do {
        let realmInstance = try Realm()
        try realmInstance.write {
          realmInstance.add(item, update: .modified)
        }
        
        observer(.completed)
      } catch {
        observer(.error(error))
      }
      
      return Disposables.create()
    }
  }
  
  public func fetchDatas() -> Single<[Item]> {
    return Single.create { observer in
      do {
        let realmInstance = try Realm()
        let items = Array(realmInstance.objects(Item.self))
        observer(.success(items))
      } catch {
        observer(.failure(error))
      }
      
      return Disposables.create()
    }
  }
  
  public func deleteData(_ item: Item) -> Completable {
    return Completable.create { observer  in
      do {
        let realmInstance = try Realm()
        try realmInstance.write {
          realmInstance.delete(item)
        }
        
        observer(.completed)
      } catch {
        observer(.error(error))
      }
      
      return Disposables.create()
    }
  }
  
  public func deleteAll() -> Completable {
    return Completable.create { observer  in
      do {
        let realmInstance = try Realm()
        try realmInstance.write {
          realmInstance.deleteAll()
        }
        
        observer(.completed)
      } catch {
        observer(.error(error))
      }
      
      return Disposables.create()
    }
  }
}
