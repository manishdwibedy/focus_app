//
//  NewInviteViewController.swift
//  FocusInterests
//
//  Created by Alex Jang on 7/16/17.
//  Copyright © 2017 singlefocusinc. All rights reserved.
//

import UIKit
import Contacts
import FirebaseStorage
import MessageUI
import Crashlytics


class NewInviteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SendInvitationsViewControllerDelegate, MFMessageComposeViewControllerDelegate, UITextFieldDelegate{

    @IBOutlet weak var timeOut: UIButton!
    @IBOutlet weak var dayTextField: UITextField!
    @IBOutlet weak var friendsTableView: UITableView!
    @IBOutlet weak var contactList: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var contactListView: UIView!
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBOutlet weak var friendsListBottom: NSLayoutConstraint!
    @IBOutlet weak var inviteTableTop: NSLayoutConstraint!
    
    var sections = [String]()
    var sectionMapping = [String:Int]()
    var users = [String:[InviteUser]]()
    var daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    @IBOutlet weak var doneToolBar: UIToolbar!
    var parentCell: SearchPlaceCell!
    var type = ""
    var id = ""
    var place: Place?
    var event: Event?
    
    var dayText = ""
    var monthText = ""
    
    var username = ""
    var selected = [InviteUser:Bool]()
    
    let store = CNContactStore()
    
    let datePicker = UIDatePicker()
    let timePicker = UIDatePicker()
    let dateFormatter = DateFormatter()
    let timeFormatter = DateFormatter()
    
