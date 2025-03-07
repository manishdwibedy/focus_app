    //
//  OtherUserProfileViewController.swift
//  FocusInterests
//
//  Created by Alex Jang on 7/12/17.
//  Copyright © 2017 singlefocusinc. All rights reserved.
//

import UIKit
import SDWebImage
import GeoFire
import FirebaseDatabase
import DataCache

protocol OtherUserProfileViewControllerDelegate {
    func hasSentUserAnInvite()
}

class OtherUserProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UINavigationBarDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, OtherUserProfileViewControllerDelegate{
    
    @IBOutlet weak var invitePopupTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var invitePopupView: UIView!
    @IBOutlet weak var followYourFriendsView: UIView!
    @IBOutlet weak var eventsCollectionView: UICollectionView!
    @IBOutlet var userScrollView: UIScrollView!
    @IBOutlet weak var otherEventStackView: UIStackView!
    @IBOutlet weak var otherPlaceStackView: UIStackView!
    @IBOutlet weak var eventsCollectionViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var placesTableView: UITableView!
    @IBOutlet weak var placesTableViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var eventsTableView: UITableView!
    @IBOutlet weak var eventsTableViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var recentPostStack: UIStackView!
    @IBOutlet weak var recentPostTableView: UITableView!
    @IBOutlet weak var recentPostTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var noRecentPostLabel: UILabel!
    
    @IBOutlet weak var navBarItem: UINavigationItem!
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBOutlet weak var userInfoView: UIView!
    
    // private user profile view
    var profileIsSetToPrivate = true
    @IBOutlet weak var privateUserProfileView: UIView!
    
    // User data
    //	@IBOutlet var userName: UILabel!
    @IBOutlet var descriptionText: UITextView!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    
    @IBOutlet weak var fullNameDescriptionStack: UIStackView!
    @IBOutlet weak var otherUserNameInterestTitleLabel: UILabel!
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    
    // follower and following
    @IBOutlet weak var followerStackView: UIStackView!
    @IBOutlet weak var followingStackView: UIStackView!
    @IBOutlet weak var followerLabel: UILabel!
    @IBOutlet weak var followerCount: UIButton!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var followingCount: UIButton!

    @IBOutlet weak var pinCount: UIButton!
    var pinInfo: pinData? = nil
    var userData: User? = nil
    
    // user interests
    
    var hiddenInterests = [UIView]()
    @IBOutlet weak var focusView: UIView!
    @IBOutlet weak var focusStackView: UIStackView!
    @IBOutlet weak var interestStackView: UIStackView!
    @IBOutlet weak var interestViewHeight: NSLayoutConstraint!
    @IBOutlet weak var containerStackForMoreOrLessButtons: UIView!
    @IBOutlet weak var containStackForMoreOrLessButtonsHeight: NSLayoutConstraint!
    @IBOutlet weak var moreOrLessButtonStack: UIStackView!
    @IBOutlet weak var moreOrLessButtonStackHeight: NSLayoutConstraint!
    @IBOutlet weak var lessButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    
    // Location Description (would this be location description?)
    // Location FOCUS button (what would this be for?)
    // Collection view See more... button
    @IBOutlet weak var moreEventsButton: UIButton!
    // (and also any of the ones after)
    @IBOutlet weak var eventView: UIView!
    @IBOutlet weak var eventsStackView: UIStackView!
    @IBOutlet weak var moreEventsStack: UIView!
    @IBOutlet weak var eventHeader: UILabel!
    
    var followers = [User]()
    var following = [User]()
    var interestArray = [Interest]()
    
    var suggestion = [Event]()
    let geoFire = GeoFire(firebaseRef: Database.database().reference().child("event_locations"))
    
    var otherUser = false
    var userID = ""
    var previous: previousScreen? = nil
    var userInfo = [String:Any]()
    var userImageURL = ""
    
    let screenSize = UIScreen.main.bounds
    var screenWidth: CGFloat = 0.0
    var screenHeight: CGFloat = 0.0
    var showInvitePopup = false
    
    var suggestedEvents = [Event]()
    var suggestedPlaces = [Place]()
    
    var pinImage: UIImage?
    
    var ticketMasterDF = DateFormatter()
    var eventDF = DateFormatter()
    
    var placesIFollow = [Place]()
    var eventsIAttend = [Event]()
    var hasPinImage = false
    var delegate: showMarkerDelegate?
    
    // Back button
    @IBAction func backButton(_ sender: Any) {
        if otherUser, let previous = previous{
            switch(previous){
            case .people:
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let VC = storyboard.instantiateViewController(withIdentifier: "home") as? HomePageViewController
                VC?.showTab = 1
                self.present(VC!, animated: true, completion: nil)
            case .notification:
                let storyboard = UIStoryboard(name: "Notif_Invite_Feed", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "NotifViewController") as! NotificationFeedViewController
                
                dropfromTop(view: self.view)
                
                self.present(vc, animated: true, completion: nil)
            }
        }
        else if otherUser{
            self.dismiss(animated: true, completion: nil)
        }
        else{
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let VC = storyboard.instantiateViewController(withIdentifier: "home") as? HomePageViewController
            
            self.present(VC!, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func moreButtonPressed(_ sender: UIButton) {
        let selectInterests = InterestsViewController(nibName: "InterestsViewController", bundle: nil)
        self.present(selectInterests, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.screenWidth = self.screenSize.width
        self.screenHeight = self.screenSize.height
        self.invitePopupView.center.y = self.screenHeight - 20
        self.invitePopupTopConstraint.constant = self.screenHeight - 20
        self.invitePopupView.layer.cornerRadius = 10.0
        
        self.recentPostTableView.dataSource = self
        self.recentPostTableView.delegate = self

        let recentPostNib = UINib(nibName: "FeedOneTableViewCell", bundle: nil)
        self.recentPostTableView.register(recentPostNib, forCellReuseIdentifier: "recentPostCell")
        
        self.placesTableView.dataSource = self
        self.placesTableView.delegate = self

        let placeNib = UINib(nibName: "InvitePeoplePlaceCell", bundle: nil)
        self.placesTableView.register(placeNib, forCellReuseIdentifier: "InvitePeoplePlaceCell")
        
        self.eventsTableView.dataSource = self
        self.eventsTableView.delegate = self
        
        let eventNib = UINib(nibName: "InvitePeopleEventCell", bundle: nil)
        self.eventsTableView.register(eventNib, forCellReuseIdentifier: "InvitePeopleEventCell")
        
        
        // Do any additional setup after loading the view.
        let attrs = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont(name: "Avenir-Black", size: 18)!
        ]
        
        self.view.backgroundColor = Constants.color.navy
        self.navBar.barTintColor = Constants.color.navy
        self.navBar.titleTextAttributes = attrs
        
        self.followButton.roundCorners(radius: 5.0)
        self.followButton.setTitle("Follow", for: .normal)
        self.followButton.setTitleColor(UIColor.white, for: .normal)
        self.followButton.setTitle("Following", for: .selected)
        self.followButton.setTitleColor(UIColor.white, for: .selected)
        
        self.inviteButton.roundCorners(radius: 5.0)
        
        self.messageButton.roundCorners(radius: 5.0)
        hideKeyboardWhenTappedAround()
        
        let eventsCollectionNib = UINib(nibName: "UserProfileCollectionViewCell", bundle: nil)
        self.eventsCollectionView.register(eventsCollectionNib, forCellWithReuseIdentifier: "eventsCollectionCell")
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.showFollowing))
        followingStackView.isUserInteractionEnabled = true
        followingStackView.addGestureRecognizer(tap)
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(self.showFollower))
        followerStackView.isUserInteractionEnabled = true
        followerStackView.addGestureRecognizer(tap1)
        
        //      Use tags in order to allow for only IBAction that will track
        //      each event based on the tag of the sender

        self.moreEventsButton.tag = 3

        self.roundImagesAndButtons()
        
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont(name: "Avenir Book", size: 21)!]
        
