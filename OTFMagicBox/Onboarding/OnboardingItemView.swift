/*
Copyright (c) 2021, Hippocrates Technologies S.r.l.. All rights reserved.

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

import SwiftUI

/// The onboarding items view elements.
struct OnboardingItemView<OnboardingItem: View>: View {
    
    /// The onboarding items view controller.
    var viewControllers: [UIHostingController<OnboardingItem>]
    
    /// The current onboarding item.
    @State var currentOnboardingItem = 0
    
    /// Creates the onboarding item view.
    init(_ views: [OnboardingItem]) {
        self.viewControllers = views.map {
            let controller = UIHostingController(rootView: $0)
            controller.view.backgroundColor = .clear
            return controller
        }
    }

    /// The onboarding items view.
    var body: some View {
        ZStack(alignment: .bottom) {
            OnboardingItemViewController(controllers: viewControllers, currentPage: $currentOnboardingItem)
                .background(Color.clear)
            if viewControllers.count > 1 {
                OnboardingItemControl(numberOfOnboardingItems: viewControllers.count, currentOnboardingItem: $currentOnboardingItem)
                    .background(Color.clear)
                    .offset(x: 0, y: -80)
                
            }
        }
        .ignoresSafeArea()
    }
    
}

/// The onboarding items view controller.
struct OnboardingItemViewController: UIViewControllerRepresentable {
    
    /// The controllers for the onboarding items.
    var controllers: [UIViewController]
    
    /// The current page.
    @Binding var currentPage: Int

    /// Documentation is in UIViewControllerRepresentable.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// Documentation is in UIViewControllerRepresentable.
    func makeUIViewController(context: Context) -> UIPageViewController {
        let onboardingItemViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal)
        if controllers.count > 1 {
            onboardingItemViewController.dataSource = context.coordinator
            onboardingItemViewController.delegate = context.coordinator
        }
        onboardingItemViewController.view.backgroundColor = .clear

        return onboardingItemViewController
    }

    /// Documentation is in UIViewControllerRepresentable.
    func updateUIViewController(_ onboardingItemViewController: UIPageViewController, context: Context) {
        onboardingItemViewController.setViewControllers(
        [self.controllers[self.currentPage]], direction: .forward, animated: true)
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

        /// The parent onboarding items view controller.
        var parent: OnboardingItemViewController

        /// Creates onboarding items view controller.
        init(_ OnboardingItemViewController: OnboardingItemViewController) {
            self.parent = OnboardingItemViewController
        }

        /// Documentation is in UIPageViewControllerDataSource.
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = parent.controllers.firstIndex(of: viewController) else {
                return nil
            }
            if index == 0 {
                return parent.controllers.last
            }
            return parent.controllers[index - 1]
        }
        
        /// Documentation is in UIPageViewControllerDataSource.
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = parent.controllers.firstIndex(of: viewController) else {
                return nil
            }
            if index + 1 == parent.controllers.count {
                return parent.controllers.first
            }
            return parent.controllers[index + 1]
        }

        /// Documentation is in UIPageViewControllerDelegate.
        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed,
                let visibleViewController = pageViewController.viewControllers?.first,
                let index = parent.controllers.firstIndex(of: visibleViewController) {
                parent.currentPage = index
            }
        }
    }
}

/// The onboarding item  control.
struct OnboardingItemControl: UIViewRepresentable {
    
    /// The number of onboarding items.
    var numberOfOnboardingItems: Int
    
    /// The current onboarding item.
    @Binding var currentOnboardingItem: Int
    
    /// Documentation is in UIViewRepresentable.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// Documentation is in UIViewRepresentable.
    func makeUIView(context: Context) -> UIPageControl {
        let control = UIPageControl()
        control.numberOfPages = numberOfOnboardingItems
        control.pageIndicatorTintColor = UIColor.lightGray
        control.currentPageIndicatorTintColor = YmlReader().primaryColor
        control.backgroundColor = .clear
        control.addTarget(
            context.coordinator,
            action: #selector(Coordinator.updateCurrentOnboardingItem(sender:)),
            for: .valueChanged)

        return control
    }

    /// Documentation is in UIViewRepresentable.
    func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.currentPage = currentOnboardingItem
    }

    class Coordinator: NSObject {
        
        /// Control of the onboarding item controller.
        var control: OnboardingItemControl

        /// Creates onboarding item controller.
        init(_ control: OnboardingItemControl) {
            self.control = control
        }
        
        /// Updates the on boarding item.
        @objc func updateCurrentOnboardingItem(sender: UIPageControl) {
            control.currentOnboardingItem = sender.currentPage
        }
    }
}
