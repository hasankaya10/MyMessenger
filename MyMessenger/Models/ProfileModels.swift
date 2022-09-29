//
//  ProfileModels.swift
//  MyMessenger
//
//  Created by Hasan Kaya on 19.09.2022.
//

import Foundation
struct profileViewModel {
    let viewModelType : ProfileViewModelType
    let title: String
    let handler : (() -> Void)?
}
enum ProfileViewModelType{
    case info,logOut
}
