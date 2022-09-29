//
//  ConversationModels.swift
//  MyMessenger
//
//  Created by Hasan Kaya on 19.09.2022.
//

import Foundation
struct Conversation {
    let id : String
    let name : String
    let otherUserEmail : String
    let latestMessage : LatestMessage

}
struct LatestMessage {
    let date : String
    let Message : String
    let isRead : Bool
}
