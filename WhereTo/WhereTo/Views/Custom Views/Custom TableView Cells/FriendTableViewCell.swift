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
    
    @IBOutlet weak var containerView: TableViewCellBackground!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    // MARK: - Properties
    
    var friend: User? { didSet { setUpViews() } }
    
    // MARK: - Set Up UI

    func setUpViews() {
        // If the friend is nil, then display a notice to the user that they haven't added any friends
        guard let friend = friend else {
            isUserInteractionEnabled = false
            profileImageView.isHidden = true
            nameLabel.textAlignment = .center
            nameLabel.text = "You have not yet added any friends - click the plus button in the top corner to add a friend"
            return
        }
        
        // Otherwise, fill in the details of the friend
        isUserInteractionEnabled = true
        profileImageView.isHidden = false
        nameLabel.textAlignment = .left
        profileImageView.image = friend.photo ?? #imageLiteral(resourceName: "default_profile_picture")
        nameLabel.text = friend.name
    }
    
    // MARK: - Selected State
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selectionStyle = .none
        
        // Change the colors when the cell is selected
        if selected { containerView.backgroundColor = UIColor.cellBackgroundSelected.withAlphaComponent(0.8) }
        else { containerView.backgroundColor = UIColor.cellBackground.withAlphaComponent(0.8) }
    }
}
