//
//  SearchHistoryCollectionCell.swift
//  Moview
//
//  Created by 이승기 on 2023/10/08.
//

import UIKit

import Then
import SnapKit

import RxSwift
import RxCocoa


final class SearchHistoryCollectionCell: UICollectionViewCell {
  
  // MARK: - Constants
  
  static let identifier = String(describing: SearchHistoryCollectionCell.self)
  
  enum Metric {
    static let horizontalInset = 20.f
  }
  
  
  // MARK: - Properties
  
  private var disposeBag = DisposeBag()
  private var deleteHandler: (() -> Void)?
  
  
  // MARK: - UI
  
  private let leadingImage = UIImageView().then {
    $0.image = R.image.time_arrow_backward()!
    $0.tintColor = R.color.textGrayDark()!
  }
  private let termLabel = UILabel().then {
    $0.font = .systemFont(ofSize: 17, weight: .semibold)
    $0.textColor = R.color.textWhite()!
  }
  private let deleteButton = UIButton().then {
    $0.setImage(R.image.x()!, for: .normal)
    $0.tintColor = R.color.iconWhite()!
  }
  
  
  // MARK: - Initializers
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  // MARK: - Public
  
  public func configure(_ history: SearchHistory, deleteHandler: @escaping () -> Void) {
    termLabel.text = history.term
    self.deleteHandler = deleteHandler
  }
  
  
  // MARK: - Private
  
  private func setup() {
    setupView()
    bind()
  }
  
  private func setupView() {
    setupLeadingImageView()
    setupDeleteButton()
    setupTermLabel()
    setupSelectedBackground()
  }
  
  private func setupLeadingImageView() {
    contentView.addSubview(leadingImage)
    leadingImage.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.leading.equalToSuperview().inset(Metric.horizontalInset)
      $0.width.height.equalTo(20)
    }
  }
  
  private func setupDeleteButton() {
    contentView.addSubview(deleteButton)
    deleteButton.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.trailing.equalToSuperview().inset(Metric.horizontalInset)
      $0.width.height.equalTo(24)
    }
  }
  
  private func setupTermLabel() {
    contentView.addSubview(termLabel)
    termLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.leading.equalTo(leadingImage.snp.trailing).offset(16)
      $0.trailing.equalTo(deleteButton.snp.leading).offset(-16)
    }
  }
  
  private func setupSelectedBackground() {
    let selectedView = UIView()
    selectedView.backgroundColor = R.color.backgroundBlackLighter()!
    selectedBackgroundView = selectedView
  }
  
  
  // MARK: - Binding
  
  private func bind() {
    bindDeleteButton()
  }
  
  private func bindDeleteButton() {
    deleteButton.rx.tap
      .asDriver()
      .drive(with: self, onNext: { strongSelf, _  in
        strongSelf.deleteHandler?()
      })
      .disposed(by: disposeBag)
  }
}


// MARK: - Preview
import SwiftUI

struct SearchHistoryCollectionCell_Preview: PreviewProvider {
  static var previews: some View {
    let cell = SearchHistoryCollectionCell()
    let sampleData = SearchHistory(date: .init(), term: "Spider man")
    cell.configure(sampleData) {
      print("delete button clicked!")
    }
    
    return UIViewPreview {
      cell
    }
    .frame(height: 56)
  }
}
