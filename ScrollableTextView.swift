//
//  ScrollableTextView.swift
//  Vinyl Recorder
//
//  Created by Ramon Haro Marques on 29/01/2018.
//  Copyright © 2018 Convert Technologies. All rights reserved.
//

import UIKit
import QuartzCore

enum AutoScrollDirection {
    case rigth
    case left
}

class ScrollableTextView: UIView, UIScrollViewDelegate {

    //MARK: - Variables
    //MARK: Constants
    let kLabelCount:Int = 2
    let kDefaultFadeLength:CGFloat = 7.0
    let kDefaultPixelsPerSecond:CGFloat = 30
    let kDefaultPauseTime:CGFloat = 1.5
    let kDefaultLabelBufferSpace:CGFloat = 20
    
    
    //MARK: Vars
    var labels = [UILabel]()
    
    
    lazy var scrollView:UIScrollView = {
       
        let aScrollView = UIScrollView(frame: self.bounds)
        aScrollView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        
        self.addSubview(aScrollView)
        
        return aScrollView
    }()
    var isScrolling = false
    
    
    
    var mainLabel:UILabel{
        get{
            if labels.count>0{
                return labels[0]
            }
            else{
                return UILabel()
            }
        }
    }
    
    var text:String{
        set(value){
            if value != text{
                for label in labels{
                    label.text = value
                }
                refreshLabels()
            }
        }
        get{
            return mainLabel.text ?? ""
        }
    }
    
    var attributedText:NSAttributedString{
        set(value){
            if value.string != attributedText.string{
                for label in labels{
                    label.attributedText = value
                }
            }
            refreshLabels()
        }
        get{
            return mainLabel.attributedText ?? NSAttributedString()
        }
    }
    
    var textColor:UIColor{
        set(value){
            for label in labels{
                label.textColor = value
            }
        }
        get{
            return mainLabel.textColor
        }
    }
    
    var font:UIFont{
        set(value){
            if value != font{
                for label in labels{
                    label.font = value
                }
            }
            refreshLabels()
            self.invalidateIntrinsicContentSize()
        }
        get{
            return mainLabel.font
        }
    }
    
    var shadowColor:UIColor{
        set(value){
            for label in labels{
                label.shadowColor = value
            }
        }
        get{
            return mainLabel.shadowColor ?? .black
        }
    }
    
    var shadowOffset:CGSize{
        set(value){
            for label in labels{
                label.shadowOffset = value
            }
        }
        get{
            return mainLabel.shadowOffset
        }
    }
    
    
    
    var scrollSpeed:CGFloat = 0{
        didSet{
            scrollLabelIfNeeded()
        }
    }
    
    var scrollDirection = AutoScrollDirection.rigth{
        didSet{
            scrollLabelIfNeeded()
        }
    }
    
    var fadeLength:CGFloat = 0{
        didSet{
            refreshLabels()
        }
    }
    
