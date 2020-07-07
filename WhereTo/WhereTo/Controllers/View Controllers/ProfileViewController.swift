//
//  ProfileViewController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/23/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var addRestrictionButton: UIButton!
    @IBOutlet weak var dietaryRestrictionsTableView: UITableView!
    @IBOutlet weak var dietaryRestrictionsPickerView: UIPickerView!
    
    // MARK: - Properties
    
    var imagePicker = UIImagePickerController()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Set up the observer to listen for notifications telling any view to display an alert
        setUpNotificationObservers()
        
        // Set up the observer to update the view once the photo has loaded
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUI), name: .updateProfileView, object: nil)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotate(from: fromInterfaceOrientation)
        profileImageView.addCornerRadius(profileImageView.frame.height / 2)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.addCornerRadius(profileImageView.frame.height / 2)
    }
    
    // MARK: - Respond to Notifications
    
    @objc func refreshUI() {
        DispatchQueue.main.async { self.profileImageView.image = UserController.shared.currentUser?.photo }
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        imagePicker.delegate = self
        
        profileImageView.image = currentUser.photo ?? #imageLiteral(resourceName: "default_profile_picture")
        nameLabel.text = currentUser.name
        emailLabel.text = "Email: \(currentUser.email)"
        
        if currentUser.dietaryRestrictions.count == User.DietaryRestriction.allCases.count {
            addRestrictionButton.isHidden = true
        }
        
        dietaryRestrictionsTableView.delegate = self
        dietaryRestrictionsTableView.dataSource = self
        dietaryRestrictionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "dietaryRestrictionCell")
        
        dietaryRestrictionsPickerView.delegate = self
        dietaryRestrictionsPickerView.dataSource = self
    }
    
    // MARK: - Actions
    
    @IBAction func screenTouched(_ sender: UITapGestureRecognizer) {
        dietaryRestrictionsPickerView.isHidden = true
    }
    
    @IBAction func editImageButtonTapped(_ sender: Any) {
        dietaryRestrictionsPickerView.isHidden = true
        
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Create an alert controller with options for how to get a photo
        let alertController = UIAlertController(title: "Choose a Photo", message: nil, preferredStyle: .alert)
        
        // Add a button option for the photo library
        let photoLibraryAction = UIAlertAction(title: "Choose a photo from the library", style: .default) { [weak self] (_) in
            self?.openPhotoLibrary()
        }
        
        // Add a button option for the camera
        let cameraAction = UIAlertAction(title: "Take a photo with the camera", style: .default) { [weak self] (_) in
            self?.openCamera()
        }
        
        // Add a button for the user to dismiss the alert
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (_) in
            self?.imagePicker.dismiss(animated: true, completion: nil)
        }
        
        // Add the actions and present the alert
        alertController.addAction(photoLibraryAction)
        alertController.addAction(cameraAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    @IBAction func editNameButtonTapped(_ sender: Any) {
        dietaryRestrictionsPickerView.isHidden = true
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Present an alert allowing the user to enter a new name
        presentTextFieldAlert(title: "Enter a new username", message: "Choose how your name will appear to your friends", textFieldPlaceholder: nil, textFieldText: currentUser.name) { [weak self] (newName) in
            // Make sure the new username is valid
            guard !newName.isEmpty, newName != "" else {
                self?.presentAlert(title: "Invalid Username", message: "Your name cannot be blank")
                return
            }
            
            // Update the user's name
            currentUser.name = newName
            
            // Save the updated name to the cloud
            UserController.shared.saveChanges(to: currentUser) { (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Update the view
                        self?.nameLabel.text = newName
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
    }
    
    @IBAction func resetPasswordButtonTapped(_ sender: UIButton) {
        dietaryRestrictionsPickerView.isHidden = true
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Present an alert to have the user enter their current password first
        presentTextFieldAlert(title: "Enter Current Password", message: "First enter your current password before you can change it", textFieldPlaceholder: nil) { [weak self] (currentPassword) in
            
            // Try to log the user in with the entered password, to confirm their identity
            Auth.auth().signIn(withEmail: currentUser.email, password: currentPassword) { (authResult, error) in
                if let error = error {
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                    return
                }
                
                // Present a new alert allowing the user to enter a new password
                self?.presentTextFieldAlert(title: "Enter New Password", message: "Choose a new password", textFieldPlaceholder: nil, completion: { (newPassword) in
                    
                    // Update the password in the cloud
                    Auth.auth().currentUser?.updatePassword(to: newPassword, completion: { (error) in
                        if let error = error {
                            // Print and display the error
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            self?.presentErrorAlert(error)
                        }
                    })
                })
            }
        }
    }
    
    @IBAction func addDietaryRestrictionButtonTapped(_ sender: UIButton) {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // If the options are not currently displayed, then display them
        if dietaryRestrictionsPickerView.isHidden {
            dietaryRestrictionsPickerView.isHidden = false
        }
            // Otherwise, add the selected option to the user's dietary restrictions and hide the picker view
        else {
            // Get the selected option and add it to the user's information
            let options = User.DietaryRestriction.allCases.filter({ !currentUser.dietaryRestrictions.contains($0) })
            let selectedRow = dietaryRestrictionsPickerView.selectedRow(inComponent: 0)
            let dietaryRestriction = options[selectedRow]
            currentUser.dietaryRestrictions.append(dietaryRestriction)
            
            // Save the changes to the user
            UserController.shared.saveChanges(to: currentUser) { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Update the tableview
                        self?.dietaryRestrictionsTableView.reloadData()
                        
                        // Hide the add button if necessary
                        if currentUser.dietaryRestrictions.count == User.DietaryRestriction.allCases.count {
                            self?.addRestrictionButton.isHidden = true
                        }
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
            
            // Hide the picker and refresh its data for next time its opened
            dietaryRestrictionsPickerView.isHidden = true
            dietaryRestrictionsPickerView.reloadAllComponents()
        }
    }
    
    @IBAction func signOutButtonTapped(_ sender: UIButton) {
        dietaryRestrictionsPickerView.isHidden = true
        do {
            // Sign the user out and return to the main screen
            try Auth.auth().signOut()
            transitionToStoryboard(named: .Main)
        } catch let error {
            // Print and display the error
            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            presentErrorAlert(error)
        }
    }
    
    @IBAction func deleteAccountButtonTapped(_ sender: UIButton) {
        dietaryRestrictionsPickerView.isHidden = true
        
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Present an alert to confirm deleting the account
        presentChoiceAlert(title: "Delete account?", message: "Are you sure you want to delete your account? This will permanently remove all your data from this device and from the cloud.") {
            
            // Show the loading icon
            self.view.activityStartAnimating()
            
            // If the user clicks confirm, delete their information from the cloud
            UserController.shared.deleteCurrentUser { [weak self] (result) in
                DispatchQueue.main.async {
                    // Hide the loading icon
                    self?.view.activityStopAnimating()
                    
                    switch result {
                    case .success(_):
                        // Delete the user's account from the authorization side of Firebase
                        let user = Auth.auth().currentUser
                        user?.delete(completion: { (error) in
                            if let error = error {
                                // Print and display the error
                                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                self?.presentErrorAlert(error)
                            } else {
                                // Return to the login screen
                                self?.transitionToStoryboard(named: .Main)
                            }
                        })
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
    }
}

// MARK: - TableView Methods

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserController.shared.currentUser?.dietaryRestrictions.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dietaryRestrictionCell", for: indexPath)
        
        guard let dietaryRestriction = UserController.shared.currentUser?.dietaryRestrictions[indexPath.row] else { return cell}
        cell.textLabel?.text = dietaryRestriction.formatted
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let currentUser = UserController.shared.currentUser else { return }
            
            // Make sure the user is connected to the internet
            guard Reachability.checkReachable() else {
                presentInternetAlert()
                return
            }
            
            // Remove the dietary restriction
            currentUser.dietaryRestrictions.remove(at: indexPath.row)
            
            // Save the changes to the user
            UserController.shared.saveChanges(to: currentUser) { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Enable the add button again and refresh the picker view
                        self?.addRestrictionButton.isHidden = false
                        self?.dietaryRestrictionsPickerView.reloadAllComponents()
                        
                        // Refresh the tableview
                        self?.dietaryRestrictionsTableView.reloadData()
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
    }
}

// MARK: - PickerView Methods

extension ProfileViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return User.DietaryRestriction.allCases.count - (UserController.shared.currentUser?.dietaryRestrictions.count ?? 0)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let currentUser = UserController.shared.currentUser else { return "ERROR" }
        let options = User.DietaryRestriction.allCases.filter({ !currentUser.dietaryRestrictions.contains($0) })
        return options[row].formatted
    }
}

// MARK: - Image Picker Delegate

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func openPhotoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true)
        } else {
            presentAlert(title: "Camera Access Not Available", message: "Please allow access to your camera to use this feature")
        }
    }
    
    func openCamera() {
          if UIImagePickerController.isSourceTypeAvailable(.camera) {
              imagePicker.sourceType = .camera
              present(imagePicker, animated: true)
          } else {
            presentAlert(title: "Photo Library Access Not Available", message: "Please allow access to your photo library to use this feature")
          }
      }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Get the photo
        guard let photo = info[.originalImage] as? UIImage else { return }
        
        // Close the image picker
        imagePicker.dismiss(animated: true)
        
        // Save the photo to the cloud
        profileImageView.activityStartAnimating()
        UserController.shared.savePhotoToCloud(photo) { [weak self] (result) in
            DispatchQueue.main.async {
                self?.profileImageView.activityStopAnimating()
                
                switch result {
                case .success(_):
                    // Update the UI
                    self?.profileImageView.image = photo
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
      
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePicker.dismiss(animated: true)
    }
}
