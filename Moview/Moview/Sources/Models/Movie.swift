//
//  Moview.swift
//  Moview
//
//  Created by Wallaby on 2023/02/05.
//

import RxDataSources


struct Movie: Decodable {
  var id: String
  var title: String
  var rating: Float
  var runtime: Int
  var genres: [String]
  var description_full: String
  var medium_cover_image: String
  var large_cover_image: String
}

extension Movie {
  public static func sampleItems(count: Int) -> [Movie] {
    var fakeItems = [Movie]()
    
    for _ in 0..<count {
      fakeItems.append(Movie.sampleItem())
    }
    
    return fakeItems
  }
  
  public static func sampleItem() -> Movie {
    return .init(
      id: UUID().uuidString,
      title: "",
      rating: 0,
      runtime: 0,
      genres: [],
      description_full: "",
      medium_cover_image: "",
      large_cover_image: "")
  }
}

extension Movie {
  public func toMovieBookmarkType() -> MovieBookmark {
    return MovieBookmark(
      id: id,
      title: title,
      rating: rating,
      runtime: runtime,
      genres: genres.joined(separator: MovieBookmark.genreArraySeparator),
      description_full: description_full,
      medium_cover_image: medium_cover_image,
      large_cover_image: large_cover_image)
  }
}

extension Movie: IdentifiableType {
  typealias Identity = String
  
  var identity: String {
    return id
  }
}

extension Movie: Hashable {
  static func == (lhs: Movie, rhs: Movie) -> Bool {
    return lhs.id == rhs.id
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id.hashValue)
  }
}