    var pauseInterval = TimeInterval()
    var labelSpacing:CGFloat = 0
    var textAligment = NSTextAlignment.left
    var animationOption = UIViewAnimationOptions.curveLinear
    
    
    
    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        print("helloooooooooooooooooooo init")
        commonInit()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    
        print("helloooooooooooooooooooo coder")
        commonInit()
        
    }
    
    func dealloc(){
        
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        NotificationCenter.default.removeObserver(self)
    
    }
    
    func commonInit(){
        
        for _ in 0..<kLabelCount{
            
            let label = UILabel()
            label.backgroundColor = .clear
            label.autoresizingMask = self.autoresizingMask
            
            scrollView.addSubview(label)
            labels.append(label)
            
        }
        
        scrollDirection = .left
        scrollSpeed = kDefaultPixelsPerSecond
        
        pauseInterval = TimeInterval(kDefaultPauseTime)
        labelSpacing = kDefaultLabelBufferSpace
        fadeLength = kDefaultFadeLength
        textAligment = NSTextAlignment.left
        animationOption = UIViewAnimationOptions.curveLinear
        
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isScrollEnabled = false
        scrollView.isUserInteractionEnabled = false
        
        self.backgroundColor = .clear
        self.clipsToBounds = true
        
    }
    
    
    
    //MARK: - Lifecycle Methods
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if self.window != nil{
            scrollLabelIfNeeded()
        }
        
    }
    
    override var bounds: CGRect{
        didSet{
            super.bounds = bounds
            didChangeFrame()
        }
    }
    
    override var frame: CGRect{
        didSet{
            super.frame = frame
            didChangeFrame()
        }
    }
    
    
    
    //MARK: - AutoLayout
    override var intrinsicContentSize: CGSize{
        get{
            return CGSize.init(width: 0, height: mainLabel.intrinsicContentSize.height)
        }
    }
    
    
    
    //MARK: - MISC
    func observeApplicationNotifications(){
        
        NotificationCenter.default.removeObserver(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(scrollLabelIfNeeded), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(scrollLabelIfNeeded), name: NSNotification.Name.UIApplicationDidBecomeActive, object: self)
        
    }
    
    @objc func enableShadow(){
        
        isScrolling = true
        applyGradientMaskForFadeLength(fadeLength: fadeLength, enableFade: true)
        
    }
    
    @objc func scrollLabelIfNeeded(){
        
        if text.count > 0{
            
            let labelWidth = mainLabel.bounds.width
            
            if labelWidth > self.bounds.width{
                
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(scrollLabelIfNeeded), object: nil)
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(enableShadow), object: nil)
                
                let doScrollLeft = scrollDirection == .left
                scrollView.layer.removeAllAnimations()
                scrollView.contentOffset = doScrollLeft ? CGPoint.zero : CGPoint(x: labelWidth + labelSpacing, y: 0)
            
                perform(#selector(enableShadow), with: nil, afterDelay: pauseInterval)
                
                let duration:TimeInterval = TimeInterval(labelWidth/scrollSpeed)
                UIView.animate(withDuration: duration, delay: pauseInterval, options: [animationOption, .allowUserInteraction], animations: {
                    
                    self.scrollView.contentOffset = doScrollLeft ? CGPoint.init(x: labelWidth + self.labelSpacing, y: 0): CGPoint.zero
                
                }, completion: { (finished) in
                    
                    self.isScrolling = false
                    self.applyGradientMaskForFadeLength(fadeLength: self.fadeLength, enableFade: false)
                    if finished{
                        self.perform(#selector(self.scrollLabelIfNeeded), with: nil)
                    }
                    
                })
                
            }
            
        }
        
    }
    
    func refreshLabels(){
        
        var offset:CGFloat = 0
        
        for label in labels{
            
            label.sizeToFit()
            
            var frame = label.frame
            frame.origin = CGPoint(x: offset, y: 0)
            frame.size.height = self.bounds.height
            label.frame = frame
            
            label.center = CGPoint(x: label.center.x, y: CGFloat(roundf(Float(self.center.y - self.frame.minY))))
            
            offset += label.bounds.width + labelSpacing
            
        }
        
        scrollView.contentOffset = CGPoint.zero
        scrollView.layer.removeAllAnimations()
        
        if mainLabel.bounds.width > self.bounds.width{
            
            let newWidth = mainLabel.bounds.width + self.bounds.width + labelSpacing
            let newHeigth = self.bounds.height
            
            scrollView.contentSize = CGSize(width: newWidth, height: newHeigth)
            
            for label in labels{
                label.isHidden = false
            }
            
            applyGradientMaskForFadeLength(fadeLength: fadeLength, enableFade: isScrolling)
            scrollLabelIfNeeded()
            
        }
        else{
            
            for label in labels{
                label.isHidden = mainLabel != label
            }
            
            scrollView.contentSize = self.bounds.size
            mainLabel.frame = self.bounds
            mainLabel.isHidden = false
            mainLabel.textAlignment = textAligment
            
            scrollView.layer.removeAllAnimations()
            applyGradientMaskForFadeLength(fadeLength: 0, enableFade: false)
            
        }
        
    }
    
    func didChangeFrame(){
        refreshLabels()
        applyGradientMaskForFadeLength(fadeLength: fadeLength, enableFade: isScrolling)
    }
    
    
    func applyGradientMaskForFadeLength(fadeLength:CGFloat, enableFade fade:Bool){
        
        let labelWidth = mainLabel.bounds.width
        
        if labelWidth > self.bounds.width{
           
            let gradientMask = CAGradientLayer.init(layer: layer)
            
            gradientMask.bounds = self.layer.bounds
            gradientMask.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            
            gradientMask.shouldRasterize = true
            gradientMask.rasterizationScale = UIScreen.main.scale
            
            gradientMask.startPoint = CGPoint(x: 0, y: self.frame.midY)
            gradientMask.endPoint = CGPoint(x: 1, y: self.frame.midY)
            
            gradientMask.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
            
            let fadePoint:CGFloat = fadeLength / self.bounds.width
            var leftFadePoint:NSNumber = NSNumber.init(value: Float(fadePoint))
            var rightFadePoint:NSNumber = NSNumber.init(value: Float(1 - fadePoint))
            
            if !fade{
                switch scrollDirection{
                case .left:
                    leftFadePoint = 0
                case .rigth:
                    leftFadePoint = 0
                    rightFadePoint = 1
                }
            }
            
            gradientMask.locations = [0, leftFadePoint, rightFadePoint, 1]
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            self.layer.mask = gradientMask
            
            CATransaction.commit()
            
        }
        else{
            self.layer.mask = nil
        }
        
        
        
    }
    
}
