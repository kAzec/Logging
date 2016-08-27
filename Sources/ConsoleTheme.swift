//
//  ConsoleTheme.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/18.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Foundation

/**
 *  Logger ConsoleDestination Theme, based on [XCodeColors](https://github.com/robbiehanson/XcodeColors).
 */
public struct ConsoleTheme: DestinationTheme, CustomStringConvertible {
    public typealias Color = UInt32
    typealias Colors = [(foreground: Color?, background: Color?)]
    
    let colors: [(foreground: Color?, background: Color?)]
    let components: LogComponents

    /// Textual representation of the receiver.
    public var description: String {
        return textualRepresentation
    }
    
    init(colors: [(foreground: Color?, background: Color?)], components: LogComponents) {
        self.colors = colors
        self.components = components
    }
    
    /**
     Initializes a new theme for logger destination.
     
     - parameter foreground: The theme's foreground colors.
     - parameter background: The theme's background colors.
     - parameter components: The theme's components.
     
     - returns: A new theme.
     */
    public init(foreground: [(PriorityLevel, Color?)]? = nil, background: [(PriorityLevel, Color?)]? = nil, components: LogComponents) {
        self = ConsoleTheme.initialize(foreground: foreground, background: background, components: components)
    }
    
    static func colorize(string: String, foreground: Color?, background: Color?) -> String {
        let color = (colorStringFromHex(foreground), colorStringFromHex(background))
        switch color {
        case (.Some(let foreground), .Some(let background)):
            return "\u{001b}[fg\(foreground);\u{001b}[bg\(background);\(string)\u{001b}[;"
        case (.Some(let foreground), .None):
            return "\u{001b}[fg\(foreground);\(string)\u{001b}[fg;"
        case (.None, .Some(let background)):
            return "\u{001b}[bg\(background);\(string)\u{001b}[bg;"
        default:
            return string
        }
    }
}

// MARK: - ConsoleTheme + Creations
public extension ConsoleTheme {
    /**
     Conveniently create a new theme for logger destination.
     
     - parameter foreground: The foreground of the new theme.
     - parameter background: The background of the new theme.
     - parameter components: The components of the new theme.
     
     - returns: A new theme.
     */
    static func theme(foreground: [(PriorityLevel, Color?)]? = nil, background: [(PriorityLevel, Color?)]? = nil, components: LogComponents) -> ConsoleTheme {
        return ConsoleTheme.initialize(foreground: foreground, background: background, components: components)
    }
    
    /// Default classic theme.
    static func classic(components: LogComponents = .level) -> ConsoleTheme {
        return ConsoleTheme(
            foreground: [
                (.trace, 0x808080),
                (.debug, 0x00FF00),
                (.info,  0x0000FF),
                (.warn,  0xFFFF00),
                (.error, 0xFF0000),
                (.fatal, 0xFFFFFF)
            ],
            background: [
                (.fatal, 0xFF0000)
            ],
            components: components
        )
    }
    
    /// Default solarized theme.
    static func solarized(components: LogComponents = .level) -> ConsoleTheme {
        return ConsoleTheme(
            foreground: [
                (.trace, 0x93A1A2),
                (.debug, 0x2AA198),
                (.info,  0x268BD2),
                (.warn,  0xB58900),
                (.error, 0xDC322F),
                (.fatal, 0xFDF6E3)
            ],
            background: [
                (.fatal, 0xDC322F)
            ],
            components: components
        )
    }
    
    /// Default flat theme.
    static func flat(components: LogComponents = .level) -> ConsoleTheme {
        return ConsoleTheme(
            foreground: [
                (.trace, 0xE0E0E0),
                (.debug, 0x1ABC9C),
                (.info,  0x3498DB),
                (.warn,  0xF1C40F),
                (.error, 0xE74C3C),
                (.fatal, 0xF5F5F5)
            ],
            background: [
                (.fatal, 0xE74C3C)
            ],
            components: components
        )
    }
}

// MARK: - Privates
private func colorStringFromHex(hex: ConsoleTheme.Color?) -> String? {
    guard let hex = hex else { return nil }
    
    let r = (hex & 0xFF0000) >> 16
    let g = (hex & 0x00FF00) >> 8
    let b = hex & 0x0000FF
    
    return "\(r),\(g),\(b)"
}