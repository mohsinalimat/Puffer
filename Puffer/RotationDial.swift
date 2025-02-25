//
//  AngleDashboard.swift
//  Puffer
//
//  Created by Echo on 10/21/18.
//  Copyright © 2018 Echo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

@IBDesignable
public class RotationDial: UIView {
    @IBInspectable public var pointerHeight: CGFloat = 8
    @IBInspectable public var spanBetweenDialPlateAndPointer: CGFloat = 6
    @IBInspectable public var pointerWidth: CGFloat = 8 * sqrt(2)
    
    public var didRotate: (_ angle: CGAngle) -> Void = { _ in }
    public var config = Config()
    
    private var angleLimit = CGAngle(radians: CGFloat.pi)
    private var showRadiansLimit: CGFloat = CGFloat.pi
    private var dialPlate: RotationDialPlate?
    private var dialPlateHolder: UIView?
    private var pointer: CAShapeLayer = CAShapeLayer()
    private var rotationKVO: NSKeyValueObservation?

    var viewModel = RotationDialViewModel()
    
    /**
     This one is needed to solve storyboard render problem
     https://stackoverflow.com/a/42678873/288724
     */
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public init(frame: CGRect, config: Config) {
        super.init(frame: frame)
        setup(with: config)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

// MARK: - private funtions
extension RotationDial {
    private func setupUI() {
        clipsToBounds = true
        backgroundColor = config.backgroundColor
        
        dialPlateHolder?.removeFromSuperview()
        dialPlateHolder = getDialPlateHolder(by: config.orientation)
        addSubview(dialPlateHolder!)
        createDialPlate(in: dialPlateHolder!)
        setupPointer(in: dialPlateHolder!)
        setDialPlateHolder(by: config.orientation)
    }
    
    private func setupViewModel() {
        rotationKVO = viewModel.observe(\.rotationAngle,
                                        options: [.old, .new]
        ) { [weak self] _, changed in
            guard let angle = changed.newValue else { return }
            self?.handleRotation(by: angle)
        }
        
        let rotationCenter = getRotationCenter()
        viewModel.makeRotationCalculator(by: rotationCenter)
    }
    
    private func handleRotation(by angle: CGAngle) {
        if case .limit = config.rotationLimitType {
            guard angle <= angleLimit else {
                return
            }
        }
        
        if rotateDialPlate(by: angle) {
            didRotate(getRotationAngle())
        }
    }
    
    private func getDialPlateHolder(by orientation: Config.Orientation) -> UIView {
        let view = UIView(frame: bounds)
        
        switch orientation {
        case .normal, .upsideDown:
            ()
        case .left, .right:
            view.frame.size = CGSize(width: view.bounds.height, height: view.bounds.width)
        }
        
        return view
    }
    
    private func setDialPlateHolder(by orientation: Config.Orientation) {
        switch orientation {
        case .normal:
            ()
        case .left:
            dialPlateHolder?.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
            dialPlateHolder?.frame.origin = CGPoint(x: 0, y: 0)
        case .right:
            dialPlateHolder?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            dialPlateHolder?.frame.origin = CGPoint(x: 0, y: 0)
        case .upsideDown:
            dialPlateHolder?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            dialPlateHolder?.frame.origin = CGPoint(x: 0, y: 0)
        }
    }
    
    private func createDialPlate(in container: UIView) {
        var margin: CGFloat = CGFloat(config.margin)
        if case .limit(let angle) = config.angleShowLimitType {
            margin = 0
            showRadiansLimit = angle.radians
        } else {
            showRadiansLimit = CGFloat.pi
        }
        
        var dialPlateShowHeight = container.frame.height - margin - pointerHeight - spanBetweenDialPlateAndPointer
        var r = dialPlateShowHeight / (1 - cos(showRadiansLimit))
        
        if r * 2 * sin(showRadiansLimit) > container.frame.width {
            r = (container.frame.width / 2) / sin(showRadiansLimit)
            dialPlateShowHeight = r - r * cos(showRadiansLimit)
        }
        
        let dialPlateLength = 2 * r
        let dialPlateFrame = CGRect(x: (container.frame.width - dialPlateLength) / 2, y: margin - (dialPlateLength - dialPlateShowHeight), width: dialPlateLength, height: dialPlateLength)
        
        dialPlate?.removeFromSuperview()
        dialPlate = RotationDialPlate(frame: dialPlateFrame, config: config)
        container.addSubview(dialPlate!)
    }
    
    private func setupPointer(in container: UIView){
        guard let dialPlate = dialPlate else { return }
        
        let path = CGMutablePath()
        let pointerEdgeLength: CGFloat = pointerWidth
        
        let pointTop = CGPoint(x: container.bounds.width/2, y: dialPlate.frame.maxY + spanBetweenDialPlateAndPointer)
        let pointLeft = CGPoint(x: container.bounds.width/2 - pointerEdgeLength / 2, y: pointTop.y + pointerHeight)
        let pointRight = CGPoint(x: container.bounds.width/2 + pointerEdgeLength / 2, y: pointLeft.y)
        
        path.move(to: pointTop)
        path.addLine(to: pointLeft)
        path.addLine(to: pointRight)
        path.addLine(to: pointTop)
        pointer.fillColor = config.indicatorColor.cgColor
        pointer.path = path
        container.layer.addSublayer(pointer)
    }
    
    private func getRotationCenter() -> CGPoint {
        guard let dialPlate = dialPlate else { return .zero }
        
        if case .custom(let center) = config.rotationCenterType {
            return center
        } else {
            let p = CGPoint(x: dialPlate.bounds.midX , y: dialPlate.bounds.midY)
            return dialPlate.convert(p, to: self)
        }
    }
}

// MARK: - public API
extension RotationDial {
    /// Setup the dial with your own config
    ///
    /// - Parameter config: dail config. If not provided, default config will be used
    public func setup(with config: Config = Config()) {
        self.config = config
        
        if case .limit(let angle) = config.rotationLimitType {
            angleLimit = angle
        }
        
        setupUI()
        setupViewModel()
    }
    
    @discardableResult
    func rotateDialPlate(by angle: CGAngle) -> Bool {
        guard let dialPlate = dialPlate else { return false }
        
        let radians = angle.radians
        if case .limit = config.rotationLimitType {
            if (getRotationAngle() * angle).radians > 0 && abs(getRotationAngle().radians + radians) >= angleLimit.radians {
                
                if radians > 0 {
                    rotateDialPlate(to: angleLimit)
                } else {
                    rotateDialPlate(to: -angleLimit)
                }
                
                return false
            }
        }
        
        dialPlate.transform = dialPlate.transform.rotated(by: radians)
        return true
    }
    
    public func rotateDialPlate(to angle: CGAngle, animated: Bool = false) {
        let radians = angle.radians
        
        if case .limit = config.rotationLimitType {
            guard abs(radians) <= angleLimit.radians else {
                return
            }
        }
        
        func rotate() {
            dialPlate?.transform = CGAffineTransform(rotationAngle: radians)
        }
        
        if animated {
            UIView.animate(withDuration: 0.5) {
                rotate()
            }
        } else {
            rotate()
        }
    }
    
    public func resetAngle(animated: Bool) {
        rotateDialPlate(to: CGAngle(radians: 0), animated: animated)
    }
    
    public func getRotationAngle() -> CGAngle {
        guard let dialPlate = dialPlate else { return CGAngle(degrees: 0) }
        
        let radians = CGFloat(atan2f(Float(dialPlate.transform.b), Float(dialPlate.transform.a)))
        return CGAngle(radians: radians)
    }
    
    public func setRotationCenter(by point: CGPoint, of view: UIView) {
        let p = view.convert(point, to: self)
        config.rotationCenterType = .custom(p)
    }
}
