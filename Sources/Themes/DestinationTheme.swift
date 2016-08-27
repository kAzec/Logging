//
//  DestinationTheme.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/21.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Foundation

protocol DestinationTheme {
    associatedtype Color
    
    var colors: [(foreground: Color?, background: Color?)] { get }
    var components: LogComponents { get }
    
    init(colors: [(foreground: Color?, background: Color?)], components: LogComponents)
    
    static func colorize(string: String, foreground: Color?, background: Color?) -> String
}

extension DestinationTheme {
    var textualRepresentation: String {
        return colors.enumerate().map {
            return Self.colorize(PriorityLevel(rawValue: $0)!.symbol, foreground: $1.foreground, background: $1.background)
            }.joinWithSeparator(" ")
    }
    
    func colorizeEntry(entry: LogEntry, forLevel level: PriorityLevel) -> LogEntry {
        let newPairs = entry.pairs.map { component, content in
            return (component: component, content: colorizeComponent(component, content: content, level: level))
        }
        
        return LogEntry(newPairs)
    }
    
    func colorizeComponent(component: LogComponents, content: String, level: PriorityLevel) -> String {
        if components.contains(component) {
            let color = colors[level.rawValue]
            
            if color.foreground == nil && color.background == nil {
                return content
            } else {
                return Self.colorize(content, foreground: color.foreground, background: color.background)
            }
        } else {
            return content
        }
    }
    
    static func initialize(foreground foreground: [(PriorityLevel, Color?)]? = nil, background: [(PriorityLevel, Color?)]? = nil, components: LogComponents) -> Self {
        var mutableColors = [(foreground: Color?, background: Color?)](count: PriorityLevel.numberOfLevels, repeatedValue: (foreground: nil, background: nil))
        
        if let foregroundColors = foreground {
            for (level, color) in foregroundColors {
                mutableColors[level.rawValue].foreground = color
            }
        }
        
        if let backgroundColors = background {
            for (level, color) in backgroundColors {
                mutableColors[level.rawValue].background = color
            }
        }
        
        return Self(colors: mutableColors, components: components)
    }
}