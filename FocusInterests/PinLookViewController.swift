//
//  PinLookViewController.swift
//  FocusInterests
//
//  Created by Andrew Simpson on 5/29/17.
//  Copyright © 2017 singlefocusinc. All rights reserved.
//

import UIKit
import Firebase
import Crashlytics

class PinLookViewController: UIViewController, GMSMapViewDelegate {

    @IBOutlet weak var viewForMap: UIView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var addressTopOut: UIButton!
    @IBOutlet weak var likeOut: UIButton!
    @IBOutlet weak var commentOut: UIButton!
    @IBOutlet weak var sendOut: UIButton!
    @IBOutlet weak var interestsLabel: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var pinMessageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBOutlet weak var pinMessageLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var commentsStackView: UIStackView!
    @IBOutlet weak var commentHeight: NSLayoutConstraint!
    @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!
    
    var data: pinData!
    var dictData = NSDictionary()
    var likes = 0
    var mapView: MapViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hideKeyboardWhenTappedAround()
        profileImage.roundedImage()
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
        
        let attrs = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont(name: "Avenir-Black", size: 18)!
        ]
        
        self.view.backgroundColor = Constants.color.navy
        self.navBar.barTintColor = Constants.color.navy
        navBar.titleTextAttributes = attrs
        
        if data.focus == ""{
            addGreenDot(label: self.interestsLabel, content: "N.A")
        }else{
            if data.focus.characters.first == "●"{
                let startIndex = data.focus.index(data.focus.startIndex, offsetBy: 2)
                let interestStringWithoutDot = data.focus.substring(from: startIndex)
                addGreenDot(label: self.interestsLabel, content: interestStringWithoutDot)
            }else{
                addGreenDot(label: self.interestsLabel, content: data.focus)
            }
        }
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(didDoubletap(sender:)))
        doubleTap.numberOfTapsRequired = 2
        self.viewForMap.addGestureRecognizer(doubleTap)
        
        
        Constants.DB.user.child(data.fromUID).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            if value != nil
            {
                if let username = value?["username"] as? String{
                    
                    Answers.logCustomEvent(withName: "Screen",
                                           customAttributes: [
                                            "Name": "View Pin",
                                            "user": username
                        ])
                    self.usernameLabel.text = username
                    
                    let messageText = "\(String(describing: username)) \(self.data.pinMessage)"
                    
                    let length = username.characters.count
                    let range = NSMakeRange(0, length)
                    
                    self.pinMessageLabel.attributedText = attributedString(from: messageText, boldRange: range)
                }
                else{
                    self.usernameLabel.text = "N.A."
                }
                
                if let image = value?["image_string"] as? String{
                    self.profileImage.sd_setImage(with: URL(string: image))
                }
            }
        })
        
        addressTopOut.setTitle(data.locationAddress.replacingOccurrences(of: ";;", with: " ", options: .literal, range: nil), for: UIControlState.normal)
        
        let formatter = DateFormatter()
        let date = Date(timeIntervalSince1970: data.dateTimeStamp)
        dateLabel.text = formatter.timeSince(from: date, numericDates: true, shortVersion: true)
        
        //check for images
        Constants.DB.pins.child(data.fromUID).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            if value != nil
            {
                
                if let image = value?["images"] as? NSDictionary
                {
                    var firstVal = ""
                    for (key,_) in image
                    {
                        firstVal = key as! String
                        break
                    }
                    let bigImage = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.viewForMap.frame.height))
                    
                    bigImage.contentMode = UIViewContentMode.scaleAspectFill
                    bigImage.clipsToBounds = true
                    
                    self.viewForMap.addSubview(bigImage)
                    
                    let placeholderImage = UIImage(named: "empty_event")
                    
                    let reference = Constants.storage.pins.child(((value?["images"] as! NSDictionary)[firstVal] as! NSDictionary)["imagePath"] as! String)
                    reference.downloadURL(completion: { (url, error) in
                        
                        if error != nil {
                            print(error?.localizedDescription ?? "")
                            return
                        }
                        
                        bigImage.sd_setImage(with: url, placeholderImage: placeholderImage)
                        bigImage.setShowActivityIndicator(true)
                        bigImage.setIndicatorStyle(.gray)
                        
                        
                        let tap = UITapGestureRecognizer(target: self, action: #selector(self.imageTap(sender:)))
                        tap.numberOfTapsRequired = 2
                        bigImage.isUserInteractionEnabled = true
                        bigImage.addGestureRecognizer(tap)
                    })
                    
                }else
                {
                    let camera = GMSCameraPosition.camera(withLatitude: self.data.coordinates.latitude, longitude: self.data.coordinates.longitude, zoom: 13)
                    let mapView = GMSMapView.map(withFrame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.viewForMap.frame.height), camera: camera)
                    mapView.settings.scrollGestures = false
                    mapView.delegate = self
                    
                    let position = CLLocationCoordinate2D(latitude: Double(self.data.coordinates.latitude), longitude: Double(self.data.coordinates.longitude))
                    
                    let marker = GMSMarker(position: position)
                    marker.map = mapView
                    let image = UIImageView(frame: CGRect(x: 0, y: 0, width: 25, height: 40))
                    image.image = UIImage(named: "pin")
                    image.contentMode = .scaleAspectFit
                    marker.iconView = image
                    
                    mapView.mapType = .normal
                    self.viewForMap.addSubview(mapView)
                }
                
            }
        })
        
        
        //check for likes
        data.dbPath.child("like").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            if value != nil{
                self.likesLabel.isHidden = false
                self.likes = (value?["num"] as? Int)!
                
                if self.likes > 1{
                    self.likesLabel.text = String(self.likes) + " likes"
                }
                else if self.likes == 1{
                    self.likesLabel.text = String(self.likes) + " like"
                }
            }else{
                self.likesLabel.isHidden = true
            }
        })
        
        data.dbPath.child("like").child("likedBy").queryOrdered(byChild: "UID").queryEqual(toValue: AuthApi.getFirebaseUid()).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            if value != nil
            {
                
                self.likeOut.setImage(UIImage(named: "Liked"), for: UIControlState.normal)
            }
        })
        
        
        for view in commentsStackView.subviews{
            view.removeFromSuperview()
        }
        
        data.dbPath.child("comments").queryOrdered(byChild: "date").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? [String:Any]
            if let value = value
            {
                if value.count > 3{
                    let seeMoreCommentsButton = UIButton(frame: CGRect(x: 0, y: 0, width: self.commentsStackView.frame.size.width, height: 30))
                    
                    seeMoreCommentsButton.titleLabel?.font = UIFont(name: "Avenir-Book", size: 14)
                    seeMoreCommentsButton.setTitle("View \(value.count) comments", for: .normal)
                    seeMoreCommentsButton.setTitleColor(UIColor.white, for: .normal)
                    seeMoreCommentsButton.setTitle("View \(value.count) comments", for: .selected)
                    seeMoreCommentsButton.setTitleColor(UIColor.white, for: .selected)
                    seeMoreCommentsButton.backgroundColor = UIColor.clear
                    seeMoreCommentsButton.contentHorizontalAlignment = .left
                    
                    seeMoreCommentsButton.addTarget(self, action: #selector(PinLookViewController.showComments(_:)), for: .touchUpInside)
                    
                    self.commentsStackView.addArrangedSubview(seeMoreCommentsButton)
                    self.commentsStackView.translatesAutoresizingMaskIntoConstraints = false
                }
                
                let myArr = Array(value.keys)
                var sortedKeys = myArr.sorted(by: {
                    let val1 = value[$0] as? [String: Any]
                    let val2 = value[$1] as? [String: Any]
                    
                    let date1 = val1!["date"] as! Double
                    let date2 = val2!["date"] as! Double
                    return date1 > date2
                })
                
                if sortedKeys.count < 3{
                    sortedKeys = sortedKeys.reversed()
                }
                else{
                    sortedKeys = sortedKeys[0..<3].reversed()
                }
                
                for (index,id) in (sortedKeys.enumerated()){
                    if index == 3{
                        break
                        
                    }
                    let data = value[id] as? [String:Any]
                    Constants.DB.user.child(data?["fromUID"] as! String).observeSingleEvent(of: .value, with: { (snapshot) in
                        let value = snapshot.value as? NSDictionary
                        if value != nil
                        {
                            let username = value?["username"] as! String
                            let messageText = "\(username) \(data?["comment"] as! String)"
                            let length = messageText.characters.count - username.characters.count
                            let range = NSMakeRange(username.characters.count, length)
                            
                            let commentLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.commentsStackView.frame.width, height: .greatestFiniteMagnitude))
                            commentLabel.textColor = .white
                            commentLabel.numberOfLines = 0
                            commentLabel.lineBreakMode = .byWordWrapping
                            commentLabel.textAlignment = .left
                            commentLabel.attributedText = attributedString(from: messageText, nonBoldRange: range)
//                            commentLabel.sizeToFit()
                            
                            self.commentsStackView.addArrangedSubview(commentLabel)
                            self.commentsStackView.translatesAutoresizingMaskIntoConstraints = false
                            let tap = UITapGestureRecognizer(target: self, action: #selector(self.showComments(_:)))
                            self.commentsStackView.addGestureRecognizer(tap)
                        }
                    })
                }
            }
        })
        
        var tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.goToUserProfile))
        tapGesture.numberOfTapsRequired = 1
        self.profileImage.isUserInteractionEnabled = true
        
        self.usernameLabel.addGestureRecognizer(tapGesture)
        self.profileImage.addGestureRecognizer(tapGesture)
    }
    
    func goToUserProfile(){
        let VC = UIStoryboard(name: "UserProfile", bundle: nil).instantiateViewController(withIdentifier: "OtherUser") as! OtherUserProfileViewController
        
        VC.otherUser = true
        VC.userID = self.data.fromUID
        
        Constants.DB.user.child(self.data.fromUID).observeSingleEvent(of: .value, with: {snapshot in
            if let info = snapshot.value as? [String:Any]{
                if let user = User.toUser(info: info){
                    VC.userData = user
                    self.present(VC, animated:true, completion:nil)
                }
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.pinMessageLabelHeight.constant = self.pinMessageLabel.intrinsicContentSize.height

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    
    @IBAction func addressOut(_ sender: Any) {
    }
    
    @IBAction func options(_ sender: Any) {
    }
    
    func imageTap(sender: UITapGestureRecognizer){
        if (self.likeOut.imageView?.image?.isEqual(#imageLiteral(resourceName: "Like")))!{
            self.likes = self.likes + 1
            data.dbPath.child("like").updateChildValues(["num": likes])
            data.dbPath.child("like").child("likedBy").childByAutoId().updateChildValues(["UID": AuthApi.getFirebaseUid()!])
            
            if self.likes > 1{
                self.likesLabel.text = String(self.likes) + " likes"
            }
            else{
                self.likesLabel.text = String(self.likes) + " like"
            }
            
            self.likeOut.setImage(#imageLiteral(resourceName: "Liked"), for: UIControlState.normal)
            
            
            Answers.logCustomEvent(withName: "Like Pin",
                                   customAttributes: [
                                    "liked": true,
                                    "user": AuthApi.getFirebaseUid()!,
                                    "likeCount": self.likes
                ])
            
            sendNotification(to: data.fromUID, title: "New Like", body: "\(AuthApi.getUserName()!) liked your Pin", actionType: "", type: "", item_id: "", item_name: "")
            
        }
    }
    
    @IBAction func like(_ sender: Any) {
       if (self.likeOut.imageView?.image?.isEqual(#imageLiteral(resourceName: "Like")))!
       {
            self.likes = self.likes + 1
            data.dbPath.child("like").updateChildValues(["num": likes])
            data.dbPath.child("like").child("likedBy").childByAutoId().updateChildValues([
                "UID": AuthApi.getFirebaseUid()!,
                "time": Date().timeIntervalSince1970
                ])
        
            if self.likes > 1{
                self.likesLabel.text = String(self.likes) + " likes"
            }else if self.likes == 1{
                self.likesLabel.text = String(self.likes) + " like"
                self.likesLabel.isHidden = false
            }else{
                self.likesLabel.isHidden = true
            }
            self.likeOut.setImage(#imageLiteral(resourceName: "Liked"), for: UIControlState.normal)
        
            sendNotification(to: data.fromUID, title: "New Like", body: "\(AuthApi.getUserName()!) liked your Pin", actionType: "", type: "", item_id: "", item_name: "")
        
        Answers.logCustomEvent(withName: "Like Pin",
                               customAttributes: [
                                "liked": true,
                                "user": AuthApi.getFirebaseUid()!,
                                "likeCount": self.likes
            ])
        }
       else{
            self.likes = self.likes - 1
            data.dbPath.child("like").updateChildValues(["num": likes])

            data.dbPath.child("like").child("likedBy").queryOrdered(byChild: "UID").queryEqual(toValue: AuthApi.getFirebaseUid()).observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? [String:Any]
                if let value = value
                {
                    for (id, _) in value{
                        self.data.dbPath.child("like").child("likedBy").child(id).removeValue()
                    }
                }
            })
        
        
            if self.likes > 1{
                self.likesLabel.text = String(self.likes) + " likes"
            }else if self.likes == 1{
                self.likesLabel.text = String(self.likes) + " like"
            }else{
                self.likesLabel.isHidden = true
            }
            self.likeOut.setImage(#imageLiteral(resourceName: "Like"), for: UIControlState.normal)
        
        Answers.logCustomEvent(withName: "Like Pin",
                               customAttributes: [
                                "liked": false,
                                "user": AuthApi.getFirebaseUid()!,
                                "likeCount": self.likes
            ])
        }
       
    }
    
    func didDoubletap(sender:UITapGestureRecognizer)
    {
        if self.likesLabel.isHidden == true {
            self.likesLabel.isHidden = false
        }
        if self.likeOut.isEnabled == true{
            self.likes = self.likes + 1
            data.dbPath.child("like").updateChildValues(["num": likes])
            data.dbPath.child("like").child("likedBy").childByAutoId().updateChildValues([
                "UID": AuthApi.getFirebaseUid()!,
                "time": Date().timeIntervalSince1970
                ])
            self.likeOut.isEnabled = false
            self.likesLabel.text = String(self.likes) + " likes"
            self.likeOut.setImage(UIImage(named: "Liked"), for: UIControlState.normal)
        }
        
    }
    
    @IBAction func comment(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Comments", bundle: nil)
        let ivc = storyboard.instantiateViewController(withIdentifier: "comments") as! CommentsViewController
        ivc.type = "pin"
        ivc.data = data
        self.present(ivc, animated: true, completion: { _ in })
        
    }
    
    @IBAction func send(_ sender: Any) {
    }

    @IBAction func back(_ sender: Any) {
        if let parent = mapView{
            parent.willShowPin = true
            //parent.showPin = pinData
            
            parent.currentLocation = CLLocation(latitude: self.data.coordinates.latitude, longitude: self.data.coordinates.longitude)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func showComments(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Comments", bundle: nil)
        let ivc = storyboard.instantiateViewController(withIdentifier: "comments") as! CommentsViewController
        ivc.type = "pin"
        ivc.data = data
        self.present(ivc, animated: true, completion: { _ in })
    }

}

