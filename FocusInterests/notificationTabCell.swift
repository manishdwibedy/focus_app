//
//  notificationTabCell.swift
//  FocusInterests
//
//  Created by Andrew Simpson on 6/16/17.
//  Copyright © 2017 singlefocusinc. All rights reserved.
//

import UIKit

class notificationTabCell: UITableViewCell {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var typePic: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var whatLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var data: NSDictionary!
    var parentVC: NotificationFeedViewController? = nil
    var notification: FocusNotification? = nil
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.profileImage.layer.borderColor = UIColor(red: 122/255.0, green: 201/255.0, blue: 1/255.0, alpha: 1.0).cgColor
        self.profileImage.layer.borderWidth = 2
        self.profileImage.layer.cornerRadius = self.profileImage.frame.width/2
        self.profileImage.clipsToBounds = true
        
        self.typePic.layer.borderColor = UIColor(red: 122/255.0, green: 201/255.0, blue: 1/255.0, alpha: 1.0).cgColor
        self.typePic.layer.borderWidth = 2
        self.typePic.layer.cornerRadius = self.profileImage.frame.width/2
        self.typePic.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
     func setupCell(notif: FocusNotification) {
        self.notification = notif
        data = notif.item?.data
        
        var usernameStr = ""
        var actionStr = ""
        var whatStr = ""
        
        if notif.type == .Following{
            if let image_string = notif.sender?.imageURL{
                if let url = URL(string: image_string){
                    self.profileImage.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "placeholder_people"))
                }
                else{
                    self.profileImage.image = #imageLiteral(resourceName: "placeholder_place")
                }
            }
            else{
                self.profileImage.image = #imageLiteral(resourceName: "placeholder_place")
            }
            
            
            let attrString: NSMutableAttributedString = NSMutableAttributedString(string:notif.sender!.username! + " ")
            attrString.addAttribute(NSForegroundColorAttributeName, value:Constants.color.green, range: NSMakeRange(0,  notif.sender!.username!.characters.count))
            
            let other = "started following you"
            let otherAttrString: NSMutableAttributedString = NSMutableAttributedString(string:other)
            otherAttrString.addAttribute(NSForegroundColorAttributeName, value:UIColor.white, range: NSMakeRange(0,  other.characters.count))
            attrString.append(otherAttrString)
            
            self.usernameLabel.attributedText = attrString
            self.typePic.isHidden = true
            self.timeLabel.text = DateFormatter().timeSince(from: notif.time!, numericDates: true, shortVersion: true)
            