        ticketMasterDF.dateFormat = "yyyy-MM-dd HH:mm:ss"
        eventDF.dateFormat = "MMM d, hh:mm a"
        
        getEvents()
//        getPin()
        
        Constants.DB.user.child(AuthApi.getFirebaseUid()!).child("following/people").queryOrdered(byChild: "UID").queryEqual(toValue: userID).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? [String:Any]
            
            if value != nil{
                self.followButton.isSelected = true
                self.followButton.layer.borderWidth = 1
                self.followButton.layer.borderColor = UIColor.white.cgColor
                self.followButton.backgroundColor = UIColor(red: 20/255.0, green: 40/255.0, blue: 64/255.0, alpha: 1.0)
                self.followButton.tintColor = UIColor.clear
                self.followButton.layer.shadowOpacity = 0.5
                self.followButton.layer.masksToBounds = false
                self.followButton.layer.shadowColor = UIColor.black.cgColor
                self.followButton.layer.shadowRadius = 5.0
                
                self.privateUserProfileView.isHidden = true
                var eventTableFrame = self.eventsTableView.frame
                eventTableFrame.size.height = self.eventsTableView.contentSize.height
                self.eventsTableView.frame = eventTableFrame
                
                var placesTableFrame = self.placesTableView.frame
                placesTableFrame.size.height = self.placesTableView.contentSize.height
                self.placesTableView.frame = placesTableFrame
            }
            else{
                if self.userData!.isPrivate{
                    if self.profileIsSetToPrivate{
                        self.otherPlaceStackView.isHidden = true
                        self.otherEventStackView.isHidden = true
                        self.eventsStackView.isHidden = true
                        self.recentPostTableView.isHidden = true
                        self.focusView.isHidden = true
                        self.eventView.isHidden = true
                    }
                    else{
                        self.privateUserProfileView.isHidden = true
                        var eventTableFrame = self.eventsTableView.frame
                        eventTableFrame.size.height = self.eventsTableView.contentSize.height
                        self.eventsTableView.frame = eventTableFrame
                        var placesTableFrame = self.placesTableView.frame
                        placesTableFrame.size.height = self.placesTableView.contentSize.height
                        self.placesTableView.frame = placesTableFrame
                    }
                }
                else{
                    self.privateUserProfileView.isHidden = true
                    var eventTableFrame = self.eventsTableView.frame
                    eventTableFrame.size.height = self.eventsTableView.contentSize.height
                    self.eventsTableView.frame = eventTableFrame
                    
                    var placesTableFrame = self.placesTableView.frame
                    placesTableFrame.size.height = self.placesTableView.contentSize.height
                    self.placesTableView.frame = placesTableFrame
                }
            }
        })
        
        let ID = otherUser ? self.userID : AuthApi.getFirebaseUid()!
        Constants.DB.pins.child(ID).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            if let value = value
            {
                self.recentPostStack.removeArrangedSubview(self.noRecentPostLabel)
                self.noRecentPostLabel.isHidden = true
                self.pinInfo = pinData(UID: value["fromUID"] as! String, dateTS: value["time"] as! Double, pin: value["pin"] as! String, location: value["formattedAddress"] as! String, lat: value["lat"] as! Double, lng: value["lng"] as! Double, path: Constants.DB.pins.child(ID ), focus: value["focus"] as? String ?? "")
                self.recentPostTableView.reloadData()
                    if let likes = value["like"] as? [String:Any]{
                        let count = likes["num"] as? Int
                        
                        var label = "like"
                        if count! > 1{
                            label = "likes"
                        }
                    }
                    
        
                    if let images = value["images"] as? NSDictionary{
                        print("images \(images)")
                        self.hasPinImage = true
                        var firstVal = ""
                        for (key,_) in images
                        {
                            firstVal = key as! String
                            break
                        }
                        
                        let reference = Constants.storage.pins.child((images[firstVal] as! NSDictionary)["imagePath"] as! String)
                        reference.downloadURL(completion: { (url, error) in
                            
                            if error != nil {
                                print(error?.localizedDescription ?? "")
                                return
                            }
                            print("images \(url)")
                            SDWebImageManager.shared().downloadImage(with: url, options: .continueInBackground, progress: {
                                (receivedSize :Int, ExpectedSize :Int) in
                                
                            }, completed: {
                                (image : UIImage?, error : Error?, cacheType : SDImageCacheType, finished : Bool, url : URL?) in
                                
                                if image != nil && finished{
                                    self.pinImage = image
                                    
                                    guard let recentPostCell = self.recentPostTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? FeedOneTableViewCell else{
                                        print("no recent post ")
                                        return
                                    }
                                    
                                    
                                    let pinImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: recentPostCell.feedOneStackView.frame.width, height: 345))
                                    let recentPostImageView = UIView(frame: CGRect(x: 0, y: 0, width: recentPostCell.feedOneStackView.frame.width, height: 355))
                                    
                                    pinImageView.image = image
                                    pinImageView.center = CGPoint(x: recentPostImageView.bounds.size.width  / 2, y: recentPostImageView.bounds.size.height / 2)
                                    
                                    recentPostImageView.addSubview(pinImageView)
                                    recentPostCell.feedOneStackView.insertArrangedSubview(recentPostImageView, at: 1)
                                    recentPostCell.frame.size.width = self.view.frame.width
                                    recentPostCell.frame.size.height += 325
                                    self.recentPostTableViewHeight.constant += 325
                                    print("images \(self.pinImage)")
                                }
                            })
                        })
                    }
            }else{
                self.recentPostStack.removeArrangedSubview(self.recentPostTableView)
                self.recentPostTableView.isHidden = true
            }
        })
        
        let pinDetail = UITapGestureRecognizer(target: self, action: #selector(self.showPin))
//        pinView.isUserInteractionEnabled = true
//        pinView.addGestureRecognizer(pinDetail)
        self.eventView.bounds.size.height += (self.eventsCollectionView.contentSize.height)
        let infoButton = UIButton(type: .infoLight)
        
        // You will need to configure the target action for the button itself, not the bar button itemr
        infoButton.tintColor = UIColor.white
        infoButton.addTarget(self, action: #selector(showUserBlockAlertAction), for: .touchUpInside)
        
        // Create a bar button item using the info button as its custom view
        let infoBarButtonItem = UIBarButtonItem(customView: infoButton)
        
        // Use it as required
        self.navBar.topItem?.rightBarButtonItem = infoBarButtonItem

    }
    
    func showUserBlockAlertAction(){
        let unfollowAlertController = UIAlertController(title: "Block \(self.userInfo["username"]!)?", message: nil, preferredStyle: .actionSheet)
        
        
        let unfollowAction = UIAlertAction(title: "Block", style: .destructive) { action in
            User.blockUser(uid: self.userID)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
            print("cancel has been tapped")
        }
        
        unfollowAlertController.addAction(unfollowAction)
        unfollowAlertController.addAction(cancelAction)
        self.present(unfollowAlertController, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.displayUserData()
        
        print("has pin image \(self.hasPinImage)")
    }
    
    //    MARK: COLLECTIONVIEW DELEGATE METHODS
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.suggestion.count > 9 ? 9 : self.suggestion.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let eventCell = collectionView.dequeueReusableCell(withReuseIdentifier: "eventsCollectionCell", for: indexPath) as!UserProfileCollectionViewCell
        
        if indexPath.row == 0{
            self.eventsCollectionViewHeight.constant = eventCell.frame.height
        }else if indexPath.row == 3 || indexPath.row == 5{
            self.eventsCollectionViewHeight.constant += (eventCell.frame.height + 20)
        }
        
        let suggestion = self.suggestion[indexPath.row]
        eventCell.userEventsLabel.text = suggestion.title
        
        // Placeholder image
        let placeholderImage = UIImage(named: "empty_event")
        
        eventCell.userEventsLabel.text = "Event \((indexPath.row+1))"
        
        eventCell.userEventsLabel.text = suggestion.title
        
        let reference = Constants.storage.event.child("\(suggestion.id!).jpg")
        
        reference.downloadURL(completion: { (url, error) in
            
            if error != nil {
                print(error?.localizedDescription ?? "")
                return
            }
            
            eventCell.userEventsImage.sd_setImage(with: url, placeholderImage: placeholderImage)
            eventCell.userEventsImage.setShowActivityIndicator(true)
            eventCell.userEventsImage.setIndicatorStyle(.gray)
        })

        return eventCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let suggestion = self.suggestion[indexPath.row]
        
        let storyboard = UIStoryboard(name: "EventDetails", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "eventDetailVC") as! EventDetailViewController
        controller.event = suggestion
        self.present(controller, animated: true, completion: nil)
    }
    
    func showFollowing(sender:UITapGestureRecognizer) {
        let followerViewController = UIStoryboard(name: "Followers", bundle: nil).instantiateViewController(withIdentifier: "FollowersViewController") as! FollowersViewController
        followerViewController.windowTitle = "Following"
        followerViewController.ID = self.userID
        self.present(followerViewController, animated: true, completion: nil)
    }
    
    func showFollower(sender:UITapGestureRecognizer) {
        let followerViewController = UIStoryboard(name: "Followers", bundle: nil).instantiateViewController(withIdentifier: "FollowersViewController") as! FollowersViewController
        followerViewController.windowTitle = "Followers"
        followerViewController.ID = self.userID
        self.present(followerViewController, animated: true, completion: nil)
    }
    
    func showPin(sender: UITapGestureRecognizer){
        let storyboard = UIStoryboard(name: "Pin", bundle: nil)
        let ivc = storyboard.instantiateViewController(withIdentifier: "PinLookViewController") as! PinLookViewController
        ivc.data = self.pinInfo
        self.present(ivc, animated: true, completion: { _ in })
    }
    
    func displayUserData() {
        let ID = otherUser ? self.userID : AuthApi.getFirebaseUid()!
        Constants.DB.user.child(ID).observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionnary = snapshot.value as? NSDictionary {
                
                self.userInfo = (dictionnary as? [String:Any])!
                //                print(dictionnary)
                let username_str = dictionnary["username"] as? String ?? ""
                let description_str = dictionnary["description"] as? String ?? ""
                let image_string = dictionnary["image_string"] as? String ?? ""
                self.userImageURL = image_string
                let fullname = dictionnary["fullname"] as? String ?? ""
                
                
                self.userImage.image = #imageLiteral(resourceName: "placeholder_people")
                if let url = URL(string: image_string){
                    SDWebImageManager.shared().downloadImage(with: url, options: .continueInBackground, progress: {
                        (receivedSize :Int, ExpectedSize :Int) in
                        
                    }, completed: {
                        (image : UIImage?, error : Error?, cacheType : SDImageCacheType, finished : Bool, url : URL?) in
                        
                        if image != nil && finished{
                            self.userImage.image = crop(image: image!, width: 85, height: 85)
                        }
                    })
                }
                
//                SAMPLE description text

                self.fullNameLabel.text = fullname
                
                if self.descriptionText.text == ""{
                    self.fullNameDescriptionStack.removeArrangedSubview(self.descriptionText)
                    self.descriptionText.removeFromSuperview()
                }else{
                    self.fullNameDescriptionStack.insertArrangedSubview(self.descriptionText, at: 1)
                    self.descriptionText.textContainer.maximumNumberOfLines = 3
                    self.descriptionText.textContainer.lineBreakMode = .byTruncatingTail
                    self.descriptionText.text = description_str
                }
                
                self.otherUserNameInterestTitleLabel.text = "\(username_str)\'s FOCUS"
                
                self.navBarItem.title = username_str
                
                if let followersData = dictionnary["followers"] as? [String:Any]{
                    if let users = followersData["people"] as? [String:[String:Any]]{
                        let count = users.count
                        
                        for (_,user) in users{
                            Constants.DB.user.child(user["UID"] as! String).observeSingleEvent(of: .value, with: {snapshot in
                                if let data = snapshot.value as? [String:Any]{
                                    if let user = User.toUser(info: data){
                                        self.followers.append(user)
                                    }
                                }
                            })
                        }
                        
                        
                        self.followerCount.setTitle("\(count)", for: .normal)
                    }
                }
                
                if let followersData = dictionnary["following"] as? [String:Any]{
                    if let users = followersData["people"] as? [String:[String:Any]]{
                        let count = users.count
                        
                        for (_,user) in users{
                            Constants.DB.user.child(user["UID"] as! String).observeSingleEvent(of: .value, with: {snapshot in
                                if let data = snapshot.value as? [String:Any]{
                                    if let user = User.toUser(info: data){
                                        self.followers.append(user)
                                    }
                                }
                            })
                        }
                        
                        self.followingCount.setTitle("\(count)", for: .normal)
                    }
                }
                
                if let pinCount = dictionnary["pinCount"] as? Int{
                    self.pinCount.setTitle("\(pinCount)", for: .normal)
                }
                else{
                    self.pinCount.setTitle("0", for: .normal)
                }
                
                
                
                if self.otherUser{
                    if let interests = dictionnary["interests"] as? String{
                        let selected = interests.components(separatedBy: ",")
                        let matching = matchingUserInterest(user: self.userData!)
                        
                        var final_interest = [String]()
                        for interest in matching{
                            final_interest.append(interest.name!)
                        }
                
                        if self.suggestedPlaces.count < 3{
                            getFollowingPlace(uid: self.userID, limit: 3, gotPlaces: { placesUserFollows in
                                print(placesUserFollows)
                                let user_interest_set = Set<Place>(self.placesIFollow)
                                let other_user = Set<Place>(placesUserFollows)
                                
                                let common = Array(other_user.intersection(user_interest_set))
                                if common.count >= 3{
                                    if self.suggestedPlaces.count < 3{
                                        self.suggestedPlaces = Array(common[0..<3])
                                        self.placesTableView.reloadData()
                                    }
                                }
                                else{
                                    if other_user.count >= 3{
                                        if self.suggestedPlaces.count < 3{
                                            self.suggestedPlaces = Array(placesUserFollows[0..<3])
                                            self.placesTableView.reloadData()
                                        }
                                    }
                                    else if user_interest_set.count >= 3{
                                        if self.suggestedPlaces.count < 3{
                                            self.suggestedPlaces = Array(self.placesIFollow[0..<3])
                                            self.placesTableView.reloadData()
                                        }
                                        
                                    }
                                    else{
                                        getSuggestedPlaces(interests: final_interest.joined(separator: ","), limit: 3, gotPlaces: {places in
                                            if places.count >= 3{
                                                if self.suggestedPlaces.count < 3{
                                                    self.suggestedPlaces = places
                                                    self.placesTableView.reloadData()
                                                }
                                            }
                                            else{
                                                getSuggestedPlaces(interests: "Food", limit: 3, gotPlaces: {places in
                                                    if self.suggestedPlaces.count < 3{
                                                        self.suggestedPlaces = places
                                                        self.placesTableView.reloadData()
                                                    }
                                                    
                                                })
                                            }
                                        })
                                    }
                                }
                            })
                        }
                        
                        if self.suggestedEvents.count < 3{
                            getAttendingEvent(uid: self.userID, gotEvents: { placesUserFollows in
                                let user_interest_set = Set<Event>(self.eventsIAttend)
                                let other_user = Set<Event>(placesUserFollows)
                                
                                let common = Array(other_user.intersection(user_interest_set))
                                if common.count >= 3{
                                    self.suggestedEvents = Array(common[0..<3])
                                    self.eventsTableView.reloadData()
                                }
                                else{
                                    if other_user.count >= 3{
                                        self.suggestedEvents = Array(placesUserFollows[0..<3])
                                        self.eventsTableView.reloadData()
                                    }
                                    else if user_interest_set.count >= 3{
                                        self.suggestedEvents = Array(self.eventsIAttend[0..<3])
                                        self.eventsTableView.reloadData()
                                    }
                                    else{
                                        getSuggestedEvents(interests: final_interest.joined(separator: ","), limit: 3, gotEvents: {events in
                                            if events.count >= 3{
                                                self.suggestedEvents = events
                                                self.eventsTableView.reloadData()
                                            }
                                            else{
                                                getSuggestedEvents(interests: "Food", limit: 3, gotEvents: {events in
                                                    self.suggestedEvents = events
                                                    self.eventsTableView.reloadData()
                                                })
                                            }
                                        })
                                    }
                                }
                            })
                        }
                        
                       
                    
//                        getSuggestedEvents(interests: final_interest.joined(separator: ","), limit: 3, gotEvents: {events in
//                            self.suggestedEvents = events
//                            self.eventsTableView.reloadData()
//                        })
//                        
//                        getSuggestedPlaces(interests: final_interest.joined(separator: ","), limit: 3, gotPlaces: {places in
//                            self.suggestedPlaces = places
//                            self.placesTableView.reloadData()
//                        })
                        
                        print("final_interest \(final_interest)")
                        
                        print("selected \(selected)")
                        
                        for interestViews in self.interestStackView.arrangedSubviews{
                            self.interestStackView.removeArrangedSubview(interestViews)
                            interestViews.removeFromSuperview()
                        }
                        
                        let user_interest = Set(getUserInterests().components(separatedBy: ","))
                        
                        for (index, interest) in (final_interest.enumerated()){

                            let interestLabelView = InterestStackViewLabel(frame: CGRect(x: 0, y: 0, width: self.interestStackView.bounds.width, height: 30))
                            
                            if interest.characters.count > 0{
                                interestLabelView.view.bounds.size.width = self.interestStackView.frame.size.width
                                interestLabelView.view.center = interestLabelView.center
                                interestLabelView.interestLabel.text = interest
                                
                                if user_interest.contains(interest){
                                    interestLabelView.addButton.setImage(#imageLiteral(resourceName: "Green_check_sign"), for: .normal)
                                }
                                
                                let interestImage = "\(interest) Green"
                                interestLabelView.interestLabelImage.image = UIImage(named: interestImage)
                                if index < 3{
                                    print("adding interests less than 3")
                                    self.interestStackView.addArrangedSubview(interestLabelView)
                                    self.interestStackView.translatesAutoresizingMaskIntoConstraints = false
                                }else{
                                    print("adding interests to hidingInterests array")
                                    self.hiddenInterests.append(interestLabelView)
                                }
                            }
                        }
                        
                        guard let firstFocusView = self.interestStackView.arrangedSubviews.first else {
                            return
                        }
                        
                        if self.interestStackView.arrangedSubviews.count <= 1{
                            self.interestViewHeight.constant = firstFocusView.frame.height
                        }else{
                            self.interestViewHeight.constant = CGFloat((firstFocusView.frame.height + 15) * CGFloat(self.interestStackView.arrangedSubviews.count))
                        }
                        
                        if selected.count > 3 {
                            self.containerStackForMoreOrLessButtons.isHidden = false
                            self.focusStackView.addArrangedSubview(self.containerStackForMoreOrLessButtons)
                            self.moreOrLessButtonStack.removeArrangedSubview(self.lessButton)
                            self.lessButton.isHidden = true
                            self.containStackForMoreOrLessButtonsHeight.constant = 20
                            self.moreOrLessButtonStackHeight.constant = 20.0
//                            self.lessButton.removeFromSuperview()
                        }else{
                            self.containerStackForMoreOrLessButtons.isHidden = true
                            self.focusStackView.removeArrangedSubview(self.containerStackForMoreOrLessButtons)

                        }
                        
                    }
                }
            }
            
        })
        
        if !otherUser{
            let interests = getUserInterests().components(separatedBy: ",")
            
            print("!otherUser condition: \(self.interestStackView.arrangedSubviews.count)")
            
            if interestStackView.arrangedSubviews.count > 0{
                var endIndex = interestStackView.arrangedSubviews.count-1
                while endIndex >= 0{
                    interestStackView.arrangedSubviews[endIndex].removeFromSuperview()
                    endIndex -= 1
                }
            }
            
            for (_, interest) in (interests.enumerated()){
                
                let textLabel = UILabel()
                
                textLabel.textColor = .white
                textLabel.text  = interest
                textLabel.textAlignment = .left
                
                if interest.characters.count > 0{
                    if interestStackView.arrangedSubviews.count < 3{
                        let interestView = InterestStackViewLabel()
                        interestView.interestLabel.text = interest
                        let interestSubView = UIView(frame: CGRect(x: 0, y: 0, width: self.interestStackView.frame.size.width, height: 20))
                        
                        interestSubView.addSubview(interestView)
                        self.interestStackView.addArrangedSubview(interestSubView)
                        interestStackView.translatesAutoresizingMaskIntoConstraints = false
                    }
                }
            }
        }
        
    }
    
    @IBAction func moreInterestsButtonPressed(_ sender: Any) {
        print("adding these interests \(self.hiddenInterests)")
        
        if self.hiddenInterests.count > 0{
            for interestViewIndex in 0...self.hiddenInterests.count-1{
                self.interestStackView.addArrangedSubview(self.hiddenInterests[interestViewIndex])
            }
            
            guard let firstFocusView = self.interestStackView.arrangedSubviews.first else {
                return
            }
            
            self.interestViewHeight.constant = CGFloat((firstFocusView.bounds.size.height) * CGFloat(self.interestStackView.arrangedSubviews.count))
            
            self.lessButton.isHidden = false
            self.moreOrLessButtonStack.addArrangedSubview(self.lessButton)
            self.moreOrLessButtonStack.removeArrangedSubview(self.moreButton)
            self.moreButton.isHidden = true
            self.containStackForMoreOrLessButtonsHeight.constant = 20
            self.moreOrLessButtonStackHeight.constant = 20.0
        }else{
            print("nothing to add")
        }
        
    }
    
    @IBAction func lessInterestsButtonPressed(_ sender: Any) {
        print("")
        print("")
        print("removing these interests from stackview \(self.hiddenInterests)")
        print("")
        print("")
        for arrangedInterestIndex in 0...self.hiddenInterests.count-1{
            self.interestStackView.removeArrangedSubview(self.hiddenInterests[arrangedInterestIndex])
        }
        
        guard let firstFocusView = self.interestStackView.arrangedSubviews.first else {
            return
        }
        
        self.interestViewHeight.constant = CGFloat((firstFocusView.bounds.size.height) * CGFloat(self.interestStackView.arrangedSubviews.count))
        
        self.moreButton.isHidden = false
        self.moreOrLessButtonStack.addArrangedSubview(self.moreButton)
        self.moreOrLessButtonStack.removeArrangedSubview(self.lessButton)
        self.lessButton.isHidden = true
        self.containStackForMoreOrLessButtonsHeight.constant = 20
        self.moreOrLessButtonStackHeight.constant = 20.0
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if showInvitePopup {
            //            self.view.bringSubview(toFront: self.invitePopupView)
            UIView.animate(withDuration: 1, delay: 0.0, options: .curveEaseInOut, animations: {
                self.invitePopupView.center.y -= self.invitePopupView.frame.size.height
                self.invitePopupTopConstraint.constant -= self.invitePopupView.frame.size.height
            }, completion: { animate in
                UIView.animate(withDuration: 1, delay: 3.0, options: .curveEaseInOut, animations: {
                    self.invitePopupView.center.y += self.invitePopupView.frame.size.height
                    self.invitePopupTopConstraint.constant += self.invitePopupView.frame.size.height
                }, completion: nil)
            })
            self.showInvitePopup = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //    @IBAction func settingsButtonTapped(_ sender: UIBarButtonItem) {
    //        let vc = SettingsViewController(nibName: "SettingsViewController", bundle: nil)
    //        self.present(vc, animated: true, completion: nil)
    //    }
    
    
    func getPin() {
        
        Constants.DB.pins.child(AuthApi.getFirebaseUid()!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            if let value = value
            {
//                self.pinAddress2Label.text = value["pin"] as? String
                if let likes = value["like"] as? NSDictionary{
                    if let likeCount = likes["num"] as? Int{
                        var likeLabel = "like"
                        if likeCount > 1{
                            likeLabel.append("s")
                        }
//                        self.pinLikesLabel.text = "\(likeCount) \(likeLabel)"
                    }
                }
                
                let pin_location = CLLocation(latitude: value["lat"] as! Double, longitude: value["lng"] as! Double)
//                self.pinDistanceLabel.text = getDistance(fromLocation: pin_location, toLocation: AuthApi.getLocation()!)
            }
        })
    }
    
    @IBAction func updatePin(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Pin", bundle: nil)
        let VC = storyboard.instantiateViewController(withIdentifier: "Home") as? PinScreenViewController
        self.present(VC!, animated: true, completion: nil)
    }
    
    func getEvents(){
        self.moreEventsButton.isHidden = false
        
        let ID = otherUser ? self.userID : AuthApi.getFirebaseUid()!
        Constants.DB.event.queryOrdered(byChild: "creator").queryEqual(toValue: ID).queryLimited(toLast: 4).observeSingleEvent(of: .value, with: { snapshot in
            let eventInfo = snapshot.value as? [String : Any]
            
            if let eventInfo = eventInfo{
                _ = eventInfo.count
                for (id, eventData) in eventInfo{
                    if let info = eventData as? [String:Any]{
                        if let event = Event.toEvent(info: info){
                            event.id = id
                            self.suggestion.append(event)
                        }
                    }
                }
            }
            
            if self.suggestion.count > 9{
                self.moreEventsButton.isHidden = false
                self.eventsStackView.addArrangedSubview(self.moreEventsStack)
            }else{
                self.moreEventsButton.isHidden = true
                self.eventsStackView.removeArrangedSubview(self.moreEventsStack)
                self.moreEventsStack.removeFromSuperview()
            }
            self.eventsCollectionView.reloadData()
        })
        
        Constants.DB.user.child(AuthApi.getFirebaseUid()!).child("invitations/event").queryOrdered(byChild: "status").queryEqual(toValue: "accepted").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            
            if let placeData = value{
                let count = placeData.count
                for (_,place) in placeData
                {
                    let id = (place as? [String:Any])?["ID"]
                    
                    Constants.DB.event.child(id as! String).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let info = snapshot.value as? [String : Any], info.count > 0{
                            let event = Event.toEvent(info: info)
                            event?.id = id as! String
                            
                            let eventLocation = CLLocation(latitude: Double((info["longitude"])! as! String)!, longitude: Double((info["longitude"])! as! String)!)
                            
                            event?.distance = eventLocation.distance(from: AuthApi.getLocation()!)
                            if let attending = info["attendingList"] as? [String:Any]{
                                event?.setAttendessCount(count: attending.count)
                            }
                            
                            
                            self.suggestion.append(event!)
                            if self.suggestion.count == count{
                                
                                if self.suggestion.count > 9{
                                    self.moreEventsButton.isHidden = false
                                }
                                else{
                                    if self.moreEventsButton != nil{
                                        self.moreEventsButton.isHidden = true
                                    }
                                }
                                
                                self.eventsCollectionView.reloadData()
                            }
                            
                        }
                        
                        
                    })
                }
            }
        })
    }
    
    func roundImagesAndButtons(){
//        self.updatePinButton.roundCorners(radius: 10.0)
        
        self.userImage.layer.borderWidth = 2
        self.userImage.layer.borderColor = UIColor(red: 122/255.0, green: 201/255.0, blue: 1/255.0, alpha: 1.0).cgColor
        self.userImage.roundedImage()
        
//        self.pinImage.layer.borderWidth = 1
//        self.pinImage.layer.borderColor = UIColor(red: 122/255.0, green: 201/255.0, blue: 1/255.0, alpha: 1.0).cgColor
//        self.pinImage.roundedImage()
        
//        self.editButton.layer.borderWidth = 1
//        self.editButton.layer.borderColor = UIColor.white.cgColor
//        self.editButton.roundCorners(radius: 5.0)
        
        self.moreEventsButton.layer.borderWidth = 1
        self.moreEventsButton.layer.borderColor = UIColor.white.cgColor
        self.moreEventsButton.roundCorners(radius: 5.0)
    }
    
    @IBAction func createPin(_ sender: Any) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc: UITabBarController = mainStoryboard.instantiateViewController(withIdentifier: "home") as! UITabBarController
        vc.selectedIndex = 2
        self.present(vc, animated: true, completion: nil)
    }
    
    //    MARK: TableView Delegate and Data Source Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 0{
            return suggestedPlaces.count
        }
        else if tableView.tag == 1{
            return suggestedEvents.count
        }else{
            if self.pinInfo == nil{
                return 0
            }
            else{
                return 1
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "InvitePeoplePlaceCell", for: indexPath) as! InvitePeoplePlaceCell
            self.placesTableViewHeight.constant = (cell.frame.size.height * CGFloat(indexPath.row + 1))
            
            let place_cell = self.suggestedPlaces[indexPath.row]
            
            cell.place = place_cell
            cell.placeNameLabel.text = place_cell.name
            cell.otherUser = self
            // cell.place = place
            
            if place_cell.address.count > 0{
                if place_cell.address.count == 1{
                    cell.addressTextView.text = "\(place_cell.address[0])"
                }
                else{
                    cell.addressTextView.text = "\(place_cell.address[0])\n\(place_cell.address.last!)"
                }
            }
            
            let date = Date()
            let calendar = Calendar.current
            
            let day = calendar.component(.weekday, from: date)
            
            cell.setRatingAmount(ratingAmount: Double(place_cell.rating))
            
            cell.ratingLabel.text = "\(place_cell.rating) (\(place_cell.reviewCount) reviews)"
            
            if let hour = place_cell.getHour(day: day){
                cell.dateAndTimeLabel.text = "\(convert24HourTo12Hour(hour.start)) - \(convert24HourTo12Hour(hour.end))"
            }
            
            let place_location = CLLocation(latitude: place_cell.latitude, longitude: place_cell.longitude)
            cell.distanceLabel.text = getDistance(fromLocation: place_location, toLocation: AuthApi.getLocation()!)
            if place_cell.categories.count > 0{
                addGreenDot(label: cell.categoryLabel, content: getInterest(yelpCategory: place_cell.categories[0].alias))
            }
            
            
            cell.checkForFollow()
            if let url = URL(string: place_cell.image_url){
                SDWebImageManager.shared().downloadImage(with: url, options: .continueInBackground, progress: {
                    (receivedSize :Int, ExpectedSize :Int) in
                    
                }, completed: {
                    (image : UIImage?, error : Error?, cacheType : SDImageCacheType, finished : Bool, url : URL?) in
                    
                    if image != nil && finished{
                        cell.placeImage.image = crop(image: image!, width: 50, height: 50)
                    }
                })
                
            }
            
            cell.inviteFromOtherUserProfile = true
            cell.inPlacesTheyllLike = true
            cell.UID = (self.userInfo["firebaseUserId"] as? String)!
            cell.username = (self.userInfo["username"] as? String)!
            cell.otherUser = self
            
            return cell
        }else if tableView.tag == 1{
            let cell = tableView.dequeueReusableCell(withIdentifier: "InvitePeopleEventCell", for: indexPath) as! InvitePeopleEventCell
            
            let event = self.suggestedEvents[indexPath.row]
            self.eventsTableViewHeight.constant = (cell.frame.size.height * CGFloat(indexPath.row + 1))
            
            cell.name.text = event.title
            cell.address.text = event.fullAddress?.replacingOccurrences(of: ";;", with: "\n")
            
            if let category = event.category{
                if category.contains(","){
                    addGreenDot(label: cell.interest, content: category.components(separatedBy: ",")[0])
                }
                else{
                    addGreenDot(label: cell.interest, content: category)
                }
            }
            
            cell.inviteFromOtherUserProfile = true
            cell.inEventsTheyllLike = true
            
            cell.event = event
            cell.UID = self.userInfo["firebaseUserId"] as? String
            cell.username = (self.userInfo["username"] as? String)!
            cell.otherUser = self
            
            cell.guestCount.isHidden = true
            
            //            Date formatter for date and time label in event
            cell.price.text = event.price == nil || event.price == 0 ? "Free" : "$\(event.price!)"
            
            let eventLocation = CLLocation(latitude: Double(event.latitude!)!, longitude: Double(event.longitude!)!)
            cell.distance.text = getDistance(fromLocation: eventLocation, toLocation: AuthApi.getLocation()!)
            
            if let date = self.ticketMasterDF.date(from: event.date!){
                cell.dateAndTimeLabel.text = eventDF.string(from: date)
            }
            else{
                cell.dateAndTimeLabel.text = event.date!
            }
            
            
            if (event.creator?.characters.count)! > 0{
                let reference = Constants.storage.event.child("\(event.id!).jpg")
                
                cell.eventImage.image = crop(image: #imageLiteral(resourceName: "empty_event"), width: 50, height: 50)
                
                reference.downloadURL(completion: { (url, error) in
                    
                    if error != nil {
                        print(error?.localizedDescription ?? "")
                        return
                    }
                    
                    
                    SDWebImageManager.shared().downloadImage(with: url, options: .continueInBackground, progress: {
                        (receivedSize :Int, ExpectedSize :Int) in
                        
                    }, completed: {
                        (image : UIImage?, error : Error?, cacheType : SDImageCacheType, finished : Bool, url : URL?) in
                        
                        if image != nil && finished{
                            cell.eventImage.image = crop(image: image!, width: 50, height: 50)
                        }
                    })
                    
                    
                })
            }
            else{
                if let url = URL(string: event.image_url!){
                    SDWebImageManager.shared().downloadImage(with: url, options: .continueInBackground, progress: {
                        (receivedSize :Int, ExpectedSize :Int) in
                        
                    }, completed: {
                        (image : UIImage?, error : Error?, cacheType : SDImageCacheType, finished : Bool, url : URL?) in
                        
                        if image != nil && finished{
                            cell.eventImage.image = crop(image: image!, width: 50, height: 50)
                        }
                    })
                }
                
            }
            
            cell.loadLikes()

            return cell
        }else{
            let recentPostCell = tableView.dequeueReusableCell(withIdentifier: "recentPostCell", for: indexPath) as! FeedOneTableViewCell
            
            Constants.DB.user.child((self.pinInfo?.fromUID)!).observeSingleEvent(of: .value, with: {snapshot in
                if let value = snapshot.value as? [String:Any]{
                    recentPostCell.usernameLabel.text = value["username"] as? String
                }
            })
            
            recentPostCell.commentTextView.delegate = self
            recentPostCell.mapButton.addTarget(self, action: #selector(OtherUserProfileViewController.globeButtonPressed(_:)), for: .touchUpInside)
            recentPostCell.timeSince.text = DateFormatter().timeSince(from: Date(timeIntervalSince1970: (self.pinInfo!.dateTimeStamp)), numericDates: true, shortVersion: true)
            recentPostCell.pin = self.pinInfo
            
            if let url = URL(string: self.userImageURL){
                SDWebImageManager.shared().downloadImage(with: url, options: .continueInBackground, progress: {
                    (receivedSize :Int, ExpectedSize :Int) in
                    
                }, completed: {
                    (image : UIImage?, error : Error?, cacheType : SDImageCacheType, finished : Bool, url : URL?) in
                    
                    if image != nil && finished{
                        recentPostCell.userImage.setImage(image, for: .normal)
                        recentPostCell.userImage.setImage(image, for: .selected)
                    }
                })
            }
            
            /*self.pinInfo?.dbPath.observeSingleEvent(of: .value, with: {snapshot in
                if let value = snapshot.value as? [String:Any]{
                    if value["images"] != nil{
                        if let images = value["images"] as? [String:Any]{
                            if let imageURL = (images[images.keys.first!] as? [String:Any])?["imagePath"] as? String{
                                let reference = Constants.storage.pins.child(imageURL)
                                reference.downloadURL(completion: { (url, error) in
                                    
                                    if error != nil {
                                        print(error?.localizedDescription ?? "")
                                        return
                                    }
                                    recentPostCell.userImage.sd_setImage(with: url, for: .normal)
                                    recentPostCell.userImage.sd_setImage(with: url, for: .selected)
//                                    recentPostCell.userImage.sd_setImage(with: url, for: .normal, placeholderImage: #imageLiteral(resourceName: "placeholder_people"))
//                                    recentPostCell.userImage.sd_setImage(with: url, for: .selected, placeholderImage: #imageLiteral(resourceName: "placeholder_people"))
                
                                })
                            }
                        }
                    }
                }
                
            })*/
            
            self.pinInfo?.dbPath.child("like").child("likedBy").queryOrdered(byChild: "UID").queryEqual(toValue: AuthApi.getFirebaseUid()).observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                if value != nil
                {
                    
                    recentPostCell.likeButton.setImage(UIImage(named: "Liked"), for: UIControlState.normal)
                }
            })
            
            let pinLocation = CLLocation(latitude: pinInfo!.coordinates.latitude, longitude: pinInfo!.coordinates.longitude)
            recentPostCell.distanceLabel.text = getDistance(fromLocation: pinLocation, toLocation: AuthApi.getLocation()!)
            
            recentPostCell.addressLabel.text = self.pinInfo?.locationAddress.components(separatedBy: ";;")[0]
            if let pinFocus = self.pinInfo?.focus{
                if pinFocus.characters.first == "●"{
                    let startIndex = pinFocus.index(pinFocus.startIndex, offsetBy: 2)
                    let interestStringWithoutDot = pinFocus.substring(from: startIndex)
                    addGreenDot(label: recentPostCell.interestLabel, content: interestStringWithoutDot)
                }else{
                    addGreenDot(label: recentPostCell.interestLabel, content: pinFocus)
                }
            }else{
                addGreenDot(label: recentPostCell.interestLabel, content: "N.A")
            }
        
            recentPostCell.nameDescriptionLabel.text = self.pinInfo?.pinMessage
            return recentPostCell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag == 2{
            let storyboard = UIStoryboard(name: "Pin", bundle: nil)
            let ivc = storyboard.instantiateViewController(withIdentifier: "PinLookViewController") as! PinLookViewController
            ivc.data = self.pinInfo
            self.present(ivc, animated: true, completion: { _ in })
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var rowHeight = CGFloat()
        if tableView.tag == 0{
            let placeCell = tableView.dequeueReusableCell(withIdentifier: "InvitePeoplePlaceCell") as! InvitePeoplePlaceCell
            rowHeight = placeCell.frame.size.height
        }else if tableView.tag == 1{
            let eventCell = tableView.dequeueReusableCell(withIdentifier: "InvitePeopleEventCell") as! InvitePeopleEventCell
            rowHeight = eventCell.frame.size.height
        }else if tableView.tag == 2{
            let myCell = tableView.dequeueReusableCell(withIdentifier: "recentPostCell") as! FeedOneTableViewCell
            self.recentPostTableViewHeight.constant = myCell.contentView.frame.size.height
            rowHeight = myCell.contentView.frame.size.height
        }
        
        return rowHeight
    }
    
    @IBAction func inviteClicked(_ sender: Any) {
        let storyboard = UIStoryboard(name: "search_people", bundle: nil)
        let ivc = storyboard.instantiateViewController(withIdentifier: "invitePeople") as! InvitePeopleViewController
        ivc.inviteFromOtherUserProfile = true
        ivc.UID = self.userID
        ivc.isMeetup = true
        ivc.otherUserProfile = self
        ivc.otherUserProfileDelegate = self
        ivc.attendingEvents = self.eventsIAttend
        ivc.followingPlaces = self.placesIFollow
        
        self.present(ivc, animated: true, completion: nil)
    }
    
    @IBAction func followUser(_ sender: Any) {
        let time = NSDate().timeIntervalSince1970
        
        if self.followButton.isSelected == false{
            Follow.followUser(uid: self.userInfo["firebaseUserId"] as! String)
            followButton.isSelected = true
            followButton.layer.borderWidth = 1
            followButton.layer.borderColor = UIColor.white.cgColor
            followButton.backgroundColor = UIColor(red: 20/255.0, green: 40/255.0, blue: 64/255.0, alpha: 1.0)
            followButton.tintColor = UIColor.clear
            followButton.layer.shadowOpacity = 0.5
            followButton.layer.masksToBounds = false
            followButton.layer.shadowColor = UIColor.black.cgColor
            followButton.layer.shadowRadius = 5.0
            
        } else if self.followButton.isSelected == true{
            
            let unfollowAlertController = UIAlertController(title: "Unfollow \(self.userInfo["username"]!)?", message: nil, preferredStyle: .actionSheet)
            
            
            let unfollowAction = UIAlertAction(title: "Unfollow", style: .destructive) { action in
                Follow.unFollowUser(uid: self.userInfo["firebaseUserId"] as! String)
                self.followButton.isSelected = false
                self.followButton.layer.borderWidth = 1
                self.followButton.layer.borderColor = UIColor.clear.cgColor
                self.followButton.backgroundColor = UIColor(red: 122/255.0, green: 201/255.0, blue: 1/255.0, alpha: 1.0)
                self.followButton.tintColor = UIColor.clear
                self.followButton.layer.shadowOpacity = 0.5
                self.followButton.layer.masksToBounds = false
                self.followButton.layer.shadowColor = UIColor.black.cgColor
                self.followButton.layer.shadowRadius = 5.0
                
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
                print("cancel has been tapped")
            }
            
            unfollowAlertController.addAction(unfollowAction)
            unfollowAlertController.addAction(cancelAction)
            self.present(unfollowAlertController, animated: true, completion: nil)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Add a comment"{
            textView.text = ""
        }
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Messages", bundle: nil)
        let VC = storyboard.instantiateViewController(withIdentifier: "chat") as? ChatViewController
        let root = storyboard.instantiateViewController(withIdentifier: "otherUserProfileNavigation") as! UINavigationController
        VC?.user = self.userInfo
        VC?.messageUser = true
        VC?.goBackToOtherUser = true
        
        root.navigationItem.hidesBackButton = true
        root.navigationBar.barTintColor = Constants.color.navy
        root.navigationBar.isTranslucent = false
        
        root.pushViewController(VC!, animated: true)
        self.present(root, animated: true, completion: nil)
    }
    
    @IBAction func unwindToOtherUserProfile(_ sender: UIStoryboardSegue){
        self.hasSentUserAnInvite()
    }
    
    func showPopup(){
        UIView.animate(withDuration: 1, delay: 0.0, options: .curveEaseInOut, animations: {
            self.invitePopupView.center.y -= self.invitePopupView.frame.size.height
            self.invitePopupTopConstraint.constant -= self.invitePopupView.frame.size.height
        }, completion: { animate in
            UIView.animate(withDuration: 1, delay: 3.0, options: .curveEaseInOut, animations: {
                self.invitePopupView.center.y += self.invitePopupView.frame.size.height
                self.invitePopupTopConstraint.constant += self.invitePopupView.frame.size.height
            }, completion: nil)
        })
    }
    
    func hasSentUserAnInvite(){
        self.showInvitePopup = true
        print("in other user profile")
    }
    
    func globeButtonPressed(_ sender: UIButton) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "home") as! HomePageViewController
        vc.willShowPin = true
        
        vc.location = CLLocation(latitude: (self.pinInfo?.coordinates.latitude)!, longitude: (self.pinInfo?.coordinates.longitude)!)
        vc.selectedIndex = 0
        vc.showPin = self.pinInfo
        
        DataCache.instance.write(object: self.pinInfo! as NSCoding, forKey: "view_pin")
        delegate?.showPinMarker(pin: self.pinInfo!, show: true)
        self.present(vc, animated: true, completion: nil)
    }
}

