//
//  SearchViewController.swift
//  FocusInterests
//
//  Created by Manish Dwibedy on 5/31/17.
//  Copyright © 2017 singlefocusinc. All rights reserved.
//

import UIKit
import SDWebImage
import Alamofire
import CoreLocation
import SwiftyJSON
import GooglePlaces

class SearchViewController: UIViewController, UITableViewDataSource, UISearchBarDelegate, UITableViewDelegate,CLLocationManagerDelegate{

    @IBOutlet weak var peopleHeaderView: UIView!
    @IBOutlet weak var placeHeaderView: UIView!
    @IBOutlet weak var eventHeaderView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var locationField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    var people = [User]()
    var filtered_user = [User]()
    var places = [Place]()
    var filtered_places = [Place]()
    var events = [Event]()
    var filtered_events = [Event]()
    var allData = [generalSearchData]()
    
    let locationManager = CLLocationManager()
    var location: CLLocation? = nil
    var FOCUSListShouldBe = true
    var selectedFocus = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 500
        locationManager.startUpdatingLocation()
        locationManager.delegate = self

        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // search bar setup
        self.searchBar.delegate = self
        
        self.searchBar.isTranslucent = true
        self.searchBar.backgroundImage = UIImage()
        self.searchBar.tintColor = UIColor.white
        self.searchBar.barTintColor = UIColor.white
        
        self.searchBar.layer.cornerRadius = 6
        self.searchBar.clipsToBounds = true
        self.searchBar.layer.borderWidth = 0
        self.searchBar.layer.borderColor = UIColor(red: 119/255.0, green: 197/255.0, blue: 53/255.0, alpha: 1.0).cgColor
        
        // search bar attributes
        let placeholderAttributes: [String : AnyObject] = [NSForegroundColorAttributeName: UIColor.white]
        let attributedPlaceholder: NSAttributedString = NSAttributedString(string: "Search", attributes: placeholderAttributes)
        
        // search bar placeholder
        let textFieldInsideSearchBar = self.searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.backgroundColor = Constants.color.navy
        textFieldInsideSearchBar?.attributedPlaceholder = attributedPlaceholder
        textFieldInsideSearchBar?.textColor = UIColor.white
        
        // search bar glass icon
        let glassIconView = textFieldInsideSearchBar?.leftView as! UIImageView
        glassIconView.image = glassIconView.image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        glassIconView.tintColor = UIColor.white
        
