//
//  FriendTableViewCell.swift
//  WhereTo
//
//  Created by Shannon Draeker on 6/23/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class FriendTableViewCell: UITableViewCell {

    // MARK: - Outlets
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    // MARK: - Properties
    
    var friend: User? { didSet { setUpViews() } }
    
    // MARK: - Set Up UI

    func setUpViews() {
        guard let friend = friend else { return }
        
        nameLabel.text = friend.name
    }
}
