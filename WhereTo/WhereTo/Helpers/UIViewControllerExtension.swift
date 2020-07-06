//
//  UIViewControllerExtension.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Contacts

// MARK: - Navigation

extension UIViewController {
    
    enum StoryboardNames: String {
        case Main
        case TabViewHome
        case VotingSession
    }
    
    func transitionToStoryboard(named storyboard: StoryboardNames, direction: CATransitionSubtype = .fromLeft, completion: @escaping () -> Void = {}) {
        // Make sure the user is not already on the given storyboard
        guard let currentStoryboard = self.storyboard?.value(forKey: "name") as? String,
            currentStoryboard != storyboard.rawValue
            else { return }
        guard !(currentStoryboard == "WhereTo" && storyboard == .TabViewHome) else { return completion() }
        
        // Get the reference to the new storyboard
        let storyboard = UIStoryboard(name: storyboard.rawValue, bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController() else { return }
        initialVC.modalPresentationStyle = .fullScreen
        
        // Make the transition look like navigating forward through a navigation controller
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = .push
        transition.subtype = direction
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.window?.layer.add(transition, forKey: kCATransition)
        
        present(initialVC, animated: false, completion: completion)
    }
    
    func transitionToVotingSessionPage(with votingSession: VotingSession) {
        let storyboard = UIStoryboard(name: StoryboardNames.VotingSession.rawValue, bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController() as? VotingSessionViewController else { return }
        initialVC.votingSession = votingSession
        initialVC.modalPresentationStyle = .fullScreen
        
        // Make the transition look like navigating forward through a navigation controller
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = .push
        transition.subtype = .fromRight
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.window?.layer.add(transition, forKey: kCATransition)
        
        present(initialVC, animated: false)
    }
}
    
// MARK: - Alerts

var simpleAlert: UIAlertController?
extension UIViewController {
    
    // Generic Alerts
    
    // Present an alert with a simple dismiss button to display a message to the user
    func presentAlert(title: String, message: String, completion: @escaping () -> Void = { () in }) {
        // Create the alert controller
        simpleAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the dismiss button to the alert
        simpleAlert?.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { [weak self] (_) in
            completion()
            self?.handleNextNotification()
        }))
        
        // Present the alert
        if let simpleAlert = simpleAlert { present(simpleAlert, animated: true) }
    }
    
    // Present an alert that the internet connection isn't working
    func presentInternetAlert() {
        presentAlert(title: "No Internet Connection", message: "You must be connected to the internet in order to use WhereTo. Please check your internet connection and try again")
    }
    
    // Present an alert with simple confirm or cancel buttons
    func presentChoiceAlert(title: String, message: String, cancelText: String = "Cancel", confirmText: String = "Confirm", cancelCompletion: @escaping () -> Void = {}, confirmCompletion: @escaping () -> Void) {
        // Create the alert controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the cancel button to the alert
        alertController.addAction(UIAlertAction(title: cancelText, style: .cancel, handler: { [weak self] (_) in cancelCompletion()
            self?.handleNextNotification()
        }))
        
        // Add the confirm button to the alert
        alertController.addAction(UIAlertAction(title: confirmText, style: .default, handler: { [weak self] (_) in confirmCompletion()
            self?.handleNextNotification()
        }))
        
        // Present the alert
        present(alertController, animated: true)
    }
    
    // Present an alert with a text field to get some input from the user
    func presentTextFieldAlert(title: String, message: String, textFieldPlaceholder: String?, textFieldText: String? = nil, saveButtonTitle: String = "Save", keyboardType: UIKeyboardType = .default, completion: @escaping (String) -> Void) {
        // Create the alert controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the text field
        alertController.addTextField { (textField) in
            textField.placeholder = textFieldPlaceholder
            textField.keyboardType = keyboardType
            if let textFieldText = textFieldText {
                textField.text = textFieldText
            }
        }
        
        // Create the cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (_) in
            self?.handleNextNotification()
        }
        
        // Create the save button
        let saveAction = UIAlertAction(title: saveButtonTitle, style: .default) { [weak self] (_) in
            // Get the text from the text field
            guard let text = alertController.textFields?.first?.text, !text.isEmpty else { return }
            
            // Pass it to the helper function to handle sending the friend request
            completion(text)
            
            self?.handleNextNotification()
        }
        
