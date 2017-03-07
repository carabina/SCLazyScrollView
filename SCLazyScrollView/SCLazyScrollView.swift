//
//  SCLazyScrollView.swift
//  SCLazyScrollView
//
//  Created by SeanChoi on 2017. 1. 11..
//  Copyright © 2017년 SeanChoi. All rights reserved.
//

import UIKit

enum SCLazyScrollViewDirection {
    case horizontal
    case vertical
}

protocol SCLazyScrollViewDelegate {
    func lazyScrollViewWillBeginDragging(pageingView:SCLazyScrollView)
    func lazyScrollViewDidScroll(pageingView:SCLazyScrollView, at visibleOffset:CGPoint, with selfDrivenAnimation:Bool)
    func lazyScrollViewDidEndDragging(pageingView:SCLazyScrollView)
    func lazyScrollViewWillBeginDecelerating(pageingView:SCLazyScrollView)
    func lazyScrollViewDidEndDecelerating(pageingView:SCLazyScrollView, at pageIndex:Int)
    func lazyScrollView(pageingView:SCLazyScrollView, changed currenPageIndex:Int)
}

extension SCLazyScrollViewDelegate {
    func lazyScrollViewWillBeginDragging(pageingView:SCLazyScrollView) {}
    func lazyScrollViewDidScroll(pageingView:SCLazyScrollView, at visibleOffset:CGPoint, with selfDrivenAnimation:Bool) {}
    func lazyScrollViewDidEndDragging(pageingView:SCLazyScrollView) {}
    func lazyScrollViewWillBeginDecelerating(pageingView:SCLazyScrollView) {}
    func lazyScrollViewDidEndDecelerating(pageingView:SCLazyScrollView, at pageIndex:Int) {}
    func lazyScrollView(pageingView:SCLazyScrollView, changed currenPageIndex:Int) {}
}

protocol SCLazyScrollViewDataSource {
    func viewControllerOfSCLazyScrollViewAt(index: Int) -> UIViewController?
}

class SCLazyScrollView: UIScrollView {
    
    enum SCLazyScrollViewScrollDirection {
        case backward
        case forward
    }
    
    enum SCLazyScrollViewTransition {
        case auto
        case forward
        case backward
    }

    var controlDelegate: SCLazyScrollViewDelegate?
    var controlDatasource: SCLazyScrollViewDataSource?
    
    var numberOfPages : Int = 0 {
        didSet {
            reloadData()
        }
    }
    
    fileprivate(set) public var currentPage : Int = NSNotFound
    fileprivate(set) public var direction : SCLazyScrollViewDirection = .horizontal
    
    var circularScrollEnabled = false
    fileprivate var isManualAnimating = false
    
    fileprivate var visibleRect : CGRect {
        return CGRect(origin: self.contentOffset, size: self.contentSize)
    }
    
    //MARK: Init
    init(frame: CGRect,
         direction scrollDirection: SCLazyScrollViewDirection,
         circularScroll circular: Bool) {
        
        super.init(frame: frame)
        direction = scrollDirection
        circularScrollEnabled = circular
        
        initializeControl()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initializeControl()
    }
    
    func initializeControl() {
        
        self.autoresizesSubviews = true
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.isPagingEnabled = true
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.delegate = self
        self.contentSize = CGSize(width: self.frame.size.width, height: self.contentSize.height)
        
        currentPage = NSNotFound
    }
    
    //MARK:
    fileprivate func hasMultiplePages() -> Bool {
        return numberOfPages > 1
    }
    
    fileprivate func createPoint(size: CGFloat) -> CGPoint {
        if direction == .horizontal {
            return CGPoint(x: size, y: 0)
        } else {
            return CGPoint(x: 0, y: size)
        }
    }
    
    func pageIndexByAdding(offset: Int, index: Int) -> Int {
        var offsetVar = offset
        while offsetVar < 0 {
            offsetVar += numberOfPages
        }
        
        return (numberOfPages + index + offsetVar) % numberOfPages
    }
    
    //MARK: Auto Play
    var autoPlay = false {
        didSet {
            if numberOfPages > 0 {
                reloadData()
            }
        }
    }
    
    var autoPlayTime : TimeInterval = 3.0
    private var autoPlayTimer : Timer?
    
