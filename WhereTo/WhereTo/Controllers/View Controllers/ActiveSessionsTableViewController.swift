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
    }

    // MARK: - TableView Methods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "votingSessionCell", for: indexPath)

        // Configure the cell...

        return cell
    }
}
