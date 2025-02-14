//
//  DoctorLoginViewController.swift
//  OTFMagicBox
//
//  Created by Arslan Raza on 25/07/2024.
//

import UIKit
import WebKit

class DoctorLoginViewController: UIViewController, WKNavigationDelegate {
    
    var webView: WKWebView!
    
    lazy var doctorLoginLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 19)
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    lazy var linkToWeb: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .black
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = Constants.doctorLogin
        self.view.addSubview(doctorLoginLabel)
        self.view.addSubview(linkToWeb)
        setAttributedTextWithLink(text: Constants.theraforgeWebLink)
        setAttributedTextLineSpacing(text: ModuleAppYmlReader().failedLoginWithDoctorCred)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleLabelTap(_:)))
        linkToWeb.addGestureRecognizer(tapGesture)
        
        webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        view.addSubview(webView)
        layoutSubviews()
    }
    
    private func layoutSubviews() {
        doctorLoginLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 40).isActive = true
        doctorLoginLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            .isActive = true
        doctorLoginLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        doctorLoginLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        doctorLoginLabel.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        linkToWeb.topAnchor.constraint(equalTo: doctorLoginLabel.topAnchor, constant: 70).isActive = true
        linkToWeb.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            .isActive = true
        linkToWeb.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15).isActive = true
        linkToWeb.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        linkToWeb.heightAnchor.constraint(equalToConstant: 80).isActive = true
    }
    
    @objc func handleLabelTap(_ gesture: UITapGestureRecognizer) {
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        if let url = URL(string: Constants.theraforgeWebLink) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func setAttributedTextLineSpacing(text: String) {
        let attributedString = NSMutableAttributedString(string: text)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .center
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: attributedString.length)
        )
        
        doctorLoginLabel.attributedText = attributedString
    }
    
    func setAttributedTextWithLink(text: String) {
        let attributedString = NSMutableAttributedString(string: text)
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        
        detector?.enumerateMatches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) { (match, _, _) in
            if let match = match, let url = match.url {
                attributedString.addAttribute(.link, value: url, range: match.range)
                attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: match.range)
                attributedString.addAttribute(.foregroundColor, value: UIColor.link, range: match.range)
            }
        }
        
        linkToWeb.attributedText = attributedString
    }
    
}
