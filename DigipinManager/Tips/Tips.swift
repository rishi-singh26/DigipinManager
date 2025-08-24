//
//  Tips.swift
//  DigipinManager
//
//  Created by Rishi Singh on 23/08/25.
//


import TipKit

struct CopyToClipboardTip: Tip {
    @Parameter
    static var show: Bool = false
    
    var title: Text {
        Text("Copy DIGIPIN")
    }
    
    var message: Text? {
        Text("Click on the DIGIPIN to copy to clipboard.")
    }
    
    var image: Image? {
        Image(systemName: "document.on.document")
    }
    
    var rules: [Rule] {
        // Define a rule based on the app state.
        #Rule(Self.$show) {
            // Set the conditions for when the tip displays.
            $0 == true
        }
    }
}

struct AddToPinnedListTip: Tip {
    @Parameter
    static var show: Bool = false
    
    var title: Text {
        Text("Add to Pinned List")
    }
    
    var message: Text? {
        Text("Tap on the Pin button to pin the scoped location to Pinned List.")
    }
    
    var image: Image? {
        Image(systemName: "pin")
    }
    
    var rules: [Rule] {
        // Define a rule based on the app state.
        #Rule(Self.$show) {
            // Set the conditions for when the tip displays.
            $0 == true
        }
    }
}

struct ScopeTip: Tip {
    @Parameter
    static var show: Bool = false
    
    var title: Text {
        Text("Location Scope")
    }
    
    var message: Text? {
        Text("The DIGIPIN for the location under the scope icon is shown in the bottom sheet below.")
    }
    
    var image: Image? {
        Image(systemName: "scope")
    }
    
    var rules: [Rule] {
        // Define a rule based on the app state.
        #Rule(Self.$show) {
            // Set the conditions for when the tip displays.
            $0 == true
        }
    }
}
