//
//  MLPagerView.swift
//  MLPageViewDemo_Swift
//
//  Created by 戴明亮 on 2018/5/27.
//  Copyright © 2018年 ML Dai. All rights reserved.
//

import UIKit

enum MLTransitionStyle {
    case MLTransitionStyleScro
    case MLTransitionStyleTab
}

@objc protocol MLPagerViewDelegate:class, UIScrollViewDelegate {
 
   @objc optional func pagerView(pagerView:MLPagerView,willDispalyPage page:UIView, atIndex index:Int)
    
   @objc optional func pagerView(pagerView:MLPagerView,willMovePage page:UIView, atIndex index:Int)
    
  @objc optional  func pagerView(pagerView:MLPagerView,didMovePage page:UIView, atIndex index:Int)
    
  @objc optional  func pagerView(pagerView:MLPagerView,didEndDispalyPage page:UIView, atIndex index:Int)
    
    
}

@objc protocol MLPagerViewDatasource:class {
    
    func numberOfPagesInPagerView(pageview:MLPagerView)-> Int
    
    func pagerView(pageView:MLPagerView,viewForPagerAtIndex index: Int)->UIView?
    
}

 class MLPagerViewDelegateForwarder: NSObject,UIScrollViewDelegate {
    
   weak var pagerView:MLPagerView!
   weak var delegate:MLPagerViewDelegate?

    override func forwardingTarget(for aSelector: Selector!) -> Any? {

        if let pagerView_ = pagerView,let delegate_ = delegate  {
            if (pagerView_.responds(to: aSelector)) {
                return pagerView
            }
            if (delegate_.responds(to: aSelector)){
                return delegate
            }
        }

        return super.forwardingTarget(for: aSelector)
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        
        if let pagerView_ = pagerView,let delegate_ = delegate  {
            if (pagerView_.responds(to: aSelector)){
                return true
            }
            if (delegate_.responds(to: aSelector)){
                return true
            }
        }

        return super.responds(to: aSelector);
    }
    
    
}

open class MLPagerView: UIScrollView,UIScrollViewDelegate,UIGestureRecognizerDelegate {
  private  var forwarder:MLPagerViewDelegateForwarder!
  private  var count: Int = 0
  private  var index: Int = 0
  private  var reuseQueue:[UIView]!
  private  var registration:NSMutableDictionary!
  private  var pages:[NSNumber: UIView]!
          var transitionStyle:MLTransitionStyle = MLTransitionStyle.MLTransitionStyleScro
    
   /// indexForSelectedPage
   public var indexForSelectedPage:Int{
        return self.index
    }
    
   /// selectPage
   public var selectPage:UIView?{
        let key = NSNumber.init(value: self.index)
        return self.pages[key]
    }

   /// loadedPages
   public var loadedPages:[UIView]?{
        let pages = self.pages.values
        return pages.reversed()
    }
    
    @IBOutlet override weak open var delegate: UIScrollViewDelegate?{
        set{
            super.delegate = nil
            forwarder.delegate = newValue as? MLPagerViewDelegate;
            super.delegate = forwarder
        }
        get{
            return forwarder.delegate
        }
    }
   @IBOutlet weak var dataSource: MLPagerViewDatasource?;
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
    
  private func initialize(){
        self.isPagingEnabled = true
        self.scrollsToTop = false
        self.isDirectionalLockEnabled = true
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        forwarder = MLPagerViewDelegateForwarder()
        forwarder.pagerView = self
        super.delegate = forwarder
        reuseQueue = NSMutableArray() as! [UIView]
        registration = NSMutableDictionary()
        pages = NSMutableDictionary() as! [NSNumber:UIView]
        
    }
    
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        if count <= 0{
            reloadPager()
        }
        
