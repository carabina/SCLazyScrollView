//
//  ViewController.swift
//  SCScrollViewExample
//
//  Created by SeanChoi on 2017. 1. 10..
//  Copyright © 2017년 SeanChoi. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SCLazyScrollViewDelegate, SCLazyScrollViewDataSource {

    var subViewControllers : Array<Any> = []
    var lazySCrollView : SCLazyScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        for _ in 0..<5 {
            subViewControllers.append(NSNull())
        }
        
        lazySCrollView = SCLazyScrollView(frame: self.view.bounds, direction: .horizontal, circularScroll: false)
        lazySCrollView.controlDelegate = self
        lazySCrollView.controlDatasource = self
        lazySCrollView.numberOfPages = subViewControllers.count
        self.view.addSubview(lazySCrollView)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: SCLazyScrollViewDelegate
    func lazyScrollView(pageingView: SCLazyScrollView, changed currenPageIndex: Int) {
        print(currenPageIndex)
    }
    
    //MARK: SCLazyScrollViewDataSource
    func viewControllerOfSCLazyScrollViewAt(index: Int) -> UIViewController? {
        
        guard let controller = subViewControllers[index] as? UIViewController else {
            
            let viewController = UIViewController()
            viewController.view.backgroundColor = generateRandomColor()
            
            let label = UILabel(frame: viewController.view.bounds)
            label.textColor = UIColor.white
            label.text = "\(index)"
            label.textAlignment = .center
            label.font = UIFont.boldSystemFont(ofSize: 30)
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            viewController.view.addSubview(label)
            
            subViewControllers[index] = viewController
            return viewController
        }
        
        return controller
    }

    func generateRandomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    //MARK: Rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.lazySCrollView.reloadDataCurrentPage()
        }
    }
}



