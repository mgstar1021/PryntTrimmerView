//
//  DurationView.swift
//  PryntTrimmerView
//
//  Created by Andrii Hanets on 15.09.2022.
//  Copyright © 2022 hhk. All rights reserved.
//

import AVFoundation
import UIKit

public class DurationView: UIView {
    private(set) var textView = UITextView()
    private(set) var pointerView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        pointerView.translatesAutoresizingMaskIntoConstraints = false
        
        [textView, pointerView].forEach(addSubview)
        
        textView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        textView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        textView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        textView.bottomAnchor.constraint(equalTo: pointerView.topAnchor).isActive = true
        
        pointerView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        pointerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        pointerView.widthAnchor.constraint(equalToConstant: 2).isActive = true
        pointerView.heightAnchor.constraint(equalToConstant: 6).isActive = true
        
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = false
        textView.layer.cornerRadius = 2
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6)
    }
    
    func updateBackground(color: UIColor) {
        textView.backgroundColor = color
        pointerView.backgroundColor = color
    }
    
    func updateText(color: UIColor) {
        textView.textColor = color
    }
    
    func font(size: Int) {
        textView.font = .systemFont(ofSize: 12)
    }
    
    func setDuration(_ time: CMTime) {
        textView.text = time.durationText
    }
    
    func set(visable: Bool) {
        guard !textView.text.isEmpty else { return }
        
        UIView.animate(withDuration: 0.2) {
            self.alpha = visable ? 1 : 0
        }
    }
    
}

extension CMTime {
    var durationText: String {
        let time = TimeInterval(CMTimeGetSeconds(self))
        
        if time.hour > 0 {
            return time.hourMinuteSecond
        } else {
            return time.minuteSecondMS
        }
    }
}

extension TimeInterval {
    var hourMinuteSecond: String {
        String(format: "%d:%02d:%02d", hour, minute, second)
    }
    var minuteSecondMS: String {
        String(format: "%d:%02d.%02d", minute, second, millisecond)
    }
    var hour: Int {
        Int((self/3600).truncatingRemainder(dividingBy: 3600))
    }
    var minute: Int {
        Int((self/60).truncatingRemainder(dividingBy: 60))
    }
    var second: Int {
        Int(truncatingRemainder(dividingBy: 60))
    }
    var millisecond: Int {
        Int((self*100).truncatingRemainder(dividingBy: 100))
    }
}