        // search bar clear button
        textFieldInsideSearchBar?.clearButtonMode = .whileEditing
        let clearButton = textFieldInsideSearchBar?.value(forKey: "clearButton") as! UIButton
        clearButton.addTarget(self, action: #selector(clearText), for: .touchUpInside)
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate), for: .normal)
        clearButton.tintColor = UIColor.white
        
        
        for view in searchBar.subviews.last!.subviews {
            if view.isKind(of: NSClassFromString("UISearchBarBackground")!)
            {
                view.removeFromSuperview()
            }
        }
        
        let nib = UINib(nibName: "SearchPlaceCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "placeCell")

        let nib1 = UINib(nibName: "SearchPeopleTableViewCell", bundle: nil)
        tableView.register(nib1, forCellReuseIdentifier: "peopleCell")
        
        let nib2 = UINib(nibName: "SearchEventTableViewCell", bundle: nil)
        tableView.register(nib2, forCellReuseIdentifier: "eventCell")
        
        let nib3 = UINib(nibName: "FOCUSLabelCell", bundle: nil)
        tableView.register(nib3, forCellReuseIdentifier: "FOCUSLabelCell")
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        hideKeyboardWhenTappedAround()
        
        locationField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
    }
    
    //Calls this function when the tap is recognized.
    override func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //getPlaces(text: "")
        //getEvents(text: "")
        
        tableView.reloadData()
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func clearText(){
        self.searchBar.text = ""
        self.searchBar.setShowsCancelButton(false, animated: true)
        self.FOCUSListShouldBe = true
        self.searchBar.endEditing(true)
        self.tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        self.searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.text = ""
        self.searchBar.setShowsCancelButton(false, animated: true)
        self.FOCUSListShouldBe = true
        self.searchBar.endEditing(true)
        self.tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("new text")
        if(searchText == ""){
            self.FOCUSListShouldBe = true
            self.tableView.reloadData()
        }else {
            self.FOCUSListShouldBe = false
            allData.removeAll()
            
            
            
            print("before places search")
            getPlaces(text: searchText)
            getEvents(text: searchText)
            
            if(searchText.characters.count > 0){
                self.filtered_user.removeAll()

                let ref = Constants.DB.user
                _ = ref.queryOrdered(byChild: "username").queryStarting(atValue: searchText.lowercased()).queryEnding(atValue: searchText.lowercased()+"\u{f8ff}").observe(.value, with: { snapshot in
                    _ = snapshot.value as? [String : Any] ?? [:]
                    
                    let users = snapshot.value as? [String : Any] ?? [:]
                    
                    for (_, user) in users{
                        let info = user as? [String:Any]
                        
                        let user = User(username: info?["username"] as! String?, fullname: info?["fullname"] as! String? , uuid: info?["firebaseUserId"] as! String?, userImage: nil, interests: nil, image_string: nil, hasPin: false)
                        
                        if user.uuid != AuthApi.getFirebaseUid(){
                            self.filtered_user.append(user)
                        }
                    }
                    self.tableView.reloadData()
    //                self.people_tableView.reloadData()
                })
                
                self.getPlaces(text: searchText)
                self.getEvents(text: searchText)
            }
            else{
                self.filtered_user = self.people
                self.tableView.reloadData()
    //            self.people_tableView.reloadData()

                self.filtered_places = self.places
                self.tableView.reloadData()
    //            self.place_tableView.reloadData()
                
            }
        }

    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if FOCUSListShouldBe == true{
            return Constants.interests.interests.count
        }else{
            return allData.count
        }
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        if FOCUSListShouldBe == true{
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "FOCUSLabelCell") as! FOCUSLabelCell
            cell.focusLabel.text = Constants.interests.interests[indexPath.row]
            print(Constants.interests.interests[indexPath.row])
            return cell
            
            
        }else if allData[indexPath.row].type == "people"{
            
            print("SHOWING PEOPLE CELLS")
            
            let people = self.allData[indexPath.row].object as! User
            let cell = tableView.dequeueReusableCell(withIdentifier: "peopleCell") as! SearchPeopleTableViewCell!

            cell?.username.text = people.username
            cell?.fullName.text = people.fullname

            cell?.address.text = ""
            cell?.distance.text = ""

            cell?.ID = people.uuid!
            cell?.checkFollow()
            if let interest = people.interests{
                if interest.count > 0{
                addGreenDot(label: (cell?.interest)!, content: (interest[0].name)!)
                }
                
            }
            
            cell?.address.text = people.pinCaption
            _ = UIImage(named: "empty_event")

//            cell?.followButton.roundCorners(radius: 10)
//            cell?.inviteButton.roundCorners(radius: 10)

            cell?.followButton.tag = indexPath.row
            cell?.followButton.addTarget(self, action: #selector(self.followUser), for: UIControlEvents.touchUpInside)
            
            cell?.inviteButton.tag = indexPath.row
            cell?.inviteButton.addTarget(self, action: #selector(self.inviteUser), for: UIControlEvents.touchUpInside)
            
            
            Constants.DB.pins.child(people.uuid!).observeSingleEvent(of: .value, with: { snapshot in
                let value = snapshot.value as? NSDictionary
                if value != nil{
                    let distance = getDistance(fromLocation: self.location!, toLocation: CLLocation(latitude: value?["lat"] as! Double, longitude: value?["lng"] as! Double))
                    cell?.distance.text = distance
                    let com = distance.components(separatedBy: " ")
                    self.allData[indexPath.row].distance = Double(com[0])!
                
                }
            })
            
            return cell!
                
            }else if allData[indexPath.row].type == "event"{
                print("SHOWING EVENT CELLS")
                let event = allData[indexPath.row].object as! Event
                let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell") as! SearchEventTableViewCell!
    
                cell?.name.text = event.title
    
                cell?.address.text = event.fullAddress?.replacingOccurrences(of: ";;", with: "\n")
            
    
                cell?.guestCount.text = "\(event.attendeeCount) guests"
                addGreenDot(label: (cell?.interest)!, content: event.category!)
                if let price = event.price{
                    if price == 0{
                        cell?.price.text = "Free"
                    }
                    else{
                        cell?.price.text = "$ \(price)"
                    }
                }
                else{
                    cell?.price.text = "Free"
                }
            
                cell?.distance.text = getDistance(fromLocation: self.location!, toLocation: CLLocation(latitude: Double(event.latitude!)!, longitude: Double(event.longitude!)!))
                //cell.checkForFollow(id: event.id!)
                let placeHolderImage = UIImage(named: "empty_event")
    
                let reference = Constants.storage.event.child("\(event.id!).jpg")
    
                // Placeholder image
                _ = UIImage(named: "empty_event")
    
                reference.downloadURL(completion: { (url, error) in
    
                    if error != nil {
                        print(error?.localizedDescription ?? "")
                        return
                    }
    
                    cell?.eventImage?.sd_setImage(with: url, placeholderImage: placeHolderImage)
    
                    cell?.eventImage?.setShowActivityIndicator(true)
                    cell?.eventImage?.setIndicatorStyle(.gray)
    
                })
    
    
    //            attending
//                Constants.DB.event.child((event.id)!).child("attendingList").queryOrdered(byChild: "UID").queryEqual(toValue: AuthApi.getFirebaseUid()!).observeSingleEvent(of: .value, with: { (snapshot) in
//                let value = snapshot.value as? NSDictionary
//                 if value != nil{
//                      cell?.attendButton.setTitle("Attending", for: UIControlState.normal)
//                 }
//
//                 })
                
//                cell?.attendButton.roundCorners(radius: 10)
//                cell?.inviteButton.roundCorners(radius: 10)
                
//                cell?.attendButton.tag = indexPath.row
//                cell?.attendButton.addTarget(self, action: #selector(self.attendEvent), for: UIControlEvents.touchUpInside)
            
                cell?.inviteButton.tag = indexPath.row
                cell?.inviteButton.addTarget(self, action: #selector(self.inviteUser), for: UIControlEvents.touchUpInside)
                
                return cell!
                
            }else{
                print("SHOWING PLACE CELLS")
                let place = allData[indexPath.row].object as! Place
    
                let cell:SearchPlaceCell = tableView.dequeueReusableCell(withIdentifier: "placeCell") as! SearchPlaceCell!
                cell.place = place
                cell.searchVC = self
    
                cell.placeNameLabel.text = place.name
    
                if place.address.count > 0{
                    if place.address.count == 1{
                        cell.addressTextView.text = "\(place.address[0])"
                    }
                    else{
                        cell.addressTextView.text = "\(place.address[0])\n\(place.address[1])"
                    }
                }
                cell.placeID = place.id
                cell.ratingLabel.text = "\(place.rating) (\(place.reviewCount) ratings)"
            
                addGreenDot(label: cell.categoryLabel, content: getInterest(yelpCategory: place.categories[0].alias))
            
                cell.checkForFollow()
                let placeHolderImage = UIImage(named: "empty_event")
                cell.placeImage.sd_setImage(with: URL(string :place.image_url), placeholderImage: placeHolderImage)
                cell.distanceLabel.text = getDistance(fromLocation: self.location!, toLocation: CLLocation(latitude: Double(place.latitude), longitude: Double(place.longitude)))
                return cell
            
            }
        }
        
        
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         if self.FOCUSListShouldBe == true{
            return 37
         }else if allData[indexPath.row].type == "people"{
            return 110
        }else if allData[indexPath.row].type == "event"{
            return 110
        }else{
            return 110
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.FOCUSListShouldBe == true{
            self.searchBar.setShowsCancelButton(false, animated: true)
            self.selectedFocus = Constants.interests.interests[indexPath.row]
            
            self.FOCUSListShouldBe = false
            allData.removeAll()
            
            getUsers(text: "")
            getEvents(text: "")
            getPlaces(text: "")
        }
    }
    
    func attendEvent(sender:UIButton){
        let buttonRow = sender.tag
        let event = self.events[buttonRow]
        
        if sender.title(for: .normal) == "Attend"{
            print("attending event \(String(describing: event.title)) ")
            
            Constants.DB.event.child((event.id)!).child("attendingList").childByAutoId().updateChildValues(["UID":AuthApi.getFirebaseUid()!])
            
            
            Constants.DB.event.child((event.id)!).child("attendingAmount").observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                if value != nil
                {
                    let attendingAmount = value?["amount"] as! Int
                    Constants.DB.event.child((event.id)!).child("attendingAmount").updateChildValues(["amount":attendingAmount + 1])
                }
            })
            
            sender.setTitle("Attending", for: .normal)
        }
        else{
            Constants.DB.event.child((event.id)!).child("attendingList").queryOrdered(byChild: "UID").queryEqual(toValue: AuthApi.getFirebaseUid()!).observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? [String:Any]
                
                for (id,_) in value!{
                    Constants.DB.event.child("\(event.id!)/attendingList/\(id)").removeValue()
                }
                
            })
            
            Constants.DB.event.child((event.id)!).child("attendingAmount").observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                if value != nil
                {
                    let attendingAmount = value?["amount"] as! Int
                    Constants.DB.event.child((event.id)!).child("attendingAmount").updateChildValues(["amount":attendingAmount - 1])
                }
            })
            
            sender.setTitle("Attend", for: .normal)
        }
        
    }
    
    func followUser(sender:UIButton){
        let buttonRow = sender.tag
        
        print("following user \(String(describing: self.people[buttonRow].username)) ")
    }
    
    func inviteUser(sender:UIButton){
        let buttonRow = sender.tag
        
        print("invite user \(String(describing: self.people[buttonRow].username)) ")
    }

    func getUsers(text: String){
        let ref = Constants.DB.user
        _ =  ref.queryOrdered(byChild: "username").queryStarting(atValue: text.lowercased()).queryEnding(atValue: text.lowercased()+"\u{f8ff}").observeSingleEvent(of: .value, with: { snapshot in
            let users = snapshot.value as? [String : Any] ?? [:]
            for (_, user) in users{
                let info = user as? [String:Any]
                
                let user_interest = info?["interests"] as? String ?? ""
                var people_interest = [Interest]()
                for interest in user_interest.components(separatedBy: ","){
                    people_interest.append(Interest(name: interest, category: nil, image: nil, imageString: nil))
                }
                let user = User(username: info?["username"] as! String?, fullname: info?["fullname"] as! String? , uuid: info?["firebaseUserId"] as! String?, userImage: nil, interests: people_interest, image_string: nil, hasPin: false)
                
                
                let interest = user_interest.components(separatedBy: ",")
                var user_interests = getUserInterests().components(separatedBy: ",")
                
                if self.selectedFocus.characters.count > 0{
                    user_interests = [self.selectedFocus]
                }
                let common = interest.filter(user_interests.contains)
                
//                if let common = common{
                    if common.count > 0{
                        if user.uuid != nil && user.uuid != AuthApi.getFirebaseUid(){
                            let newData = generalSearchData()
                            newData.type = "people"
                            newData.object = user
                            print(user.uuid ?? "")
                            Constants.DB.pins.child(user.uuid!).observeSingleEvent(of: .value, with: { snapshot in
                                let value = snapshot.value as? NSDictionary
                                if value != nil{
                                    let distance = getDistance(fromLocation: self.location!, toLocation: CLLocation(latitude: value?["lat"] as! Double, longitude: value?["lng"] as! Double))
                                    let com = distance.components(separatedBy: " ")
                                    newData.distance = Double(com[0])!
                                    user.hasPin = true
                                    user.pinCaption = (value?["pin"] as? String)!
                                    
                                }
                                
                                Constants.DB.user.child(AuthApi.getFirebaseUid()!).child("following").child("people").queryOrdered(byChild: "UID").queryEqual(toValue: user.uuid!).observeSingleEvent(of: .value, with: { (snapshot) in
                                    let value = snapshot.value as? NSDictionary
                                    if value != nil {
                                        newData.following = true
                                        
                                    }
                                    
                                    self.allData.append(newData)
                                    self.tableView.reloadData()
                                    
        //                          self.allData = self.sortData(data: self.allData)
                                    
                                })
                            })
                            
                            
                        }
                    }
//                }
                
            }
            //
            
        })
        
    }
    
    func getPlaces(text: String){
        print("getting place")
       
        self.filtered_places.removeAll()
        let url = "https://api.yelp.com/v3/businesses/search"
        
        let headers: HTTPHeaders = [
            "authorization": "Bearer \(AuthApi.getYelpToken()!)",
            "cache-contro": "no-cache"
        ]
        
        var category = ""
        if self.selectedFocus.characters.count > 0{
            category = getYelpCategory(category: self.selectedFocus)
        }
        
        let location = self.location == nil ? AuthApi.getLocation() : self.location
        let parameters = [
            "categories": category,
            "term": text,
            "latitude": location?.coordinate.latitude ?? 0,
            "longitude": location?.coordinate.longitude ?? 0,
            ] as [String : Any]
        
        Alamofire.request(url, method: .get, parameters:parameters, headers: headers).responseJSON { response in
            let json = JSON(data: response.data!)
            
            _ = self.places.count
            print(json)
            for (_, business) in json["businesses"].enumerated(){
                let id = business.1["id"].stringValue
                let name = business.1["name"].stringValue
                let image_url = business.1["image_url"].stringValue
                let isClosed = business.1["is_closed"].boolValue
                let reviewCount = business.1["review_count"].intValue
                let rating = business.1["rating"].floatValue
                let latitude = business.1["coordinates"]["latitude"].doubleValue
                let longitude = business.1["coordinates"]["longitude"].doubleValue
                let price = business.1["price"].stringValue
                let address_json = business.1["location"]["display_address"].arrayValue
                let phone = business.1["display_phone"].stringValue
                let distance = business.1["distance"].doubleValue
                let categories_json = business.1["categories"].arrayValue
                let url = business.1["url"].stringValue
                let plain_phone = business.1["phone"].stringValue
                let is_closed = business.1["is_closed"].boolValue
                
                var address = [String]()
                for raw_address in address_json{
                    address.append(raw_address.stringValue)
                }
                
                var categories = [Category]()
                for raw_category in categories_json as [JSON]{
                    let name = raw_category["title"].stringValue
                    let alias = raw_category["alias"].stringValue
                    let category = Category(name: name, alias: alias)
                    categories.append(category)
                }
                
                let place = Place(id: id, name: name, image_url: image_url, isClosed: isClosed, reviewCount: reviewCount, rating: rating, latitude: latitude, longitude: longitude, price: price, address: address, phone: phone, distance: distance, categories: categories, url: url, plainPhone: plain_phone)
                
                
                
                    if text.characters.count >= 0{
                        let newData = generalSearchData()
                        newData.type = "place"
                        newData.object = place
                        print(place.id)
                        let distance = getDistance(fromLocation: self.location!, toLocation: CLLocation(latitude: place.latitude, longitude: place.longitude))
                        let com = distance.components(separatedBy: " ")
                        newData.distance = Double(com[0])!
                        Constants.DB.user.child(AuthApi.getFirebaseUid()!).child("following").child("places").queryOrdered(byChild: "placeID").queryEqual(toValue: place.id).observeSingleEvent(of: .value, with: { (snapshot) in
                            let value = snapshot.value as? NSDictionary
                            if value != nil {
                                newData.following = true
                                
                            }
                           
                            self.allData.append(newData)
//                            self.allData = self.sortData(data: self.allData)
                            self.tableView.reloadData()
                        })
                        
                    
                }
            }
            self.tableView.reloadData()
        }
    }
    
    func setupInterestsSet() -> [String:Array<Any>]{
        var interestSet = [String:Array<Any>]()
        
        for interest_index in 0...Constants.interests.interests.count-1{
            interestSet[Constants.interests.interests[interest_index]] = []
        }
        return interestSet
    }
    
    func getEvents(text: String){
        
        let ref = Constants.DB.event
        _ = ref.queryOrdered(byChild: "title").queryStarting(atValue: text.lowercased()).queryEnding(atValue: text.lowercased()+"\u{f8ff}").observe(.value, with: { snapshot in
            let events = snapshot.value as? [String : Any] ?? [:]
            
            for (id, event) in events{
                let info = event as? [String:Any]
                let event = Event(title: (info?["title"])! as! String, description: (info?["description"])! as! String, fullAddress: (info?["fullAddress"])! as? String, shortAddress: (info?["shortAddress"])! as? String, latitude: (info?["latitude"])! as? String, longitude: (info?["longitude"])! as? String, date: (info?["date"])! as! String, creator: (info?["creator"])! as? String, id: id, category: info?["interests"] as? String, privateEvent: (info?["private"] as? Bool)!)
                
                let event_interests = event.category?.components(separatedBy: ",")
                var user_interests = getUserInterests().components(separatedBy: ",")
                
                if self.selectedFocus.characters.count > 0{
                    user_interests = [self.selectedFocus]
                }
                let common = event_interests?.filter(user_interests.contains)

                if let attending = info?["attendingList"] as? [String:Any]{
                    event.setAttendessCount(count: attending.count)
                }
                
                
                let newData = generalSearchData()
                newData.type = "event"
                newData.object = event
                let distance = getDistance(fromLocation: self.location!, toLocation: CLLocation(latitude: Double(event.latitude!)!, longitude: Double(event.latitude!)!))
                let com = distance.components(separatedBy: " ")
                newData.distance = Double(com[0])!
                if let common = common{
                    if common.count > 0{
                        self.allData.append(newData)
                    }
                }
                //                self.allData = self.sortData(data: self.allData)
                
                self.tableView.reloadData()
                
            }
            self.tableView.reloadData()
        })
    }
    
    
    
    func sortData(data: [generalSearchData]) -> [generalSearchData]{
        var dataN = data
        
        var followingSort = [generalSearchData]()
        var noPinPeople = [generalSearchData]()
        var middleData = [generalSearchData]()
        for gsd in dataN{
            if gsd.type == "people" || gsd.type == "place"{
                if gsd.following == true{
                    followingSort.append(gsd)
                }else if gsd.type == "people" && gsd.distance == 0.0 && gsd.following == false{
                    noPinPeople.append(gsd)
                }else{
                    middleData.append(gsd)
                }
            }
            
        }
        
        let newFollowSort = followingSort.sorted(by: { $0.distance > $1.distance })
        
        let newMiddleSort = middleData.sorted(by: { $0.distance > $1.distance })
        
        dataN = newFollowSort + newMiddleSort + noPinPeople
    
        return dataN
    }

}


extension SearchViewController: GMSAutocompleteViewControllerDelegate {
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        self.locationField.text = place.formattedAddress!
        self.location = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        
        print("Place name: \(place.name)")
        
        print("Place address: \(String(describing: place.formattedAddress))")
        
        print("Place attributions: \(String(describing: place.attributions))")
        
        dismiss(animated: true, completion: nil)
    }
    
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // to do: handle error
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        self.locationField.text = ""
        self.location = nil
        dismiss(animated: true, completion: nil)
    }
    
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        viewController.autocompleteFilter?.country = "US"
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        viewController.autocompleteFilter?.country = "US"
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension SearchViewController: UITextFieldDelegate{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == locationField{
            let autoCompleteController = GMSAutocompleteViewController()
            autoCompleteController.delegate = self
            present(autoCompleteController, animated: true, completion: nil)
        }
    }
}

class generalSearchData{
    
    var type = ""
    var object: Any!
    var following = false
    var distance = 0.0
    
}



