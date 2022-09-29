//
//  ErrorManager.swift
//  MyMessenger
//
//  Created by Hasan Kaya on 19.09.2022.
//

import Foundation
import UIKit

struct ErrorManager {
    static let shared = ErrorManager()
    private init() {}
    
}
extension ErrorManager {
    public func presentError(title : String, message : String) -> UIAlertController{
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alert.addAction(action)
        return alert
    }
}
