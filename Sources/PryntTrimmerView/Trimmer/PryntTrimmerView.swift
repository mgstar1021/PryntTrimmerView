//
//  PryntTrimmerView.swift
//  PryntTrimmerView
//
//  Created by HHK on 27/03/2017.
//  Copyright © 2017 Prynt. All rights reserved.
//

import AVFoundation
import UIKit

public protocol TrimmerViewDelegate: AnyObject {
    func didChangePositionBar(_ playerTime: CMTime)
    func positionBarStoppedMoving(_ playerTime: CMTime)
}

/// A view to select a specific time range of a video. It consists of an asset preview with thumbnails inside a scroll view, two
/// handles on the side to select the beginning and the end of the range, and a position bar to synchronize the control with a
/// video preview, typically with an `AVPlayer`.
/// Load the video by setting the `asset` property. Access the `startTime` and `endTime` of the view to get the selected time
// range
@IBDesignable public class TrimmerView: AVAssetTimeSelector {

    // MARK: - Properties
    private var leftPanGestureRecognizer: UIPanGestureRecognizer?
    private var rightPanGestureRecognizer: UIPanGestureRecognizer?
    
    private var leftLongTapGestureRecognizer: UILongPressGestureRecognizer?
    private var rightLongTapGestureRecognizer: UILongPressGestureRecognizer?

    // MARK: Color Customization

    /// The color of the main border of the view
    @IBInspectable public var mainColor: UIColor = UIColor.orange {
        didSet {
            updateMainColor()
        }
    }

    /// The color of the handles on the side of the view
    @IBInspectable public var handleColor: UIColor = UIColor.gray {
        didSet {
           updateHandleColor()
        }
    }

    /// The color of the position indicator
    @IBInspectable public var positionBarColor: UIColor = UIColor.white {
        didSet {
            positionBar.backgroundColor = positionBarColor
        }
    }

    /// The color used to mask unselected parts of the video
    @IBInspectable public var maskColor: UIColor = UIColor.white {
        didSet {
            leftMaskView.backgroundColor = maskColor
            rightMaskView.backgroundColor = maskColor
        }
    }

    // MARK: Interface

    public weak var delegate: TrimmerViewDelegate?

    // MARK: Subviews

    private let trimView = UIView()
    private let leftHandleView = HandlerView()
    private let rightHandleView = HandlerView()
    private let positionBar = UIView()
    private let leftHandleKnob = UIView()
    private let rightHandleKnob = UIView()
    private let leftMaskView = UIView()
    private let rightMaskView = UIView()
    private let leftDurationView = DurationView()
    private let rightDurationView = DurationView()
    private let totalDurationLabel = UILabel()

    // MARK: Constraints

    private var currentLeftConstraint: CGFloat = 0
    private var currentRightConstraint: CGFloat = 0
    private var leftConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?
    private var positionConstraint: NSLayoutConstraint?

    private let handleWidth: CGFloat = 15

    /// The minimum duration allowed for the trimming. The handles won't pan further if the minimum duration is attained.
    public var minDuration: Double = 3
    
    private let totalDurationTopSpacing: CGFloat = 16

    // MARK: - View & constraints configurations

    override func setupSubviews() {
        setupTotalDurationLabel()
        
        super.setupSubviews()
        layer.cornerRadius = 2
        backgroundColor = UIColor.clear
        layer.zPosition = 1
        setupTrimmerView()
        setupHandleView()
        setupMaskView()
        setupPositionBar()
        setupGestures()
        updateMainColor()
        updateHandleColor()
        setupDurationViews()
    }

    override func constrainAssetPreview() {
        assetPreview.leftAnchor.constraint(equalTo: leftAnchor, constant: handleWidth).isActive = true
        assetPreview.rightAnchor.constraint(equalTo: rightAnchor, constant: -handleWidth).isActive = true
        assetPreview.topAnchor.constraint(equalTo: topAnchor).isActive = true
        assetPreview.bottomAnchor.constraint(equalTo: totalDurationLabel.topAnchor, constant: -totalDurationTopSpacing).isActive = true
    }

