//
//  AdaptiveSheet.swift
//  TesterApp
//
//  Created by Rishi Singh on 23/07/26.
//

import SwiftUI
import SwiftData

extension View {
    
    @ViewBuilder
    func adaptiveSheet(_ width: CGFloat, isActive: Bool) -> some View {
        self
            .background {
                if isActive {
                    AdaptiveSheetHelper(width: width, isActive: true)
                } else {
                    AdaptiveSheetHelper(width: width, isActive: false)
                }
            }
    }
}

fileprivate struct AdaptiveSheetHelper: UIViewControllerRepresentable {
    var width: CGFloat
    var isActive: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        
        DispatchQueue.main.async {
            if let sheetController = controller.sheetPresentationController {
                guard let sheet = sheetController.containerView,
                      let window = controller.view.window else {
                    return
                }
                
                // Finding the Background View and setting clear background!
                if let backgroundView = sheet.subviews.first(where: {
                    $0.subviews.contains(where: { $0.backgroundColor != nil })
                }) {
                    // Clearing Background Color
                    for subview in backgroundView.subviews {
                        subview.backgroundColor = .clear
                    }
                }
                
                // Animating it inside sheet animations
                sheetController.animateChanges {
                    if isActive {
                        // Adding Set of constraints to limit the sheet container view's width, this it automatically pushes towards leading side without any additional code.
                        sheet.translatesAutoresizingMaskIntoConstraints = false
                        
                        NSLayoutConstraint.activate([
                            sheet.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                            sheet.topAnchor.constraint(equalTo: window.topAnchor),
                            sheet.bottomAnchor.constraint(equalTo: window.bottomAnchor),
                            sheet.widthAnchor.constraint(lessThanOrEqualToConstant: width),
                            sheet.widthAnchor.constraint(equalTo: window.widthAnchor).priority(.defaultHigh)
                        ])
                    } else {
                        // Resetting Lauout Contraints
                        sheet.translatesAutoresizingMaskIntoConstraints = true
                        sheet.frame = window.frame
                        sheet.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    }
                }
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}

extension NSLayoutConstraint {
    func priority(_ value: UILayoutPriority) -> Self {
        self.priority = value
        return self
    }
}

#Preview {
    @Previewable @State var container: ModelContainer = {
        let container = try! ModelContainer(for: DPItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        // Add sample data
        let sampleDPItems = [
            DPItem(pin: "4P3-33C-4635", address: "Address Data", latitude: 13.006003, longitude: 77.751144),
            DPItem(pin: "4P3-33C-5MMJ", address: "Address Data", latitude: 13.005222, longitude: 77.752166),
            DPItem(pin: "4P3-33C-P7JF", address: "Address Data", latitude: 13.004407, longitude: 77.753131),
            DPItem(pin: "4P3-33C-T9MF", address: "Address Data", latitude: 13.004709, longitude: 77.754909)
        ]
        
        for item in sampleDPItems {
            container.mainContext.insert(item)
        }
        
        return container
    }()
    
    ContentView()
        .environmentObject(AppController.shared)
        .environmentObject(MapController.shared)
        .environmentObject(MapViewModel.shared)
        .environmentObject(LocationManager.shared)
        .environmentObject(InAppNotificationManager.shared)
        .modelContainer(container)
}