            return
        }
        if let sender = data["senderID"] as? String{
            Constants.DB.user.child(sender).observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                
                self.profileImage.sd_setImage(with: URL(string:(value?["image_string"])! as! String), placeholderImage: #imageLiteral(resourceName: "placeholder_people"))
                
                self.profileImage.setShowActivityIndicator(true)
                self.profileImage.setIndicatorStyle(.gray)
                
            })

        }
        
        self.profileImage.image = #imageLiteral(resourceName: "placeholder_people")
        if let image_url = notif.sender?.imageURL{
            self.profileImage.sd_setImage(with: URL(string:(image_url)), placeholderImage: #imageLiteral(resourceName: "placeholder_people"))
            
            
            self.profileImage.setShowActivityIndicator(true)
            self.profileImage.setIndicatorStyle(.gray)
        }
        
        if let type = data["type"] as? String{
            if type == "event"{
                Constants.DB.event.child(data["id"] as! String).observeSingleEvent(of: .value, with: { (snapshot) in
                    _ = snapshot.value as? NSDictionary
                    
                    let placeholderImage = UIImage(named: "empty_event")
                    
                    let reference = Constants.storage.event.child("\(self.data["id"] as! String ).jpg")
                    
                    
                    reference.downloadURL(completion: { (url, error) in
                        
                        if error != nil {
                            print(error?.localizedDescription ?? "")
                            return
                        }
                        
                        self.typePic.sd_setImage(with: url, placeholderImage: placeholderImage)
                        self.typePic.setShowActivityIndicator(true)
                        self.typePic.setIndicatorStyle(.gray)
                        
                    })
                })
            }
            else if type == "pin"{
                let pinData = notif.item?.data["pin"] as? pinData
                pinData?.dbPath.observeSingleEvent(of: .value, with: { (snapshot) in
                    let value = snapshot.value as? NSDictionary
                    if value != nil
                    {
                        
                        if value?["images"] != nil
                        {
                            var firstVal = ""
                            print("images")
                            print((value?["images"])!)
                            for (key,_) in (value?["images"] as! NSDictionary)
                            {
                                firstVal = key as! String
                                break
                            }
                            
                            let reference = Constants.storage.pins.child(((value?["images"] as! NSDictionary)[firstVal] as! NSDictionary)["imagePath"] as! String)
                            reference.downloadURL(completion: { (url, error) in
                                
                                if error != nil {
                                    print(error?.localizedDescription ?? "")
                                    return
                                }
                                
                                self.typePic.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "placeholder_pin"))
                                self.typePic.setShowActivityIndicator(true)
                                self.typePic.setIndicatorStyle(.gray)
                                
                                
                                
                            })
                            
                        }else
                        {
                            self.typePic.image = #imageLiteral(resourceName: "placeholder_pin")
                        }
                        
                    }
                })
            }
            else{
                let place = notif.item?.data["place"] as? Place
                
                if let image = place?.image_url{
                    if let url = URL(string: image){
                        self.typePic.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "placeholder_place"))
                    }
                    
                }
                
            }

        }
        
        self.timeLabel.text = getTimeSince(date: notif.time!)
        
        if let actionType = data["actionType"] as? String{
            if actionType == "like"{
                actionStr = "liked"
            } else if actionType == "comment"{
                actionStr = "commented"
            } else{
                actionStr = "is coming to"
            }
        
            if data["type"] as! String == "event"{
                whatStr = "\(notif.item!.itemName!)"
            } else if data["type"] as! String == "pin"{
                if data["actionType"] as! String == "like"{
                    whatStr = "your Pin"
                }
                else{
                    whatStr = "on your Pin: \"\(notif.item!.itemName!.trimmingCharacters(in: .whitespacesAndNewlines))\""
                }
                
            }
            else if data["type"] as! String == "place"{
                whatStr = "\(notif.item!.itemName!)"
            }
            
            loadAttr(component1: (notif.sender?.username)!, component2: actionStr, component3: whatStr)
        }
        
        
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(showUser(sender:)))
        self.profileImage.isUserInteractionEnabled = true
        self.profileImage.addGestureRecognizer(tap)
        
     }
    
    
    func showUser(sender: UITapGestureRecognizer)
    {
        let VC = UIStoryboard(name: "UserProfile", bundle: nil).instantiateViewController(withIdentifier: "Home") as! UserProfileViewController
        
        VC.otherUser = true
        VC.previous = .notification
        VC.userID = (self.notification?.sender?.uuid)!
        dropfromTop(view: (parentVC?.view)!)
        
        parentVC?.present(VC, animated:true, completion:nil)
    }
    
    func loadAttr(component1:String,component2:String,component3:String){
        let attrString: NSMutableAttributedString = NSMutableAttributedString(string:component1 + " ")
        attrString.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 122/255, green: 201/255, blue: 1/255, alpha: 1), range: NSMakeRange(0,  component1.characters.count))
        
        let descString: NSMutableAttributedString = NSMutableAttributedString(string: component2 + " ")
        descString.addAttribute(NSForegroundColorAttributeName, value: UIColor.white, range: NSMakeRange(0, component2.characters.count))
        
        attrString.append(descString);
        if data["type"] as! String == "event"{
            let descString2: NSMutableAttributedString = NSMutableAttributedString(string: component3)
            descString2.addAttribute(NSForegroundColorAttributeName, value: Constants.color.pink, range: NSMakeRange(0, component3.characters.count))
            attrString.append(descString2);
            
        } else if data["type"] as! String == "pin"{
            let descString2: NSMutableAttributedString = NSMutableAttributedString(string: component3)
            descString2.addAttribute(NSForegroundColorAttributeName, value: Constants.color.green, range: NSMakeRange(0, component3.characters.count))
            attrString.append(descString2);
        }
        else if data["type"] as! String == "place"{
            let descString2: NSMutableAttributedString = NSMutableAttributedString(string: component3)
            descString2.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 36/255, green: 209/255, blue: 219/255, alpha: 1), range: NSMakeRange(0, component3.characters.count))
            attrString.append(descString2);
        }
        
        self.usernameLabel.attributedText = attrString
    }
    
    func getTimeSince(date:Date) -> String
    {
        var returnString = ""
        let now = Date()
        let seconds = now.timeIntervalSince(date)
        let minutes = seconds/60
        let hours = minutes/60
        let days = hours/24
        if Int(days) >= 1
        {
            returnString = String(Int(days)) + "d ago"
            
        }else if Int(hours) >= 1
        {
            returnString = String(Int(hours)) + "h ago"
            
        }else if Int(minutes) >= 1
        {
            returnString = String(Int(minutes)) + "m ago"
            
        }else if seconds < 60
        {
            returnString = "s ago"
        }
        
        return returnString
    }

    
    
    
    
    
    
    
}
