//
//  TabBarController.swift
//  iBeacon
//
//  Created by Kerry Lu on 2024/5/14.
//  使TabBar加上陰影

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBarUI()
    }
    
    func setupTabBarUI(){
        self.tabBar.backgroundColor = .white
        //self.tabBar.tintColor = .grayself.tabBar.layer.cornerRadius = 10
        //self.tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        //self.tabBar.clipsToBounds = true
        //self.tabBar.layer.masksToBounds = false
        //self.tabBar.layer.shadowColor = UIColor.black.cgColor
        self.tabBar.layer.shadowOpacity = 0.1
                 // 陰影要這樣畫，不然會太耗效能
        self.tabBar.layer.shadowPath = UIBezierPath(roundedRect: self.tabBar.bounds, cornerRadius: 0.0).cgPath
     }

}