        var size = self.bounds.size
        size.width = self.bounds.size.width * CGFloat(count)
        if !size.equalTo(self.contentSize){
            
            self.contentSize = size;
            let x = self.bounds.size.width * CGFloat(self.index)
            super.setContentOffset(CGPoint.init(x: x, y: 0), animated: false)
            
            var frame = CGRect.zero
            frame.size = self.bounds.size;
            
            for key in self.pages.keys {
                let page = self.pages[key]
                frame.origin.x = self.bounds.size.width * CGFloat(key.intValue)
                page?.frame = frame

            }
        }
    }
    
    
   /// reloadPager
   public func reloadPager(){
        
        for key in self.pages.keys {
          let page = self.pages[key];
          page?.removeFromSuperview()
        }
        pages.removeAll();
        count = (self.dataSource?.numberOfPagesInPagerView(pageview: self))!
        if count > 0{
            index = min(index, count - 1);
            self.loadPagesAtIndex(index: index)
        }
        
    }
    
    
  private func loadPagesAtIndex(index:Int){
        
        let loadPage = { [weak self] (index:NSInteger) -> () in
            if let strongSelf = self {
                let key = NSNumber(value: index)
                let page = strongSelf.pages[key]
                if page == nil && index >= 0 && index < (strongSelf.count)  {
                    
                    let pageTemp = strongSelf.dataSource?.pagerView(pageView: strongSelf, viewForPagerAtIndex: index)
                    if let page = pageTemp {
                        var frame = CGRect.zero
                        frame.size = strongSelf.bounds.size
                        frame.origin = CGPoint.init(x: CGFloat(frame.size.width * CGFloat(index)), y: 0)
                        page.frame = frame;
                        
                        strongSelf.addSubview(page)
                        strongSelf.setNeedsLayout()

                        if (strongSelf.forwarder.delegate?.responds(to: #selector(MLPagerViewDelegate.pagerView(pagerView:willDispalyPage:atIndex:))))!{
                            let key = NSNumber.init(value: index)
                            strongSelf.forwarder.delegate?.pagerView!(pagerView: strongSelf, willDispalyPage: strongSelf.pages[key]!, atIndex: index)
                        }
                        
                        strongSelf.pages[key] = page;
                        
                    }else{
                        print("page can not nill")
                    }
 
                }
            }

        }
        
        loadPage(index)
        if transitionStyle == MLTransitionStyle.MLTransitionStyleScro {
            loadPage(index - 1)
            loadPage(index + 1)
        }

    }

   private func unLoadHiddenPages(){
        
        let removes = NSMutableArray()
        for key in self.pages.keys {
            
            let pageIndex = key.intValue
            if pageIndex != self.index{
                if self.transitionStyle == MLTransitionStyle.MLTransitionStyleTab || ((pageIndex != self.index - 1) && (pageIndex != self.index + 1) ){
                    
                    if let page = self.pages[key]{
                        page.removeFromSuperview()
                        removes.add(key)
                        
                        if (page.identifire != nil) {
                            self.reuseQueue.append(page)
                        }
                        
                        if (forwarder.delegate?.responds(to: #selector(MLPagerViewDelegate.pagerView(pagerView:didEndDispalyPage:atIndex:))))!{
                            let key = NSNumber.init(value: pageIndex)
                            
                            forwarder.delegate?.pagerView!(pagerView: self, didEndDispalyPage: self.pages[key]!, atIndex: pageIndex)
                        }
                    }
                }
                
            }

        }
        for key in removes {
            self.pages.removeValue(forKey: key as! NSNumber)
        }
        
    }
    // MARK: willMovePagerAtIndex
   private func willMovePagerAtIndex(index:Int){
        self.loadPagesAtIndex(index: index)
        if (forwarder.delegate?.responds(to: #selector(MLPagerViewDelegate.pagerView(pagerView:willMovePage:atIndex:))))! {
            let key = NSNumber.init(value: index)
            forwarder.delegate?.pagerView!(pagerView: self, willMovePage: self.pages[key]!, atIndex: index)
        }
    }

     // MARK: didMovePagerAtIndex
   private func didMovePagerAtIndex(index:Int){
         let key = NSNumber.init(value: index)
        if (forwarder.delegate?.responds(to: #selector(MLPagerViewDelegate.pagerView(pagerView:didEndDispalyPage:atIndex:))))!{
            
            forwarder.delegate?.pagerView!(pagerView: self, didEndDispalyPage: self.pages[key]!, atIndex: index)
        }
        self.unLoadHiddenPages()
    }
    
    
    
     /// show the  page according to the index
     ///
     /// - Parameters:
     ///   - index: index
     ///   - animation: false/true
     public func showPageAtIndex(index:Int,animated animation:Bool){
        if index >= 0 && index != self.index && index < self.count  {
            self.loadPagesAtIndex(index: index)
            
            let animatedTemp = (self.transitionStyle == MLTransitionStyle.MLTransitionStyleTab) ? false :animation
            
            let offset = CGPoint.init(x: self.bounds.size.width * CGFloat(index), y: 0)
            self.setContentOffset(offset, animated: animatedTemp)
            
        }
    }
    
    override open func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        
        if fmod(self.contentOffset.x, self.bounds.size.width) == 0{
            
            let pageIndex = Int( self.contentOffset.x / self.bounds.size.width)
            self.index = pageIndex
            self.willMovePagerAtIndex(index: pageIndex)
            super.setContentOffset(contentOffset, animated: animated)
            if animated == false {
                self.didMovePagerAtIndex(index: pageIndex)
            }
        }else{
            super.setContentOffset(contentOffset, animated: animated)
        }
        
    }
    
    
   /// regist UINib Style for pageView
   ///
   /// - Parameters:
   ///   - nib: nib
   ///   - identifer: identifer
   public func registerNib(nib:UINib, forPageReuseIdentifier identifer:String){
        self.registration.setValue(nib, forKey: identifer)
    
    }
    
    
   /// regist AnyClass Style for pageView
   ///
   /// - Parameters:
   ///   - pageclass: AnyClass
   ///   - identifer: identifer
   public func registerClass(pageclass:AnyClass,forPageReuseIdentifier identifer:String) {
        self.registration.setValue(NSStringFromClass(pageclass), forKey: identifer)
    }
    
    
   /// Get the pageView in the cache queue
   ///
   /// - Parameter identifier: identifier
   /// - Returns: PageView/nil
   public func dequeueReusablePagerWithIdentifier(identifier: String) -> UIView?{
        
        var page:UIView?
        for reuse in self.reuseQueue as [UIView] {
            if reuse.identifire == identifire{
                page = reuse
            }
        }
        if  page == nil {
          let builder = self.registration[identifier]
            
            if ((builder as? UINib) != nil) {
               let nib = builder as? UINib
                page = nib?.instantiate(withOwner: nib, options: [:]).first as? UIView
            }else if ((builder as? String) != nil){
                let string = builder as? String
                let cls = NSClassFromString(string!) as! UIView.Type
                 let viw = cls.init()
                page  = viw;
            }else{
                page = UIView()
            }
            guard let page_  = page else {return page}
            objc_setAssociatedObject(page_, identifireKey, identifier, objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)

        }
        
        return page
        
    }
    

    // MARK:UIScrollViewDelegate
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let pageIndex = Int(scrollView.contentOffset.x / self.bounds.size.width)
        self.index = pageIndex;
        if (forwarder.delegate?.responds(to: #selector(UIScrollViewDelegate.scrollViewDidEndDecelerating(_:))))! {
            forwarder.delegate?.scrollViewDidEndDecelerating!(scrollView)
        }
        self.didMovePagerAtIndex(index: pageIndex)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
         let pageIndex = Int(targetContentOffset.pointee.x / scrollView.bounds.size.width)
        self.willMovePagerAtIndex(index: pageIndex)
        
        if (forwarder.delegate?.responds(to: #selector(UIScrollViewDelegate.scrollViewWillEndDragging(_:withVelocity:targetContentOffset:))))!{
            forwarder.delegate?.scrollViewWillEndDragging!(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        }
        
    }
    
    public  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
        self.didMovePagerAtIndex(index: self.index)
        
        if (forwarder.delegate?.responds(to: #selector(UIScrollViewDelegate.scrollViewDidEndScrollingAnimation(_:))))!{
            forwarder.delegate?.scrollViewDidEndScrollingAnimation!(scrollView)
        }
        
        
    }
    // MARK: UIGestureRecognizerDelegate
    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer.isKind(of: UIPanGestureRecognizer.self){
            let gestureRecognizertemp = gestureRecognizer as! UIPanGestureRecognizer
         let point = gestureRecognizertemp.velocity(in: self)
            if fabs(point.x) < fabs(point.y) {
                return false
            }
        }
        return true
    }
    

}

private var identifireKey:String = "identifireKey"
extension UIView {
     var identifire:String?{
        get{
            return objc_getAssociatedObject(self, &identifireKey) as? String
        }
    }
    convenience init(identifire:String) {
        self.init()
        objc_setAssociatedObject(self, identifireKey, identifire, objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)
    }
    
    convenience init(frame:CGRect,withIdentifire identifire:String) {
        self.init()
        objc_setAssociatedObject(self, identifireKey, identifire, objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)
    }
   
}





