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
        self.tableView.tableFooterView = UIView()
    }

    // MARK: - TableView Methods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return VotingSessionController.shared.votingSessions?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "votingSessionCell", for: indexPath)

        guard let votingSession = VotingSessionController.shared.votingSessions?[indexPath.row] else { return cell }
        cell.textLabel?.text = "Choose a place to eat with \(votingSession.users)" // TODO: - format better, just names of users, better location name
        cell.detailTextLabel?.text = "Currently waiting for ..." // TODO: - fill this part out better

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
