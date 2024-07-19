//
//  TabBarController.swift
//  iconSearch
//
//  Created by Diana Tsarkova on 30.06.2024.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let firstViewController = UINavigationController(rootViewController: SearchViewController())
        let secondViewController = UINavigationController(rootViewController: FavoriteViewController())

        firstViewController.tabBarItem.title = .searchTitle
        firstViewController.tabBarItem.image = .search

        secondViewController.tabBarItem.title = .favTitle
        secondViewController.tabBarItem.image = .heart

        view.backgroundColor = .white
        tabBar.isTranslucent = false
        tabBar.barTintColor = .lightGray.withAlphaComponent(0.3)
        viewControllers = [firstViewController, secondViewController]
    }

}
