//
//  UIViewController+RxLifeCycle.swift
//  Moview
//
//  Created by Wallaby on 2023/02/05.
//

import RxSwift
import RxCocoa


extension RxSwift.Reactive where Base: UIViewController {
  
  // MARK: - ViewDidLoad
  
  public var viewDidLoad: Observable<Bool> {
    return methodInvoked(#selector(UIViewController.viewDidLoad))
      .map { $0.first as? Bool ?? false }
  }
  
  
  // MARK: - ViewWillAppear
  
  public var viewWillAppear: Observable<Bool> {
    return methodInvoked(#selector(UIViewController.viewWillAppear(_:)))
      .map { $0.first as? Bool ?? false }
  }
  
  // MARK: - ViewDidAppear
  
  public var viewDidAppear: Observable<Bool> {
    return methodInvoked(#selector(UIViewController.viewDidAppear(_:)))
      .map { $0.first as? Bool ?? false }
  }
  
  
  // MARK: - ViewWillDisappear
  
  public var viewWillDisappear: Observable<Bool> {
    return methodInvoked(#selector(UIViewController.viewWillDisappear(_:)))
      .map { $0.first as? Bool ?? false }
  }
  
  
  // MARK: - ViewDidDisappear
  
  public var viewDidDisappear: Observable<Bool> {
    return methodInvoked(#selector(UIViewController.viewDidDisappear(_:)))
      .map { $0.first as? Bool ?? false }
  }
}
