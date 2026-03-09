/*
 Copyright (c) 2026, Hippocrates Technologies Sagl. All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

 3. Neither the name of the copyright holder(s) nor the names of any contributor(s) may
 be used to endorse or promote products derived from this software without specific
 prior written permission. No license is granted to the trademarks of the copyright
 holders even if such marks are included in this software.

 4. Commercial redistribution in any form requires an explicit license agreement with the
 copyright holder(s). Please contact support@hippocratestech.com for further information
 regarding licensing.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE.
 */

import UIKit

class SkeletonCardView: UIView {
    
    /// Views with shimmer animation that need frame updates on layout changes
    private var shimmerViews: [UIView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update shimmer gradient frames on rotation/layout changes
        for view in shimmerViews {
            if let gradientLayer = view.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
                gradientLayer.frame = view.bounds
            }
        }
    }
    
    private func setupView() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        translatesAutoresizingMaskIntoConstraints = false
        
        // Skeleton title bar
        let titleBar = createSkeletonBar(color: .systemGray5)
        NSLayoutConstraint.activate([
            titleBar.widthAnchor.constraint(equalToConstant: 140),
            titleBar.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        // Skeleton subtitle bar
        let subtitleBar = createSkeletonBar(color: .systemGray6)
        NSLayoutConstraint.activate([
            subtitleBar.widthAnchor.constraint(equalToConstant: 200),
            subtitleBar.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        // Skeleton button bar
        let buttonBar = createSkeletonBar(color: .systemGray5)
        buttonBar.layer.cornerRadius = 8
        NSLayoutConstraint.activate([
            buttonBar.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        addSubview(titleBar)
        addSubview(subtitleBar)
        addSubview(buttonBar)
        
        NSLayoutConstraint.activate([
            titleBar.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            subtitleBar.topAnchor.constraint(equalTo: titleBar.bottomAnchor, constant: 8),
            subtitleBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            buttonBar.topAnchor.constraint(equalTo: subtitleBar.bottomAnchor, constant: 16),
            buttonBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            buttonBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            buttonBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        
        // Add shimmer animation and track views for layout updates
        shimmerViews = [titleBar, subtitleBar, buttonBar]
        shimmerViews.forEach { addShimmerAnimation(to: $0) }
    }
    
    private func createSkeletonBar(color: UIColor) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    private func addShimmerAnimation(to view: UIView) {
        let gradientLayer = CAGradientLayer()
        let baseColor = UIColor.systemGray5.cgColor
        let highlightColor = UIColor.systemGray3.cgColor
        
        gradientLayer.colors = [baseColor, highlightColor, baseColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.locations = [0.25, 0.5, 0.75]
        gradientLayer.frame = view.bounds
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.2
        animation.repeatCount = .infinity
        
        gradientLayer.add(animation, forKey: "shimmer")

        view.layer.addSublayer(gradientLayer)
        view.layer.masksToBounds = true
    }
}
