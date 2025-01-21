//
//  SplashViewController.swift
//  2048_li
//
//  Created by 李利鑫 on 1/16/25.
//

import UIKit

class SplashViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        // 在这里放置你想要展示的图片
        let imageView = UIImageView(image: UIImage(named: "asdfa.png"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 600),
            imageView.heightAnchor.constraint(equalToConstant: 1000)
        ])
    }
}
