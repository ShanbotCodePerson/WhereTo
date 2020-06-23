//
//  ProfileViewController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/23/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var showPasswordButton: UIButton!
    @IBOutlet weak var dietaryRestrictionsTableView: UITableView!
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // MARK: - Set Up UI
    
    
    // MARK: - Actions

    @IBAction func editProfileImageButtonTapped(_ sender: UIButton) {
    }
    
    @IBAction func editNameButtonTapped(_ sender: UIButton) {
    }
    
    @IBAction func showPasswordButtonTapped(_ sender: UIButton) {
    }
    
    @IBAction func addDietaryRestrictionButtonTapped(_ sender: UIButton) {
    }
}