        // Add the buttons to the alert and present it
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        present(alertController, animated: true)
    }
    
    // Present an alert at the bottom of the screen to display an error to the user
    func presentErrorAlert(_ localizedError: LocalizedError) {
        // Create the alert controller
        let alertController = UIAlertController(title: "ERROR", message: localizedError.errorDescription, preferredStyle: .actionSheet)
        
        // Add the dismiss button to the alert
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { [weak self] (_) in
            self?.handleNextNotification()
        }))
        
        // Present the alert
        present(alertController, animated: true)
    }
    func presentErrorAlert(_ error: Error) {
        // Create the alert controller
        let alertController = UIAlertController(title: "ERROR", message: error.localizedDescription, preferredStyle: .actionSheet)
        
        // Add the dismiss button to the alert
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { [weak self] (_) in
            self?.handleNextNotification()
        }))
        
        // Present the alert
        present(alertController, animated: true)
    }
    
    // Friend Request Alerts
    
    func presentNewFriendRequestAlert(_ friendRequest: FriendRequest) {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Create the alert controller
        let alertController = UIAlertController(title: "New Friend Request", message: "\(friendRequest.fromName) has sent you a friend request!", preferredStyle: .alert)
        
        // Add the cancel button to the alert
        let denyAction = UIAlertAction(title: "Deny", style: .cancel, handler: { (_) in
            FriendRequestController.shared.respondToFriendRequest(friendRequest, accept: false) { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Offer the user a chance to block that person
                        self?.presentChoiceAlert(title: "Block?", message: "Would you like to block \(friendRequest.fromName) from sending you friend requests in the future?", cancelText: "No", confirmText: "Yes, block", confirmCompletion: {
                            
                            // Add the friend's ID to the user's list of blocked people
                            currentUser.blockedUsers.append(friendRequest.fromID)
                            
                            // Save the changes to the user
                            UserController.shared.saveChanges(to: currentUser) { (result) in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success(_):
                                        // Display the success
                                        self?.presentAlert(title: "Successfully Blocked", message: "You have successfully blocked \(friendRequest.fromName)")
                                    case .failure(let error):
                                        // Print and display the error
                                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                        self?.presentErrorAlert(error)
                                    }
                                }
                            }
                        })
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        })
        
        // Add the confirm button to the alert
        let acceptAction = UIAlertAction(title: "Accept", style: .default, handler: { (_) in
            FriendRequestController.shared.respondToFriendRequest(friendRequest, accept: true) { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Display the success
                        self?.presentAlert(title: "Added Friend", message: "You have successfully added \(friendRequest.fromName) as a friend!")
                        
                        // Send a notification for the list of friends to be updated
                        NotificationCenter.default.post(Notification(name: .updateFriendsList))
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        })
        
        // And the buttons and present the alert
        alertController.addAction(denyAction)
        alertController.addAction(acceptAction)
        present(alertController, animated: true)
    }
    
    func presentFriendRequestResponseAlert(_ friendRequest: FriendRequest) {
        presentAlert(title: "Friend Request \(friendRequest.status == .accepted ? "Accepted" : "Denied")",
            message: "\(friendRequest.toName) has \(friendRequest.status == .accepted ? "accepted" : "denied") your friend request")
    }
    
    // Voting Session Invitation Alert
    
    func presentVotingSessionInvitationAlert(_ votingSessionInvite: VotingSessionInvite, completion: @escaping (VotingSession?) -> Void) {
        // Create the alert controller
        let alertController = UIAlertController(title: "Vote!", message: "\(votingSessionInvite.fromName) has invited you to vote on a place to eat!", preferredStyle: .alert)
        
        // Create the deny button
        let denyAction = UIAlertAction(title: "No Thanks", style: .cancel) { (_) in
            VotingSessionController.shared.respond(to: votingSessionInvite, accept: false) { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        self?.handleNextNotification()
                        return completion(nil)
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                        return completion(nil)
                    }
                }
            }
        }
        
        // Create the accept button
        let acceptAction = UIAlertAction(title: "Vote!", style: .default) { (_) in
            VotingSessionController.shared.respond(to: votingSessionInvite, accept: true) { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let votingSession):
                        self?.handleNextNotification()
                        return completion(votingSession)
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                        return completion(nil)
                    }
                }
            }
        }
        
        // Add the buttons and present the alert
        alertController.addAction(denyAction)
        alertController.addAction(acceptAction)
        present(alertController, animated: true)
    }
    
    // Voting Session Results Alert
    
    func presentVotingSessionResultAlert(_ votingSession: VotingSession) {
        guard let winningRestaurant = votingSession.winningRestaurant else { return }
        
        // Create the alert controller
        let alertController = UIAlertController(title: "Vote Decided!", message: "The crowd has spoken! You have decided to eat at \(winningRestaurant.name)!", preferredStyle: .alert)
        
        // Create the dismiss button
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel) { [weak self] (_) in
            self?.handleNextNotification()
        }
        
        // Create the open in maps button
        let openInMapsAction = UIAlertAction(title: "Open in Maps", style: .default) { [weak self] (_) in
            guard let restaurant = RestaurantController.shared.previousRestaurants?.last else {
                self?.handleNextNotification()
                return
            }
            self?.launchMapWith(restaurant: restaurant )
        }
        
        // Add the buttons and present the alert
        alertController.addAction(dismissAction)
        alertController.addAction(openInMapsAction)
        present(alertController, animated: true)
    }
    
    // Random Restaurant Alert
    
    func presentRandomRestaurantAlert(_ restaurant: Restaurant) {
        // Create the alert controller
        let alertController = UIAlertController(title: "Restaurant Decided!", message: "The randomizer algorithm has spoken! You have decided to eat at \(restaurant.name)!", preferredStyle: .alert)
        
        // Create the dismiss button
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel) { [weak self] (_) in
            self?.handleNextNotification()
        }
        
        // Create the open in maps button
        let openInMapsAction = UIAlertAction(title: "Open in Maps", style: .default) { [weak self] (_) in
            self?.launchMapWith(restaurant: restaurant)
        }
        
        // Add the buttons and present the alert
        alertController.addAction(dismissAction)
        alertController.addAction(openInMapsAction)
        present(alertController, animated: true)
    }
}