    private func setupTrimmerView() {
        trimView.layer.borderWidth = 2.0
        trimView.layer.cornerRadius = 2.0
        trimView.translatesAutoresizingMaskIntoConstraints = false
        trimView.isUserInteractionEnabled = false
        addSubview(trimView)

        trimView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        trimView.bottomAnchor.constraint(equalTo: totalDurationLabel.topAnchor, constant: -totalDurationTopSpacing).isActive = true
        leftConstraint = trimView.leftAnchor.constraint(equalTo: leftAnchor)
        rightConstraint = trimView.rightAnchor.constraint(equalTo: rightAnchor)
        leftConstraint?.isActive = true
        rightConstraint?.isActive = true
    }

    private func setupHandleView() {

        leftHandleView.isUserInteractionEnabled = true
        leftHandleView.layer.cornerRadius = 2.0
        leftHandleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftHandleView)

        leftHandleView.heightAnchor.constraint(equalTo: trimView.heightAnchor).isActive = true
        leftHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        leftHandleView.leftAnchor.constraint(equalTo: trimView.leftAnchor).isActive = true
        leftHandleView.centerYAnchor.constraint(equalTo: trimView.centerYAnchor).isActive = true

        leftHandleKnob.translatesAutoresizingMaskIntoConstraints = false
        leftHandleView.addSubview(leftHandleKnob)

        leftHandleKnob.heightAnchor.constraint(equalTo: leftHandleView.heightAnchor, multiplier: 0.5).isActive = true
        leftHandleKnob.widthAnchor.constraint(equalToConstant: 2).isActive = true
        leftHandleKnob.centerYAnchor.constraint(equalTo: leftHandleView.centerYAnchor).isActive = true
        leftHandleKnob.centerXAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true

