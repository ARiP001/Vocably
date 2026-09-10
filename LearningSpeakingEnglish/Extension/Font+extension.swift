//
//  Font+extension.swift
//  LearningSpeakingEnglish
//
//  Created by Arif Fathurrahman on 10/09/26.
//
import SwiftUI

enum AppFont {
    static let largeTitleBold: Font = .largeTitle.bold()
    static let title1Bold: Font = .title.bold()
    static let title2Bold: Font = .title2.bold()
    static let title2Regular: Font = .title2
    static let title3Bold: Font = .title3.bold()
    static let headlineRegular: Font = .headline
    static let bodyRegular: Font = .body
    static let subheadRegular: Font = .subheadline
    static let subheadMedium: Font = .subheadline.weight(.medium)
    static let subheadSemibold: Font = .subheadline.weight(.semibold)
    static let caption1Regular: Font = .caption
    static let caption1Medium: Font = .caption.weight(.medium)
    static let caption1Bold: Font = .caption.bold()
    static let caption1Semibold: Font = .caption.weight(.semibold)
    static let caption2Bold: Font = .caption2.bold()
}

extension Font {
    static let appLargeTitleBold = AppFont.largeTitleBold
    static let appTitle1Bold = AppFont.title1Bold
    static let appTitle2Bold = AppFont.title2Bold
    static let appTitle2Regular = AppFont.title2Regular
    static let appTitle3Bold = AppFont.title3Bold
    static let appHeadlineRegular = AppFont.headlineRegular
    static let appBodyRegular = AppFont.bodyRegular
    static let appSubheadRegular = AppFont.subheadRegular
    static let appSubheadMedium = AppFont.subheadMedium
    static let appSubheadSemibold = AppFont.subheadSemibold
    static let appCaption1Regular = AppFont.caption1Regular
    static let appCaption1Medium = AppFont.caption1Medium
    static let appCaption1Bold = AppFont.caption1Bold
    static let appCaption1Semibold = AppFont.caption1Semibold
    static let appCaption2Bold = AppFont.caption2Bold
}