    var dateDoneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(InviteViewController.dateSelected))
    
    lazy var dateToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        
        toolbar.setItems([self.flexibleSpaceButton, self.dateDoneButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        
        return toolbar
    }()
    
    var inviteTime = ""
    
    var searchPlace: SearchPlacesViewController? = nil
    var searchEvent: SearchEventsViewController? = nil
    var mapView: MapViewController? = nil
    
    var searchPeopleEventDelegate: InvitePeopleEventCellDelegate?
    var searchPeoplePlaceDelegate: InvitePeoplePlaceCellDelegate?
    
    var image: Data?
    var selectedFriend = [Bool]()
    var contacts = [CNContact]()
    
    var flexibleSpaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    
    var places = [Place]()
    var all_places = [Place]()
    var followingPlaces = [Place]()
    var filtered = [Place]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sendButton.roundCorners(radius: 10.0)
        
        self.friendsTableView.delegate = self
        self.friendsTableView.dataSource = self
        
        self.friendsTableView.allowsSelection = true
        
        if contacts.count <= 0 {
            contactListView.isHidden = true
        }else{
            contactListView.isHidden = false
        }
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat =  "h:mm a"
        
        
        if type == "event"{
            let startDate = event?.date?.components(separatedBy: ",")[1].trimmingCharacters(in: .whitespaces)
//            timeOut.setTitle(startDate, for: .normal)
            
            let startDate1 = dateFormatter.date(from: startDate!)
            timePicker.date = startDate1!
        }
        else if type == "place"{
            let currentTime = Date()
            
            let calendar = Calendar.current
            let nextDiff = 5 - calendar.component(.minute, from: currentTime) % 5
            let nextDate = calendar.date(byAdding: .minute, value: nextDiff, to: currentTime) ?? Date()
            
//            timeOut.setTitle(dateFormatter.string(from: nextDate), for: .normal)
            timePicker.date = nextDate
        }
        
        let inviteListCellNib = UINib(nibName: "InviteListTableViewCell", bundle: nil)
        friendsTableView.register(inviteListCellNib, forCellReuseIdentifier: "personToInvite")
        
        //        let selectedTimeListCellNib = UINib(nibName: "SelectedTimeTableViewCell", bundle: nil)
        //        friendsTableView.register(selectedTimeListCellNib, forCellReuseIdentifier: "selectedTimeCell")
        
        if type != "invite"{
            Constants.DB.user.observeSingleEvent(of: .value, with: { (snapshot) in
                let data = snapshot.value as? NSDictionary
                if let data = data
                {
                    //                self.inviteCellData.removeAll()
                    for (_,value) in data
                    {
                        if let info = value as? [String: Any]{
                            if let uid = info["firebaseUserId"] as? String, let username = info["username"] as? String, let fullname = info["fullname"] as? String, let image = info["image_string"] as? String{
                                let newData = InviteUser(UID: uid, username: username, fullname: fullname, image: image)
                                self.selected[newData] = false
                                if newData.UID != AuthApi.getFirebaseUid(){
                                    let first = String(describing: newData.username.characters.first!).uppercased()
                                    
                                    if !self.sections.contains(first){
                                        self.sections.append(first)
                                        self.sectionMapping[first] = 1
                                        self.users[first] = [newData]
                                    }
                                    else{
                                        self.sectionMapping[first] = self.sectionMapping[first]! + 1
                                        self.users[first]?.append(newData)
                                    }
                                    if newData.username == self.username{
                                        self.selected[newData] = true
                                        self.contactHasBeenSelected(contact: newData, index: (self.users[first]?.count)! - 1)
                                    }
                                    
                                }
                            }
                        }
                    }
                }
                
                
                self.sections.sort()
                self.friendsTableView.reloadData()
            })
        }
        else{
            inviteTableTop.constant = 0
//            timeLabel.isHidden = true
//            timeOut.isHidden = true
            self.sections.removeAll()
            self.sectionMapping.removeAll()
            self.users.removeAll()
            
            
            let contactStore = CNContactStore()
            let keys = [CNContactPhoneNumbersKey, CNContactFamilyNameKey, CNContactGivenNameKey, CNContactNicknameKey, CNContactPhoneNumbersKey, CNContactImageDataKey]
            let request1 = CNContactFetchRequest(keysToFetch: keys  as [CNKeyDescriptor])
            
            try? contactStore.enumerateContacts(with: request1) { (contact, error) in
                if contact.phoneNumbers.count > 0 && (contact.givenName.characters.count > 0 || contact.familyName.characters.count > 0){
                    print(contact)
                    self.contacts.append(contact)
                }
                
            }
            
            for contact in contacts{
                let first = String(describing: contact.givenName.characters.first!).uppercased()
                
                var numbers = [String]()
                for number in contact.phoneNumbers{
                    numbers.append(number.value.stringValue)
                }
                let user = InviteUser(UID: numbers.joined(separator: ","), username: contact.givenName, fullname: contact.familyName)
                self.selected[user] = false
                if !self.sections.contains(first){
                    self.sections.append(first)
                    self.sectionMapping[first] = 1
                    self.users[first] = [user]
                }
                else{
                    self.sectionMapping[first] = self.sectionMapping[first]! + 1
                    self.users[first]?.append(user)
                }
            }
            
            self.sections.sort()
            friendsTableView.reloadData()
            
        }
        
        self.timePicker.datePickerMode = .time
        self.timePicker.minuteInterval = 5
        self.timeFormatter.dateFormat = "h:mm a"
        
        self.timePicker.addTarget(self, action: #selector(pickerChange(sender:)), for: UIControlEvents.valueChanged)
        
        self.friendsTableView.tableFooterView = UIView()
        hideKeyboardWhenTappedAround()
        
        let attrs = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont(name: "Avenir-Black", size: 18)!
        ]
        
        navBar.titleTextAttributes = attrs
        
        // Positon date picket within a view
        
        self.dateFormatter.dateFormat = "MMM d yyyy"
        self.dateFormatter.dateStyle = .short
        
        self.datePicker.datePickerMode = .date
        let date = Date()
        self.datePicker.minimumDate = date
        self.datePicker.maximumDate = Calendar.current.date(byAdding: .year, value: +100, to: Date())
        
        
//        self.dayTextField.delegate = self
//        self.dayTextField.attributedPlaceholder = NSAttributedString(string: "Choose a date", attributes: [NSForegroundColorAttributeName: UIColor(red: 122/255.0, green: 201/255.0, blue: 1/255.0, alpha: 1.0)])
        
    }
    
    //    MARK: Textfield Delegate Methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