// MARK: - Respond to and Display Notifications

// Names of local notifications
extension Notification.Name {
    static let notificationEnqueued = Notification.Name("notificationEnqueued")
    static let newFriendRequest = Notification.Name("newFriendRequest")
    static let responseToFriendRequest = Notification.Name("responseToFriendRequest")
    static let updateFriendsList = Notification.Name("updateFriendsList")
    static let newVotingSessionInvitation = Notification.Name("newVotingSessionInvitation")
    static let votingSessionResult = Notification.Name("votingSessionResult")
    static let updateActiveSessionsButton = Notification.Name("updateActiveSessionsButton")
    static let updateHistoryList = Notification.Name("updateHistoryList")
    static let updateSavedList = Notification.Name("updateSavedList")
    static let updateProfileView = Notification.Name("updateProfileView")
}

// A queue of all the notifications to be displayed
var notificationQueue: [Notification] = []

extension UIViewController {
    
    func setUpNotificationObservers() {
        // Set up observers to listen for when notifications are added to the queue
        NotificationCenter.default.addObserver(self, selector: #selector(handleNextNotification), name: .notificationEnqueued, object: nil)
        
//        // Set up the observers to listen for friend request notifications
//        NotificationCenter.default.addObserver(self, selector: #selector(showNewFriendRequest(_:)), name: .newFriendRequest, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(showFriendRequestResult(_:)), name: .responseToFriendRequest, object: nil)
//
//        // Set up the observer to listen for voting session invitation notifications
//        NotificationCenter.default.addObserver(self, selector: #selector(showVotingSessionInvitation(_:)), name: .newVotingSessionInvitation, object: nil)
//
//        // Set up the observer to listen for voting session result notifications
//        NotificationCenter.default.addObserver(self, selector: #selector(showVotingSessionResult(_:)), name: .votingSessionResult, object: nil)
    }
    
    @objc func handleNextNotification() {
        // Make sure there is a notification waiting to be displayed and that no alert is currently being displayed
        guard notificationQueue.count > 0, presentedViewController == nil else { return }
        
        // Get the next notification in line from the queue
        let notification = notificationQueue.removeFirst()
        
        // Call the relevant helper function for that notification
        switch notification.name {
        case .newFriendRequest:
            showNewFriendRequest(notification)
        case .responseToFriendRequest:
            showFriendRequestResult(notification)
        case .newVotingSessionInvitation:
            showVotingSessionInvitation(notification)
        case .votingSessionResult:
            showVotingSessionResult(notification)
        default:
            print("This shouldn't happen: Notification received with name \(notification.name)")
        }
    }
    
    func showNewFriendRequest(_ notification: Notification) {
        guard let friendRequest = notification.object as? FriendRequest else { return }
        DispatchQueue.main.async { self.presentNewFriendRequestAlert(friendRequest) }
    }
    
    func showFriendRequestResult(_ notification: Notification) {
        guard let friendRequest = notification.object as? FriendRequest else { return }
        DispatchQueue.main.async { self.presentFriendRequestResponseAlert(friendRequest) }
    }
    
    func showVotingSessionInvitation(_ notification: Notification) {
        guard let votingSessionInvite = notification.object as? VotingSessionInvite else { return }
        DispatchQueue.main.async {
            self.presentVotingSessionInvitationAlert(votingSessionInvite) { [weak self] (newVotingSession) in
                // If the user accepted the invitation, add it to the source of truth and transition them to the voting session page
                if let newVotingSession = newVotingSession {
                    VotingSessionController.shared.votingSessions?.append(newVotingSession)
                    self?.transitionToVotingSessionPage(with: newVotingSession)
                }
            }
        }
    }
    
    func showVotingSessionResult(_ notification: Notification) {
        guard let votingSession = notification.object as? VotingSession else { return }
        DispatchQueue.main.async {
            // First dismiss any existing alert
            simpleAlert?.dismiss(animated: true, completion: {
                self.transitionToStoryboard(named: .TabViewHome) {
                    self.presentVotingSessionResultAlert(votingSession)
                }
            })
        }
    }
}

// MARK: - inviteFriendsTVC Alerts

extension UIViewController {
    
