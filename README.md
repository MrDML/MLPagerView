# MLPagerView

[![CI Status](https://img.shields.io/travis/MrDML/MLPagerView.svg?style=flat)](https://travis-ci.org/MrDML/MLPagerView)
[![Version](https://img.shields.io/cocoapods/v/MLPagerView.svg?style=flat)](https://cocoapods.org/pods/MLPagerView)
[![License](https://img.shields.io/cocoapods/l/MLPagerView.svg?style=flat)](https://cocoapods.org/pods/MLPagerView)
[![Platform](https://img.shields.io/cocoapods/p/MLPagerView.svg?style=flat)](https://cocoapods.org/pods/MLPagerView)

## Preview
![Demo](https://github.com/MrDML/MLPagerView/blob/master/MLPageViewGif.gif)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

MLPagerView is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'MLPagerView' / pod 'MLPagerView', '~> 0.1.2'
```
##Use
```
//
//  ViewController.swift
//  MLPagerView
//
//  Created by MrDML on 05/28/2018.
//  Copyright (c) 2018 MrDML. All rights reserved.
//

import UIKit
import MLPagerView
class ViewController: UIViewController{
    
    
    @IBOutlet weak var pagerView: MLPagerView!
    
    let tableView:UITableView = UITableView()
    let webView:UIWebView = UIWebView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "MLPageView"
        self.pagerView.registerClass(pageclass: UIView.self, forPageReuseIdentifier: "pageView")
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.frame = CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        self.webView.loadRequest(URLRequest(url: URL.init(string: "http://www.baidu.com")!))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}


extension ViewController:MLPagerViewDelegate,MLPagerViewDatasource{
    
    func numberOfPagesInPagerView(pageview: MLPagerView) -> Int {
        return 10
    }
    
    func pagerView(pageView: MLPagerView, viewForPagerAtIndex index: Int) -> UIView? {
        
        if index < 2 {
            let obj =  [self.tableView,self.webView][index]
            print(obj)
            return obj
        }
        
        if let page = self.pagerView.dequeueReusablePagerWithIdentifier(identifier: "pageView") {
            let la = UILabel(frame: CGRect.init(x: 10, y: UIScreen.main.bounds.height * 0.5 - 30.0, width: UIScreen.main.bounds.width - 20 , height: 30))
            la.text = String(format: "当前第-%ld页", index+1)
            la.textAlignment = .center
            la.textColor = UIColor.orange
            la.font = UIFont.systemFont(ofSize: 25)
            page.addSubview(la)
            return page
        }else{
            return UIView.init(identifire: "pageView")
        }
    }
    
    
    func pagerView(pagerView: MLPagerView, willMovePage page: UIView, atIndex index: Int) {
        print("第\(index)页");
    }
    
}


extension ViewController:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 40
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "identifier")
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: "identifier")
        }
        
        
        cell?.textLabel?.text = String(format: "第%ld行", indexPath.row)
        return cell!
        
    }
    
}
```

## Author

MrDML, dml1630@163.com

## License

MLPagerView is available under the MIT license. See the LICENSE file for more info.