        rightHandleView.isUserInteractionEnabled = true
        rightHandleView.layer.cornerRadius = 2.0
        rightHandleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightHandleView)

        rightHandleView.heightAnchor.constraint(equalTo: trimView.heightAnchor).isActive = true
        rightHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        rightHandleView.rightAnchor.constraint(equalTo: trimView.rightAnchor).isActive = true
        rightHandleView.centerYAnchor.constraint(equalTo: trimView.centerYAnchor).isActive = true

        rightHandleKnob.translatesAutoresizingMaskIntoConstraints = false
        rightHandleView.addSubview(rightHandleKnob)

        rightHandleKnob.heightAnchor.constraint(equalTo: rightHandleView.heightAnchor, multiplier: 0.5).isActive = true
        rightHandleKnob.widthAnchor.constraint(equalToConstant: 2).isActive = true
        rightHandleKnob.centerYAnchor.constraint(equalTo: rightHandleView.centerYAnchor).isActive = true
        rightHandleKnob.centerXAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
        
        leftHandleView.addSubview(leftDurationView)
        leftDurationView.centerXAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true
        leftDurationView.bottomAnchor.constraint(equalTo: leftHandleView.topAnchor, constant: -4).isActive = true
        leftDurationView.alpha = 0
        
        rightHandleView.addSubview(rightDurationView)
        rightDurationView.centerXAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
        rightDurationView.bottomAnchor.constraint(equalTo: rightHandleView.topAnchor, constant: -4).isActive = true
        rightDurationView.alpha = 0
    }

    private func setupMaskView() {

        leftMaskView.isUserInteractionEnabled = false
        leftMaskView.backgroundColor = .white
        leftMaskView.alpha = 0.7
        leftMaskView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(leftMaskView, belowSubview: leftHandleView)

        leftMaskView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        leftMaskView.bottomAnchor.constraint(equalTo: totalDurationLabel.topAnchor, constant: -totalDurationTopSpacing).isActive = true
        leftMaskView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        leftMaskView.rightAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true

        rightMaskView.isUserInteractionEnabled = false
        rightMaskView.backgroundColor = .white
        rightMaskView.alpha = 0.7
        rightMaskView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(rightMaskView, belowSubview: rightHandleView)

        rightMaskView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        rightMaskView.bottomAnchor.constraint(equalTo: totalDurationLabel.topAnchor, constant: -totalDurationTopSpacing).isActive = true
        rightMaskView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rightMaskView.leftAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
    }

    private func setupPositionBar() {

        positionBar.frame = CGRect(x: 0, y: 0, width: 3, height: frame.height)
        positionBar.backgroundColor = positionBarColor
        positionBar.center = CGPoint(x: leftHandleView.frame.maxX, y: center.y)
        positionBar.layer.cornerRadius = 1
        positionBar.translatesAutoresizingMaskIntoConstraints = false
        positionBar.isUserInteractionEnabled = false
        addSubview(positionBar)

        positionBar.centerYAnchor.constraint(equalTo: trimView.centerYAnchor).isActive = true
        positionBar.widthAnchor.constraint(equalToConstant: 3).isActive = true
        positionBar.heightAnchor.constraint(equalTo: trimView.heightAnchor).isActive = true
        positionConstraint = positionBar.leftAnchor.constraint(equalTo: leftHandleView.rightAnchor, constant: 0)
        positionConstraint?.isActive = true
    }
    
    private func setupTotalDurationLabel() {
        totalDurationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(totalDurationLabel)
        totalDurationLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        totalDurationLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -handleWidth).isActive = true
        totalDurationLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        totalDurationLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
    }

    private func setupGestures() {

        leftPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
        leftHandleView.addGestureRecognizer(leftPanGestureRecognizer!)
        rightPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
        rightHandleView.addGestureRecognizer(rightPanGestureRecognizer!)
        
        leftLongTapGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TrimmerView.handleLongTapGesture))
        leftHandleView.addGestureRecognizer(leftLongTapGestureRecognizer!)
        rightLongTapGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TrimmerView.handleLongTapGesture))
        rightHandleView.addGestureRecognizer(rightLongTapGestureRecognizer!)
        
        leftPanGestureRecognizer?.delegate = self
        rightPanGestureRecognizer?.delegate = self
        
        leftLongTapGestureRecognizer?.minimumPressDuration = 0.2
        leftLongTapGestureRecognizer?.delaysTouchesBegan = true
        leftLongTapGestureRecognizer?.delegate = self
        
        rightLongTapGestureRecognizer?.minimumPressDuration = 0.2
        rightLongTapGestureRecognizer?.delaysTouchesBegan = true
        rightLongTapGestureRecognizer?.delegate = self
    }

    private func updateMainColor() {
        trimView.layer.borderColor = mainColor.cgColor
        leftHandleView.backgroundColor = mainColor
        rightHandleView.backgroundColor = mainColor
    }

    private func updateHandleColor() {
        leftHandleKnob.backgroundColor = handleColor
        rightHandleKnob.backgroundColor = handleColor
    }
    
    private func setupDurationViews() {
        leftDurationView.updateBackground(color: handleColor)
        leftDurationView.updateText(color: .white)
        leftDurationView.font(size: 14)
        
        rightDurationView.updateBackground(color: handleColor)
        rightDurationView.updateText(color: .white)
        rightDurationView.font(size: 14)
        
        totalDurationLabel.textColor = handleColor
        totalDurationLabel.font = .systemFont(ofSize: 14)
        totalDurationLabel.textAlignment = .right
    }
   
    func setTotalDuration(_ time: CMTime) {
        totalDurationLabel.text = "Total: \(time.durationText)"
    }

    // MARK: - Trim Gestures

    @objc func handleLongTapGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = gestureRecognizer.view else { return }
        
        let isLeftGesture = view == leftHandleView
        
        switch gestureRecognizer.state {
        case .began:
            if isLeftGesture {
                if let startTime = startTime {
                    leftDurationView.setDuration(startTime)
                }
                leftDurationView.set(visable: true)
            } else {
                if let endTime = endTime {
                    rightDurationView.setDuration(endTime)
                }
                rightDurationView.set(visable: true)
            }
        case .ended, .cancelled, .failed:
            isLeftGesture ? leftDurationView.set(visable: false) : rightDurationView.set(visable: false)
        default:
            break
        }
   
    }
    
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = gestureRecognizer.view, let superView = gestureRecognizer.view?.superview else { return }
        let isLeftGesture = view == leftHandleView
        
        switch gestureRecognizer.state {

        case .began:
            if isLeftGesture {
                currentLeftConstraint = leftConstraint!.constant
                leftDurationView.set(visable: true)
            } else {
                currentRightConstraint = rightConstraint!.constant
                rightDurationView.set(visable: true)
            }
            updateSelectedTime(stoppedMoving: false)
        case .changed:
            let translation = gestureRecognizer.translation(in: superView)
            if isLeftGesture {
                updateLeftConstraint(with: translation)
            } else {
                updateRightConstraint(with: translation)
            }
            layoutIfNeeded()
            if let startTime = startTime, isLeftGesture {
                seek(to: startTime)
            } else if let endTime = endTime {
                seek(to: endTime)
            }
            updateSelectedTime(stoppedMoving: false)

            if isLeftGesture {
                if let startTime = startTime {
                    leftDurationView.setDuration(startTime)
                }
                leftDurationView.set(visable: true)
            } else {
                if let endTime = endTime {
                    rightDurationView.setDuration(endTime)
                }
                rightDurationView.set(visable: true)
            }
            
        case .cancelled, .ended, .failed:
            updateSelectedTime(stoppedMoving: true)
            isLeftGesture ? leftDurationView.set(visable: false) : rightDurationView.set(visable: false)
        default: break
        }
    }

    private func updateLeftConstraint(with translation: CGPoint) {
        let maxConstraint = max(rightHandleView.frame.origin.x - handleWidth - minimumDistanceBetweenHandle, 0)
        let newConstraint = min(max(0, currentLeftConstraint + translation.x), maxConstraint)
        leftConstraint?.constant = newConstraint
    }

    private func updateRightConstraint(with translation: CGPoint) {
        let maxConstraint = min(2 * handleWidth - frame.width + leftHandleView.frame.origin.x + minimumDistanceBetweenHandle, 0)
        let newConstraint = max(min(0, currentRightConstraint + translation.x), maxConstraint)
        rightConstraint?.constant = newConstraint
    }

    // MARK: - Asset loading

    override func assetDidChange(newAsset: AVAsset?) {
        super.assetDidChange(newAsset: newAsset)
        resetHandleViewPosition()
        
        guard let endTime = endTime, let startTime = startTime else { return }
        
        setTotalDuration((endTime - startTime))
    }

    private func resetHandleViewPosition() {
        leftConstraint?.constant = 0
        rightConstraint?.constant = 0
        layoutIfNeeded()
    }

    // MARK: - Time Equivalence

    /// Move the position bar to the given time.
    public func seek(to time: CMTime) {
        if let newPosition = getPosition(from: time) {

            let offsetPosition = newPosition - assetPreview.contentOffset.x - leftHandleView.frame.origin.x
            let maxPosition = rightHandleView.frame.origin.x - (leftHandleView.frame.origin.x + handleWidth)
                              - positionBar.frame.width
            let normalizedPosition = min(max(0, offsetPosition), maxPosition)
            positionConstraint?.constant = normalizedPosition
            layoutIfNeeded()
        }
    }

    /// The selected start time for the current asset.
    public var startTime: CMTime? {
        let startPosition = leftHandleView.frame.origin.x + assetPreview.contentOffset.x
        return getTime(from: startPosition)
    }

    /// The selected end time for the current asset.
    public var endTime: CMTime? {
        let endPosition = rightHandleView.frame.origin.x + assetPreview.contentOffset.x - handleWidth
        print(getTime(from: endPosition)?.durationText)
        return getTime(from: endPosition)
    }

    private func updateSelectedTime(stoppedMoving: Bool) {
        guard let playerTime = positionBarTime else {
            return
        }
        if stoppedMoving {
            delegate?.positionBarStoppedMoving(playerTime)
        } else {
            delegate?.didChangePositionBar(playerTime)
            
            let duration = endTime! - startTime!
            setTotalDuration(duration)
        }
        
        leftDurationView.setDuration(playerTime)
        rightDurationView.setDuration(playerTime)
    }

    private var positionBarTime: CMTime? {
        let barPosition = positionBar.frame.origin.x + assetPreview.contentOffset.x - handleWidth
        return getTime(from: barPosition)
    }

    private var minimumDistanceBetweenHandle: CGFloat {
        guard let asset = asset else { return 0 }
        return CGFloat(minDuration) * assetPreview.contentView.frame.width / CGFloat(asset.duration.seconds)
    }

    // MARK: - Scroll View Delegate

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateSelectedTime(stoppedMoving: true)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateSelectedTime(stoppedMoving: true)
        }
    }
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateSelectedTime(stoppedMoving: false)
    }
}


// MARK: - UIGestureRecognizerDelegate
extension TrimmerView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let isLeftGestures = gestureRecognizer == leftLongTapGestureRecognizer && otherGestureRecognizer == leftPanGestureRecognizer
        let isRightGestures = gestureRecognizer == rightLongTapGestureRecognizer && otherGestureRecognizer == rightPanGestureRecognizer
        
        return (isLeftGestures || isRightGestures)
    }
}
