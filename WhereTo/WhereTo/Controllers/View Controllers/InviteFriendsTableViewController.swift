//
//  InviteFriendsTableViewController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/23/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class InviteFriendsTableViewController: UITableViewController {
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Set Up UI
    
    
    // MARK: - Actions
    
    @IBAction func addFriendButtonTapped(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func pickRandomRestaurantButtonTapped(_ sender: UIButton) {
    }
    
    @IBAction func voteButtonTapped(_ sender: UIButton) {
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath)

        // Configure the cell...

        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            // TODO: - enable swipe to defriend
//            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
