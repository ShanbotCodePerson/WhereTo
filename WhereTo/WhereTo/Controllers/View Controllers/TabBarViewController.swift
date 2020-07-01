//
//  TabBarViewController.swift
//  WhereTo
//
//  Created by Shannon Draeker on 7/1/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the default tab
        self.selectedIndex = 1
        
        // Set the colors
        setColors()
    }
    
    // MARK: - Set Up UI

    func setColors() {
        tabBar.barTintColor = .navBar
        tabBar.tintColor = .navBarButtonTint
        tabBar.unselectedItemTintColor = .tabBarUnselected
    }
}
