//
//  AlertService.swift
//  WhereTo
//
//  Created by Bryce Bradshaw on 7/6/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class AlertService {
    
    func alert(_ restaurant: Restaurant, message: String) -> SelectedRestaurantAlertViewController {
        
        let storyboard = UIStoryboard(name: "SelectedRestaurantAlert", bundle: .main)
        
        let alertVC = storyboard.instantiateViewController(withIdentifier: "alertVC") as! SelectedRestaurantAlertViewController
        alertVC.restaurant = restaurant
        alertVC.message = message
        
        alertVC.modalPresentationStyle = .overFullScreen
        alertVC.modalTransitionStyle = .crossDissolve
        
        return alertVC
    }
}
