//
//  PlaceRating.swift
//  FocusInterests
//
//  Created by Manish Dwibedy on 5/17/17.
//  Copyright © 2017 singlefocusinc. All rights reserved.
//

import Foundation

class PlaceRating: Equatable{
    let uid: String
    let date: Date
    let rating: Double
    var comment: String? = nil
    var username: String? = nil
    init(uid: String, date: Date, rating: Double) {
        self.uid = uid
        self.date = date
        self.rating = rating
    }
    
    func addComment(comment: String) {
        self.comment = comment
    }
    
    func setUsername(username: String){
        self.username = username
    }
    
    static func ==(lhs:PlaceRating, rhs:PlaceRating) -> Bool {
        return lhs.uid == rhs.uid
    }
}
