//
//  AnandaAI_Watch_AppApp.swift
//  AnandaAI Watch App Watch App
//
//  Created by Diya Maria on 05/11/24.
//

import SwiftUI
import WatchConnectivity

//@main
//struct AnandaAI_Watch_App_Watch_AppApp: App {
//    
//    var body: some Scene {
//        WindowGroup {
//            WatchAccelerometerView()
//        }
//    }
//}
//    var body: some Scene {
//        WindowGroup {
//            WatchAccelerometerView()
//        }
//    }



@main
struct AnandaAIApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                MainMenuView()
            }
        }
    }
}