    //MARK: Auto Play Extension
    private func resetAutoPlay() {
        
        if let timer = autoPlayTimer {
            timer.invalidate()
        }
        autoPlayTimer = nil
        
        if autoPlay {
            autoPlayTimer = Timer.scheduledTimer(timeInterval: autoPlayTime,
                                                 target: self,
                                                 selector: #selector(updateTimer),
                                                 userInfo: nil,
                                                 repeats: true)
        }
        
    }
    
    @objc private func updateTimer() {
        if hasMultiplePages() {
            autoPlayGoToNextPage()
        }
    }
    
    private func autoPlayGoToNextPage() {
        
        var nextPage = currentPage + 1
        if nextPage >= numberOfPages {
            nextPage = 0
        }
        
        setPage(newIndex: nextPage, animated: true)
    }
    
    fileprivate func autoPlayPause() {
        
        if let timer = autoPlayTimer {
            timer.invalidate()
        }
        autoPlayTimer = nil
    }
    
    fileprivate func autoPlayResume() {
        resetAutoPlay()
    }
    
    //MARK: Data
    func reloadData() {
        reloadDataPage(at: 0)
    }
    
    func reloadDataCurrentPage() {
        reloadDataPage(at: currentPage)
    }
    
    func reloadDataPage(at index:Int) {
        currentPage = NSNotFound
        
        let offset = CGFloat(hasMultiplePages() ? numberOfPages + 2 : 1)
        if direction == .horizontal {
            self.contentSize = CGSize(width: self.frame.size.width * offset, height: self.contentSize.height)
        } else {
            self.contentSize = CGSize(width: self.frame.size.width, height: self.contentSize.height * offset)
        }
        
        setCurrentViewController(index: index)
        resetAutoPlay()
        
    }
    
    //MARK: Page
    fileprivate func setCurrentViewController(index: Int) {
        
        if index == currentPage {
            return
        }
        
        currentPage = index
        if currentPage < 0 {
            currentPage = 0
        } else if currentPage > numberOfPages {
            currentPage = numberOfPages
        }
        
        self.subviews.forEach { $0.removeFromSuperview() }
        
        let prevPage = pageIndexByAdding(offset: -1, index: currentPage)
        let nextPage = pageIndexByAdding(offset: 1, index: currentPage)
        
        loadControllerAt(index: currentPage, placeAt: 0)
        if hasMultiplePages() {
            loadControllerAt(index: prevPage, placeAt: -1)
            loadControllerAt(index: nextPage, placeAt: 1)
        }
        
        let size = (direction == .horizontal) ? self.frame.size.width : self.frame.size.height
        self.contentOffset = createPoint(size: size * (hasMultiplePages() ? 2 : 0))
        
        controlDelegate?.lazyScrollView(pageingView: self, changed: currentPage)
    }
    
    func visiableViewController() -> UIViewController? {
        
        let rect = CGRect(origin: visibleRect.origin, size: visibleRect.size)
        let firstVisibleView = self.subviews.filter{ rect.intersects($0.frame) }.first
        
        guard let visibleView = firstVisibleView else {
            return nil
        }
        
        return viewControllerFromView(targetView: visibleView)
    }
    
    private func viewControllerFromView(targetView: UIView) -> UIViewController? {
        return targetView.traverseResponderChainForUIViewController()
    }
    
    func moveByPages(offset: Int, animated:Bool) {
        let finalIndex = pageIndexByAdding(offset: offset, index: currentPage)
        let transition : SCLazyScrollViewTransition = offset >= 0 ? .forward : .backward
        
        setPage(newIndex: finalIndex, transition: transition, animated: animated)
        
    }
    
    func setPage(newIndex: Int, animated:Bool) {
        setPage(newIndex: newIndex, transition: .forward, animated: animated)
    }
    