    // Present an alert with a text field to get some input from the user
    func presentLocationSelectionAlert(currentLocation: CLLocation, completion: @escaping (Result<CLLocation, WhereToError>) -> Void) {
        // Create the alert controller
        let alertController = UIAlertController(title: "Where To?", message: "Use Current location or enter an address to get available restaurant options", preferredStyle: .alert)
        
        // Add the text field
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter address or city here..."
        }
        
        // Create the cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // Create the Current Location button
        let currentLocation = UIAlertAction(title: "Current Location", style: .default) { (_) in
            return completion(.success(currentLocation))
        }
        
        let enteredLocation = UIAlertAction(title: "Use Entered Address", style: .default) { [weak self] (_) in
            // Get the text from the text field
            guard let address = alertController.textFields?.first?.text, !address.isEmpty else { return }
            
            // Create CLLocation using GeoCoding
            self?.getLocationFromString(addressString: address) { (result) in
                switch result {
                case .success(let location):
                    return completion(.success(location))
                case .failure(let error):
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.noLocationForAddress))
                }
            }
        }
        // Add the buttons to the alert and present it
        alertController.addAction(cancelAction)
        alertController.addAction(currentLocation)
        alertController.addAction(enteredLocation)
        present(alertController, animated: true)
    }
}

// MARK: - savedRestaurantsTVC Alerts

extension UIViewController {
    
    func presentLocationSelectionAlert(completion: @escaping (Result<Bool, WhereToError>) -> Void) {
        // Create the alert controller
        let alertController = UIAlertController(title: "Are you sure you want to remove from favorites?", message: "", preferredStyle: .alert)
        
        // Create the cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // Create the Current Location button
        let removeFromFavorites = UIAlertAction(title: "Yes", style: .default) { (_) in
            completion(.success(true))
            }
        
        // Add the buttons to the alert and present it
        alertController.addAction(cancelAction)
        alertController.addAction(removeFromFavorites)
        present(alertController, animated: true)
    }
    
    // Present an alert with a text field to get some input from the user
    func presentAddRestaurantBySearchAlert(completion: @escaping (Result<[String], WhereToError>) -> Void) {
        // Create the alert controller
        let alertController = UIAlertController(title: "", message: "Enter the name of the restaurant then search by current location or enter address to search from.", preferredStyle: .alert)
        
        // Add text fields
        alertController.addTextField { (restaurantName) in
            restaurantName.placeholder = "Enter restaurant name here..."
        }
        
        alertController.addTextField { (location) in
            location.placeholder = "Enter address or city, state"
        }
        
        // Create the cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let currentLocationAction = UIAlertAction(title: "Search Current Location", style: .default) { (_) in
            // Get the text from text field
            guard let name = alertController.textFields?.first?.text, !name.isEmpty else { return }
            completion(.success([name]))
        }
        
