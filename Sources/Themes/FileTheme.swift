//
//  FileTheme.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/21.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Foundation

public struct FileTheme: DestinationTheme {
    
    public typealias Color = UInt8
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
        self = FileTheme.initialize(foreground: foreground, background: background, components: components)
    }
    
    static func colorize(_ string: String, foreground: UInt8?, background: UInt8?) -> String {
        let f = "\u{001b}[38;5;"
        let b = "\u{001b}[48;5;"
        let r = "\u{001b}[0m"
        
        switch (foreground, background) {
        case (.some(let foreground), .some(let background)):
            return f + "\(foreground)m" + b + "\(background)m" + string + r
        case (.some(let foreground), .none):
            return f + "\(foreground)m" + string + r
        case (.none, .some(let background)):
            return b + "\(background)m" + string + r
        default:
            return string
        }
    }
}

// MARK: - FileTheme + Creations
public extension FileTheme {
    /**
     Conveniently create a new theme for logger destination.
     
     - parameter foreground: The foreground of the new theme.
     - parameter background: The background of the new theme.
     - parameter components: The components of the new theme.
     
     - returns: A new theme.
     */
    static func theme(_ foreground: [(PriorityLevel, Color?)]? = nil, background: [(PriorityLevel, Color?)]? = nil, components: LogComponents) -> FileTheme {
        return FileTheme.initialize(foreground: foreground, background: background, components: components)
    }
    
    /// Default classic theme.
    static func classic(_ components: LogComponents = .level) -> FileTheme {
        return FileTheme(
            foreground: [
                (.trace, 102), // #878787
                (.debug, 046), // #00ff00
                (.info,  012), // #0000ff
                (.warn,  011), // #ffff00
                (.error, 196), // #ff0000
                (.fatal, 231)  // #ffffff
            ],
            background: nil,
            components: components
        )
    }
    
    /// Default solarized theme.
    static func solarized(_ components: LogComponents = .level) -> FileTheme {
        return FileTheme(
            foreground: [
                (.trace, 109), // #87afaf
                (.debug, 036), // #00af87
                (.info,  032), // #0087d7
                (.warn,  136), // #af8700
                (.error, 160), // #d75f00
                (.fatal, 230)  // #ffffd7
            ],
            background: [
                (.fatal, 160)  // #d75f00
            ],
            components: components
        )
    }
    
    /// Default flat theme.
    static func flat(_ components: LogComponents = .level) -> FileTheme {
        return FileTheme(
            foreground: [
                (.trace, 188), // #d7d7d7
                (.debug, 037), // #00afaf
                (.info,  068), // #5f87d7
                (.warn,  220), // #ffd700
                (.error, 167), // #d75f5f
                (.fatal, 231)  // #ffffff
            ],
            background: [
                (.fatal, 167)  // #d75f5f
            ],
            components: components
        )
    }
}
