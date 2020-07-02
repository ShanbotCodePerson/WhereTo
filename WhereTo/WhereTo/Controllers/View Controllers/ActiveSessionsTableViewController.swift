//
//  ActiveSessionsTableViewController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/24/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class ActiveSessionsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Set up the observer to listen for notifications telling any view to display an alert
        setUpNotificationObservers()
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        // Hide the extra section markers at the bottom of the tableview
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .background
    }

    // MARK: - TableView Methods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return VotingSessionController.shared.votingSessions?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "votingSessionCell", for: indexPath)

        guard let votingSession = VotingSessionController.shared.votingSessions?[indexPath.row] else { return cell }
        lookUpAddressFromLocation(location: votingSession.location) { (locationDescription) in
            let city = locationDescription?.locality ?? ""
            cell.textLabel?.text = "Choose a place to eat with \(votingSession.participantNames)\(city.isEmpty ? "" : " near ")\(city)!"
        }
        cell.contentView.superview?.backgroundColor = .background

        return cell
    }
    
    // MARK: - Navigation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get the selected voting session
        guard let votingSession = VotingSessionController.shared.votingSessions?[indexPath.row] else { return}
        
        // Transition to the voting session view
        transitionToVotingSessionPage(with: votingSession)
    }
}
