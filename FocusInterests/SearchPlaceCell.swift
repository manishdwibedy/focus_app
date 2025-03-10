//
//  SearchPlaceCell.swift
//  FocusInterests
//
//  Created by Andrew Simpson on 5/19/17.
//  Copyright © 2017 singlefocusinc. All rights reserved.
//

import UIKit

class SearchPlaceCell: UITableViewCell {

    @IBOutlet weak var dateAndTimeLabel: UILabel!
    @IBOutlet weak var placeCellView: UIView!
    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var addressTextView: UITextView!
    @IBOutlet weak var followButtonOut: UIButton!
    @IBOutlet weak var inviteButtonOut: UIButton!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var ratingsStarImage: UIImageView!
    
    var placeID = String()
    var parentVC: SearchPlacesViewController? = nil
    var placeVC: PinViewController? = nil
    var placeViewController: PlaceViewController? = nil
    var searchVC: SearchViewController? = nil
    var place: Place?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addressTextView.contentInset = UIEdgeInsetsMake(-4,-4,0,0);
        // Initialization code
        
//        Follow button
        
        self.followButtonOut.clipsToBounds = true
        self.followButtonOut.isSelected = false
        self.followButtonOut.roundCorners(radius: 5)
        self.followButtonOut.layer.shadowOpacity = 0.5
        self.followButtonOut.layer.masksToBounds = false
        self.followButtonOut.layer.shadowColor = UIColor.black.cgColor
        self.followButtonOut.layer.shadowRadius = 5.0
        
        self.followButtonOut.setTitleColor(UIColor.white, for: .normal)
        self.followButtonOut.setTitle("Follow", for: .normal)
        self.followButtonOut.setTitleColor(UIColor.white, for: .normal)
        
