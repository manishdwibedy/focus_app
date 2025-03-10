//
//  Interest.swift
//  FocusInterests
//
//  Created by jonathan thornburg on 2/20/17.
//  Copyright © 2017 singlefocusinc. All rights reserved.
//

import Foundation
import UIKit

enum InterestCategory: String {
    
    case Sports = "sports"
    case Art = "art"
    case Nightlife = "nightlife"
    case Food = "food"
    case Shopping = "shopping"
}

enum InterestStatus{
    case normal
    case like
    case hate
    
    mutating func toggle() {
        switch self {
        case .normal:
            self = .like
        case .like:
            self = .normal
        case .hate:
            break
        }
    }
}

class Interest:NSObject, NSCoding {
    
    var name: String?
    var category: InterestCategory?
    var image: UIImage?
    var imageString: String?
    var status: InterestStatus = .normal
    
    init(name: String?, category: InterestCategory?, image: UIImage?, imageString: String?) {
        self.name = name
        self.category = category
        self.image = image
        self.imageString = imageString
    }
    
    func addStatus(status: InterestStatus){
        self.status = status
        
    }
    
    required init(coder decoder: NSCoder) {
        self.name = decoder.decodeObject(forKey: "name") as? String ?? ""
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.name, forKey: "name")
    }
    
    override var hashValue : Int {
        get {
            return "\(self.name)".hashValue
        }
    }
    
    static func == (lhs: Interest, rhs: Interest) -> Bool {
        return lhs.name == rhs.name
    }
}
