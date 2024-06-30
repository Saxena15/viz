//
//  vizApp.swift
//  viz
//
//  Created by Akash Saxena on 28/06/24.
//

import SwiftUI

@main
struct vizApp: App {
    @Environment(\.scenePhase) var scenePhase
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        
        WindowGroup {
            Home()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
               
        }.onChange(of: scenePhase) { _ in
            persistenceController.save()
        }
    }
}