        self.followButtonOut.setTitleColor(UIColor.white, for: .selected)
        self.followButtonOut.setTitle("Following", for: .selected)
        self.followButtonOut.setTitleColor(Constants.color.navy, for: .selected)
//        invite button
        self.inviteButtonOut.clipsToBounds = true
        self.inviteButtonOut.roundCorners(radius: 5)
        self.inviteButtonOut.layer.shadowOpacity = 0.5
        self.inviteButtonOut.layer.masksToBounds = false
        self.inviteButtonOut.layer.shadowColor = UIColor.black.cgColor
        self.inviteButtonOut.layer.shadowRadius = 5.0

//        image
        placeImage.layer.borderWidth = 1
        placeImage.layer.borderColor = UIColor(red: 72/255.0, green: 255/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor
        placeImage.roundedImage()
        
//        category label
        self.categoryLabel.textColor = UIColor(red: 119/255.0, green: 197/255.0, blue: 53/255.0, alpha: 1.0)
        
//        cell view
        placeCellView.allCornersRounded(radius: 10.0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.placeCellView.setNeedsLayout()
        
        self.placeCellView.layoutIfNeeded()
        
        let path = UIBezierPath(roundedRect: self.placeCellView.bounds, cornerRadius: 10)
        
        let mask = CAShapeLayer()
        let shortbackgroundMask = CAShapeLayer()
        
        mask.path = path.cgPath
        
        self.placeCellView.layer.mask = mask
    }
    @IBAction func followButton(_ sender: Any) {
        
        
        if self.followButtonOut.isSelected == false{
            
//            unfollow button appearance
            self.followButtonOut.isSelected = true
            self.followButtonOut.layer.borderWidth = 1
            self.followButtonOut.layer.borderColor = Constants.color.navy.cgColor
            self.followButtonOut.backgroundColor = UIColor.white
            self.followButtonOut.tintColor = UIColor.clear
            self.followButtonOut.layer.shadowOpacity = 0.5
            self.followButtonOut.layer.masksToBounds = false
            self.followButtonOut.layer.shadowColor = UIColor.black.cgColor
            self.followButtonOut.layer.shadowRadius = 5.0
            
            let time = NSDate().timeIntervalSince1970
            Follow.followPlace(id: (place?.id)!)
            

        } else if self.followButtonOut.isSelected == true {
            
            let unfollowAlertController = UIAlertController(title: "Are you sure you want to unfollow \(self.place!.name)?", message: nil, preferredStyle: .actionSheet)
            
            
            let unfollowAction = UIAlertAction(title: "Unfollow", style: .destructive) { action in
                
//            follow button appearance
                self.followButtonOut.isSelected = false
                self.followButtonOut.layer.borderWidth = 0
                self.followButtonOut.layer.borderColor = UIColor.clear.cgColor
                self.followButtonOut.backgroundColor = UIColor(red: 20/255.0, green: 40/255.0, blue: 64/255.0, alpha: 1.0)
                self.followButtonOut.tintColor = UIColor.clear
                self.followButtonOut.layer.shadowOpacity = 0.5
                self.followButtonOut.layer.masksToBounds = false
                self.followButtonOut.layer.shadowColor = UIColor.black.cgColor
                self.followButtonOut.layer.shadowRadius = 5.0

                Follow.unFollowPlace(id: (self.place?.id)!)
                
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
                print("cancel has been tapped")
            }
            
            unfollowAlertController.addAction(unfollowAction)
            unfollowAlertController.addAction(cancelAction)
            placeVC?.present(unfollowAlertController, animated: true, completion: nil)
            
            
            
        }
        
    }
   
    @IBAction func inviteButton(_ sender: Any) {
        print("pressed invite button in searchplace")
        let storyboard = UIStoryboard(name: "Invites", bundle: nil)
        let ivc = storyboard.instantiateViewController(withIdentifier: "home") as! InviteViewController
        ivc.type = "place"
        ivc.parentCell = self
        ivc.id = self.placeID
        ivc.place = place
        ivc.searchPlace = parentVC
        
        if let VC = self.parentVC{
            VC.present(ivc, animated: true, completion: nil)
        }else{
            self.searchVC?.present(ivc, animated: true, completion: nil)
        }
        
    }
    
    func checkForFollow(){
        
        Constants.DB.user.child(AuthApi.getFirebaseUid()!).child("following/places").queryOrdered(byChild: "placeID").queryEqual(toValue: place!.id).observeSingleEvent(of: .value, with: {snapshot in
        
            if let data = snapshot.value as? [String:Any]{
                self.followButtonOut.isSelected = true
                self.followButtonOut.layer.borderWidth = 1
                self.followButtonOut.layer.borderColor = Constants.color.navy.cgColor
                self.followButtonOut.backgroundColor = UIColor.white
                self.followButtonOut.tintColor = UIColor.clear
                self.followButtonOut.layer.shadowOpacity = 0.5
                self.followButtonOut.layer.masksToBounds = false
                self.followButtonOut.layer.shadowColor = UIColor.black.cgColor
                self.followButtonOut.layer.shadowRadius = 5.0
            }
            else{
                self.followButtonOut.isSelected = false
                self.followButtonOut.layer.borderColor = UIColor.clear.cgColor
                self.followButtonOut.layer.borderWidth = 1
                self.followButtonOut.backgroundColor = UIColor(red: 20/255.0, green: 40/255.0, blue: 64/255.0, alpha: 1.0)
                self.followButtonOut.tintColor = UIColor.clear
                self.followButtonOut.layer.shadowOpacity = 0.5
                self.followButtonOut.layer.masksToBounds = false
                self.followButtonOut.layer.shadowColor = UIColor.black.cgColor
                self.followButtonOut.layer.shadowRadius = 5.0
            }
        })
    }
    
    func setRatingAmountForSearchPlaceCell(ratingAmount: Double){

        switch ratingAmount{
        case 0.0..<0.5:
            ratingsStarImage.image = #imageLiteral(resourceName: "small_0")
        case 0.5..<1.0:
            ratingsStarImage.image = #imageLiteral(resourceName: "small_1")
        case 1.0..<1.5:
            ratingsStarImage.image = #imageLiteral(resourceName: "small_1_half")
        case 1.5..<2.0:
            ratingsStarImage.image = #imageLiteral(resourceName: "small_2")
        case 2.0..<2.5:
            ratingsStarImage.image = #imageLiteral(resourceName: "small_2_half")
        case 2.5..<3.0:
            ratingsStarImage.image = #imageLiteral(resourceName: "small_3")
        case 3.0..<3.5:
            ratingsStarImage.image = #imageLiteral(resourceName: "small_3_half")
        case 3.5..<4.0:
            ratingsStarImage.image = #imageLiteral(resourceName: "small_4")
        case 4.0..<4.5:
            ratingsStarImage.image = #imageLiteral(resourceName: "small_4_half")
        case 4.5..<5.0:
            ratingsStarImage.image = #imageLiteral(resourceName: "small_5")
        default:
            break
        }
    }
    
}