        let enteredLocationAction = UIAlertAction(title: "Search Entered Address", style: .default) { (_) in
            // Get the text from the text field
            guard let address = alertController.textFields?[1].text, !address.isEmpty,
                let name = alertController.textFields?.first?.text, !name.isEmpty
                else { return }
            completion(.success([name, address]))
            }
        
        // Add the buttons to the alert and present it
        alertController.addAction(cancelAction)
        alertController.addAction(currentLocationAction)
        alertController.addAction(enteredLocationAction)
        present(alertController, animated: true)
    }
}

// MARK: - Activity indicator

extension UIView {
    func activityStartAnimating() {
        DispatchQueue.main.async {
            let backgroundView = UIView()
            backgroundView.frame = CGRect.init(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
            backgroundView.backgroundColor = .activityIndicatorBackground
            backgroundView.tag = 475647
            
            let activityIndicator = UIActivityIndicatorView(frame: backgroundView.frame)
            activityIndicator.center = backgroundView.center
            activityIndicator.hidesWhenStopped = true
            activityIndicator.style = .large
            activityIndicator.color = .activityIndicator
            activityIndicator.startAnimating()
            self.isUserInteractionEnabled = false
            
            backgroundView.addSubview(activityIndicator)
            
            self.addSubview(backgroundView)
        }
    }
    
    func activityStopAnimating() {
        DispatchQueue.main.async {
            if let background = self.viewWithTag(475647){
                background.removeFromSuperview()
            }
            self.isUserInteractionEnabled = true
        }
    }
}

// MARK: LocationManagerDelegate

extension UIViewController: CLLocationManagerDelegate {
    
    // methods for locationManagerDelegate
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .notDetermined:
            print("Location permissions haven't been shown to the user yet.")
        case .restricted:
            print("Parental control setting disallows loacation data.")
        case .denied:
            print("User has disallowed permission, unable to get location data.")
        case .authorizedAlways:
            print("User has allowed app to get location data when app is active or in background.")
        case .authorizedWhenInUse:
            print("User has allowed app to get location data when app is active.")
        @unknown default:
            print("Unknown failure.")
            fatalError()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // TODO: show alert that getting current location failed
        
    }
    
    func getLocationFromString(addressString: String, completion: @escaping(Result<CLLocation, WhereToError>) -> Void) {
        
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(addressString) { (placemarks, error) in
            if error == nil {
                if let placemark = placemarks?[0] {
                    let location = placemark.location!
                
                    return completion(.success(location))
                }
            }
            return completion(.failure(.noLocationForAddress))
        }
    }
    
    func lookUpAddressFromLocation(location: CLLocation, completionHandler: @escaping (CLPlacemark?) -> Void ) {
        
        let geocoder = CLGeocoder()
                
        // Look up the location and pass it to the completion handler
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
            if error == nil {
                let firstLocation = placemarks?[0]
                completionHandler(firstLocation)
            }
               else {
                // An error occurred during geocoding.
                completionHandler(nil)
            }
        })
    }
    
    func fetchCurrentLocation(_ locationManager: CLLocationManager) {
        // retrieve authorization status
        let status = CLLocationManager.authorizationStatus()
        
        if(status == .denied || status == .restricted || !CLLocationManager.locationServicesEnabled()) {
            // show alert telling user they need to allow location data to use features of the app
            return
        }
        
        if(status == .notDetermined) {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        // Set Desired Accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        // Can now request location since status is Authorized
        locationManager.requestLocation()
    }
}

// MARK: - Apple Maps

extension UIViewController {
    
    func launchMapWith(restaurant: Restaurant) {
        
        guard let lat = restaurant.coordinates["latitude"],
            let lon = restaurant.coordinates["longitude"],
            let latitude = CLLocationDegrees(exactly: lat),
            let longitude = CLLocationDegrees(exactly: lon)
            else { return }
        
        // Create MKMapItem
        var mapItem: MKMapItem? {
            
            let location = restaurant.location.displayAddress.joined(separator: ", ")
            
            let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
          
            let addressDict = [CNPostalAddressStreetKey: location]
            let placemark = MKPlacemark(
                coordinate: coordinates,
                addressDictionary: addressDict)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = restaurant.name
            mapItem.url = URL(string: restaurant.url)
            return mapItem
        }
        
        mapItem?.openInMaps()
    }
}
