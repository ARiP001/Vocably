//
//  Color+extension.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 19/04/26.
//

import SwiftUI

extension Color {
    static let brandPrimary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
        ? UIColor(red: 43/255, green: 182/255, blue: 94/255, alpha: 1)
        : UIColor(red: 43/255, green: 173/255, blue: 94/255, alpha: 1)
    })
    
    static let brandSecondary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
        ? UIColor(red: 182/255, green: 43/255, blue: 131/255, alpha: 1)
        : UIColor(red: 182/255, green: 34/255, blue: 131/255, alpha: 1)
    })

    static let bgPrimary = Color(UIColor.systemGroupedBackground)
    static let bgSecondary = Color(UIColor.secondarySystemGroupedBackground)
}
