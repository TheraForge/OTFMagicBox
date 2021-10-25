//
//  OnboardingItemView.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 12.05.21.
//

import SwiftUI

/// The onboarding items view elements.
struct OnboardingItemView<OnboardingItem: View>: View {
    
    /// The onboarding items view controller.
    var viewControllers: [UIHostingController<OnboardingItem>]
    
    /// The current onboarding item.
    @State var currentOnboardingItem = 0
    
    /// Creates the onboarding item view.
    init(_ views: [OnboardingItem]) {
        self.viewControllers = views.map { UIHostingController(rootView: $0) }
    }

    /// The onboarding items view.
    var body: some View {
        ZStack(alignment: .bottom) {
            OnboardingItemViewController(controllers: viewControllers, currentPage: $currentOnboardingItem)
            OnboardingItemControl(numberOfOnboardingItems: viewControllers.count, currentOnboardingItem: $currentOnboardingItem)
        }
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
        let OnboardingItemViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal)
        OnboardingItemViewController.dataSource = context.coordinator
        OnboardingItemViewController.delegate = context.coordinator

        return OnboardingItemViewController
    }

    /// Documentation is in UIViewControllerRepresentable.
    func updateUIViewController(_ OnboardingItemViewController: UIPageViewController, context: Context) {
        OnboardingItemViewController.setViewControllers(
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
