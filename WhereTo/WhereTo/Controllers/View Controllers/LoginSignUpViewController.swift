//
//  LoginSignUpViewController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit
import Firebase

class LoginSignUpViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Try to log the user in automatically
        autoLogin()
    }
    
    // MARK: - Actions

    @IBAction func loginSignUpButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty else {
            presentAlert(title: "Invalid Email", message: "Email cannot be blank")
            return
        }
        guard let password = passwordTextField.text, !password.isEmpty else {
            presentAlert(title: "Invalid Password", message: "Password cannot be blank")
            return
        }
        
        // TODO: - display loading icon
        
        // Try to create a new user
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard authResult?.user != nil, error == nil else {
                // If the error is that the user name already exists, try to log in to that account
                if let nsError = error as NSError?, nsError.code == 17007 {
                    // TODO: - refactor this to separate method
                    Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
                        if let error = error {
                            // Print and display the error
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            DispatchQueue.main.async { self?.presentErrorAlert(error) }
                            return
                        }
                        
                        // Fetch the details of the current user
                        UserController.shared.fetchCurrentUser { (result) in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(_):
                                    // Navigate to the main screen of the app
                                    print("it worked")
                                    self?.goToMainApp()
                                case .failure(let error):
                                    // Print and display the error
                                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                    self?.presentErrorAlert(error)
                                }
                            }
                        }
                    }
                }
                else {
                    // Print and display the error
                    print("Error in \(#function) : \(error!.localizedDescription) \n---\n \(error!)")
                    DispatchQueue.main.async { self?.presentErrorAlert(error!) }
                }
                return
            }
            
            // Save the user
            UserController.shared.newUser(with: email) { (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Navigate to the main screen of the app
                        print("it worked")
                        self?.goToMainApp()
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Try to log the user in automatically
    func autoLogin() {
        if Auth.auth().currentUser != nil {
            UserController.shared.fetchCurrentUser { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        self?.goToMainApp()
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    }
                }
            }
        }
    }
    
    // Go to the main app screen
    func goToMainApp() {
        let storyboard = UIStoryboard(name: "WhereTo", bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController() else { return }
        initialVC.modalPresentationStyle = .fullScreen
        
        // Make the transition look like navigating forward through a navigation controller
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = .push
        transition.subtype = .fromRight
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.window?.layer.add(transition, forKey: kCATransition)
        
        self.present(initialVC, animated: false)
    }
}
