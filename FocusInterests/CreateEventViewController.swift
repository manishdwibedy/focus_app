//
//  CreateEventViewController.swift
//  FocusInterests
//
//  Created by Manish Dwibedy on 4/18/17.
//  Copyright © 2017 singlefocusinc. All rights reserved.
//

import UIKit
import GooglePlaces
import FirebaseDatabase

class CreateEventViewController: UIViewController {

    var event: Event?
    var place: GMSPlace?
    let datePicker = UIDatePicker()
    
    @IBOutlet weak var desc: UITextView!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var address: UITextField!
    @IBOutlet weak var time: UITextField!
    @IBOutlet weak var isPrivate: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Create Pin"
        showDateTime()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func createPin(_ sender: UIButton) {
        if place != nil{
            let locality = self.place?.addressComponents?[0].name
            let street = self.place?.addressComponents?[1].name
            _ = "\(locality!), \(street!)"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, h:mm a"
            
            
//            self.event = Event(title: name.text!, description: desc.text!, fullAddress: (self.place?.formattedAddress)!, shortAddress: shortAddress, latitude: (self.place?.coordinate.latitude.debugDescription)!, longitude: (self.place?.coordinate.longitude.debugDescription)!, date: dateFormatter.string(from: self.datePicker.date), creator: AuthApi.getFirebaseUid()!, category: )
        }
        
    }

    func showDateTime(){
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(dateTimeSelected))
        toolbar.setItems([done], animated: false)
        time.inputAccessoryView = toolbar
        
        time.inputView = datePicker
    }
    
    @IBAction func addPlace(_ sender: UITextField) {
        let autocompleteController = GMSAutocompleteViewController()
        
        autocompleteController.delegate = self
        
        present(autocompleteController, animated: true, completion: nil)
    }
    
    func dateTimeSelected(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm a"

        self.time.text = "\(dateFormatter.string(from: self.datePicker.date))"
        self.view.endEditing(true)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "add_event_icon"{
            let destinationVC = segue.destination as! EventIconViewController
            destinationVC.event = self.event
        }
    }
}

extension CreateEventViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        self.place = place
        self.address.text = place.formattedAddress!
        
        print("Place name: \(place.name)")
        
        print("Place address: \(String(describing: place.formattedAddress))")
        
        print("Place attributions: \(String(describing: place.attributions))")
        
        dismiss(animated: true, completion: nil)
        
    }
    
    
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        
        // TODO: handle the error.
        
        print("Error: ", error.localizedDescription)
        
    }
    
    
    
    // User canceled the operation.
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    // Turn the network activity indicator on and off again.
    
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
    }
    
    
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
    }
    
    
    
}