//        self.dayTextField.inputAccessoryView = self.dateToolbar
//        self.dayTextField.inputView = self.datePicker
        //        eventDateTextField.inputView = self.datePicker
        return true
    }
    
    func dateSelected(){
//        self.dayTextField.text = "\(self.dateFormatter.string(from: self.datePicker.date))"
        self.view.endEditing(true)
    }
    
    // MARK: - Tableview Delegate Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.sectionMapping[self.sections[section]]!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.sections
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        tableView.scrollToRow(at: IndexPath(row: 0, section: index), at: UITableViewScrollPosition.top , animated: false)
        
        let temp = self.sections as NSArray
        return temp.index(of: title)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = sections[indexPath.section]
        let user = self.users[section]?[indexPath.row]
        
        
        let personToInviteCell = tableView.dequeueReusableCell(withIdentifier: "personToInvite", for: indexPath) as! InviteListTableViewCell
        personToInviteCell.delegate = self
        personToInviteCell.user = user
        
        if self.selected[user!]!{
            personToInviteCell.inviteConfirmationButton.isSelected = true
        }
        else{
            personToInviteCell.inviteConfirmationButton.isSelected = false
        }
        
        
        
        personToInviteCell.usernameLabel.text = user?.username
        personToInviteCell.fullNameLabel.text = user?.fullname
        if let image = user?.image_string, image.characters.count > 0{
            personToInviteCell.userProfileImage?.sd_setImage(with: URL(string: image)!, placeholderImage: #imageLiteral(resourceName: "placeholder_people"))
        }
        
        personToInviteCell.inviteConfirmationButton.tag = indexPath.row
        return personToInviteCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = sections[indexPath.section]
        let user = self.users[section]?[indexPath.row]
        
        
        let personToInviteCell = tableView.dequeueReusableCell(withIdentifier: "personToInvite", for: indexPath) as! InviteListTableViewCell
        
        
        if !self.selected[user!]!{
            personToInviteCell.inviteConfirmationButton.isSelected = true
            contactHasBeenSelected(contact: user!, index: index)
        }
        else{
            personToInviteCell.inviteConfirmationButton.isSelected = false
            contactHasBeenRemoved(contact: user!, index: index)
        }
    }
    
    func contactHasBeenSelected(contact: InviteUser, index: Int){
        contactListView.isHidden = false
        
        let section = String(describing: contact.username.characters.first!)
        let user = self.users[section.uppercased()]?[index]
        
        var selectedFriends = [String]()
        if !self.selected[user!]!
        {
            self.selected[user!]! = true
            
            
            for (user, flag) in self.selected{
                if flag{
                    selectedFriends.append(user.username)
                }
            }
            
            if selectedFriends.count > 0{
                friendsListBottom.constant = 57
            }
            contactList.text = selectedFriends.joined(separator: ", ")
            friendsTableView.reloadData()
        }
        else if username.characters.count > 0 && self.selected[user!]!{
            selectedFriends.append((user?.username)!)
            
            if selectedFriends.count > 0{
                friendsListBottom.constant = 57
            }
            contactList.text = selectedFriends.joined(separator: ", ")
            friendsTableView.reloadData()
        }
    }
    
    func contactHasBeenRemoved(contact: InviteUser, index: Int) {
        let section = String(describing: contact.username.characters.first!)
        let user = self.users[section.uppercased()]?[index]
        
        if self.selected[user!]! == true
        {
            self.selected[user!]! = false
            var selectedFriends = [String]()
            for (user, flag) in self.selected{
                if flag{
                    selectedFriends.append(user.username)
                }
            }
            if selectedFriends.count == 0{
                contactListView.isHidden = true
                friendsListBottom.constant = 0
            }
            contactList.text = selectedFriends.joined(separator: ", ")
            friendsTableView.reloadData()
        }
    }
    
    
    @IBAction func backPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func inviteUsers(_ sender: Any) {
        
        if type != "invite"{
            let time = NSDate().timeIntervalSince1970
            
            var inviteUIDList = [String]()
            
            for (user, flag) in self.selected{
                if flag{
                    inviteUIDList.append(user.UID)
                }
            }
            
            for UID in inviteUIDList{
                var name = ""
                if type == "place"{
                    name = (place?.name)!
                    Constants.DB.user.child(AuthApi.getFirebaseUid()!).observeSingleEvent(of: .value, with: { snapshot in
                        let user = snapshot.value as? [String : Any] ?? [:]
                        
                        let username = user["username"] as! String
                        sendNotification(to: UID, title: "New Invite", body: "\(String(describing: username)) invited you to \(String(describing: self.place?.name))", actionType: "", type: "place", item_id: "",item_name: "")
                    })
                    Constants.DB.places.child(id).child("invitations").childByAutoId().updateChildValues(["toUID":UID, "fromUID":AuthApi.getFirebaseUid()!,"time": Double(time),"inviteTime":inviteTime,"status": "sent"])
                    searchPlace?.showPopup = true
                    
//                    Constants.DB.user.child(UID).child("invitations").child(self.type).childByAutoId().updateChildValues(["ID":id, "time":time,"fromUID":AuthApi.getFirebaseUid()!, "name": name, "status": "unknown", "inviteTime": self.timeOut.titleLabel?.text!])
                    
                    
                    Answers.logCustomEvent(withName: "Invite User",
                                           customAttributes: [
                                            "type": "place",
                                            "user": AuthApi.getFirebaseUid()!,
                                            "invited": UID,
                                            "name": name
                        ])
                }
                else{
                    name = (event?.title)!
                    Constants.DB.user.child(AuthApi.getFirebaseUid()!).observeSingleEvent(of: .value, with: { snapshot in
                        let user = snapshot.value as? [String : Any] ?? [:]
                        
                        let username = user["username"] as! String
                        sendNotification(to: UID, title: "New Invite", body: "\(String(describing: username)) invited you to \(String(describing: self.place?.name))", actionType: "", type: "event", item_id: "", item_name: "")
                    })
                    Constants.DB.event.child((event?.id)!).child("invitations").childByAutoId().updateChildValues(["toUID":UID, "fromUID":AuthApi.getFirebaseUid()!,"time": Double(time),"status": "sent"])
                    searchEvent?.showInvitePopup = true
                    
                    Constants.DB.user.child(UID).child("invitations/event").queryOrdered(byChild: "ID").queryEqual(toValue: id).observeSingleEvent(of: .value, with: {snapshot in
                        
                        if snapshot.value == nil{
//                            Constants.DB.user.child(UID).child("invitations").child(self.type).childByAutoId().updateChildValues(["ID":self.id, "time":time,"fromUID":AuthApi.getFirebaseUid()!, "name": name, "status": "unknown", "inviteTime": self.timeOut.titleLabel?.text!])
                            
                        }
                    })
                }
            }
            dismiss(animated: true, completion: nil)
        }
        else{
            let messageVC = MFMessageComposeViewController()
            
            
            var inviteUIDList = [String]()
            
            for (user, flag) in self.selected{
                if flag{
                    inviteUIDList.append(user.UID)
                }
            }
            
            for UID in inviteUIDList{
                inviteUIDList.append(UID)
            }
            
            messageVC.body = "Open this link to join me on FOCUS and create a Map of Your World:"
            messageVC.recipients = inviteUIDList
            messageVC.messageComposeDelegate = self
            
            self.present(messageVC, animated: false, completion: nil)
        }
    }
    
    
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch (result) {
        case .cancelled:
            print("Message was cancelled")
            self.dismiss(animated: true, completion: nil)
        case .failed:
            print("Message failed")
            self.dismiss(animated: true, completion: nil)
        case .sent:
            print("Message was sent")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func timePushed(_ sender: Any) {
        
        timePicker.frame = CGRect(x: 0, y: (self.view.frame.height)-(timePicker.frame.height), width: self.view.frame.width, height: timePicker.frame.height)
        timePicker.backgroundColor = UIColor.white
        timePicker.inputAccessoryView
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(screenTapWithPicker(sender:)))
        self.view.addGestureRecognizer(tap)
        
        self.view.addSubview(timePicker)
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func screenTapWithPicker(sender: UITapGestureRecognizer)
    {
        timePicker.removeFromSuperview()
    }
    
    func pickerChange(sender: UIDatePicker)
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        let dateString = dateFormatter.string(from: sender.date)
//        timeOut.setTitle(dateString, for: UIControlState.normal)
        inviteTime = dateString
    }
    
    
}