    func setPage(newIndex: Int, transition: SCLazyScrollViewTransition, animated:Bool) {
        if newIndex == currentPage {
            return
        }
        
        if animated {
            var finalOffset = CGPoint.zero
            
            var varTransition = transition
            if varTransition == .auto {
                if newIndex > currentPage {
                    varTransition = .forward
                } else if newIndex < currentPage {
                    varTransition = .backward
                }
            }
            
            let size = (direction == .horizontal) ? self.frame.size.width : self.frame.size.height
            
            if varTransition == .forward {
                loadControllerAt(index: newIndex, placeAt: 1)
                finalOffset = createPoint(size: size * 3)
            } else {
                loadControllerAt(index: newIndex, placeAt: -1)
                finalOffset = createPoint(size: size * 1)
            }
            
            isManualAnimating = true
            
            UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseInOut, animations: {
                self.contentOffset = finalOffset
            }, completion: { [weak self]  finish in
                if finish {
                    self?.setCurrentViewController(index: newIndex)
                    self?.isManualAnimating = false
                }
            })
        } else {
            setCurrentViewController(index: newIndex)
        }
        
    }
    
    private func setCurrentPage(newCurrentPage: Int) {
        setCurrentViewController(index: newCurrentPage)
    }
    
    fileprivate func loadControllerAt(index: Int, placeAt destIndex: Int) {
        if let viewController = controlDatasource?.viewControllerOfSCLazyScrollViewAt(index: index) {
            viewController.view.tag = 0
            
            var viewFrame = self.bounds
            let offset = hasMultiplePages() ? 2 : 0
            if direction == .horizontal {
                viewFrame = CGRect(origin: CGPoint(x: self.frame.size.width * CGFloat(destIndex + offset), y: 0) , size: viewFrame.size)
            } else {
                viewFrame = CGRect(origin: CGPoint(x: 0, y: self.frame.size.height * CGFloat(destIndex + offset)) , size: viewFrame.size)
            }
            
            print(viewFrame)
            viewController.view.frame = viewFrame
            self.addSubview(viewController.view)
        }
    }
    
}

extension SCLazyScrollView : UIScrollViewDelegate {
    
    //MARK: ScrollView Delegate
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.bounces = true
        controlDelegate?.lazyScrollViewDidEndDragging(pageingView: self)
        autoPlayResume()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        autoPlayPause()
        controlDelegate?.lazyScrollViewWillBeginDecelerating(pageingView: self)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isManualAnimating {
            controlDelegate?.lazyScrollViewDidScroll(pageingView: self, at: visibleRect.origin, with: true)
            return
        }
        
        let offset = (direction == .horizontal) ? scrollView.contentOffset.x : scrollView.contentOffset.y
        let size = (direction == .horizontal) ? self.frame.size.width : self.frame.size.height
        
        let proposedScroll : SCLazyScrollViewScrollDirection = (offset <= size * 2) ? .backward : .forward
        
        let canScrollBackward = circularScrollEnabled || (!circularScrollEnabled && currentPage != 0)
        let canSCrollForward = circularScrollEnabled || (!circularScrollEnabled && currentPage < numberOfPages - 1)
        
        let prevPage = pageIndexByAdding(offset: -1, index: currentPage)
        let nextPage = pageIndexByAdding(offset: 1, index: currentPage)
        if prevPage == nextPage {
            loadControllerAt(index: prevPage, placeAt: (proposedScroll == .backward) ? -1 : 1)
        }
        
        if (proposedScroll == .backward && !canScrollBackward) || (proposedScroll == .forward && !canSCrollForward) {
            self.bounces = false
            scrollView.setContentOffset(createPoint(size: size * 2), animated: false)
            return
        } else {
            self.bounces = true
        }
        
        var newPageIndex = currentPage
        if offset <= size {
            newPageIndex = pageIndexByAdding(offset: -1, index: currentPage)
        } else if offset >= size * 3 {
            newPageIndex = pageIndexByAdding(offset: 1, index: currentPage)
        }
        
        setCurrentViewController(index: newPageIndex)
        
        controlDelegate?.lazyScrollViewDidScroll(pageingView: self, at: visibleRect.origin, with: false)
        
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        controlDelegate?.lazyScrollViewWillBeginDecelerating(pageingView: self)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        controlDelegate?.lazyScrollViewDidEndDecelerating(pageingView: self, at: currentPage)
    }
}

extension UIView {
    
    func traverseResponderChainForUIViewController() -> UIViewController? {
        if let nextRes = self.next {
            if nextRes is UIViewController {
                let nextViewController = nextRes as! UIViewController
                return nextViewController
            } else if nextRes is UIView {
                let nextView = nextRes as! UIView
                return nextView.traverseResponderChainForUIViewController()
            }
        }
        
        return nil
    }
}
