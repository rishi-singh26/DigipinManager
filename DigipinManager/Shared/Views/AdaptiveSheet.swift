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
                AdaptiveSheetHelper(width: width, isActive: isActive)
            }
    }
}

fileprivate struct AdaptiveSheetHelper: UIViewControllerRepresentable {
    var width: CGFloat
    var isActive: Bool

    func makeUIViewController(context: Context) -> AdaptiveSheetContainerController {
        let controller = AdaptiveSheetContainerController()
        controller.view.backgroundColor = .clear
        controller.width = width
        controller.isActive = isActive
        return controller
    }

    func updateUIViewController(_ uiViewController: AdaptiveSheetContainerController, context: Context) {
        uiViewController.width = width
        uiViewController.setActive(isActive)
    }
}

/// Applying the width-limiting constraints from `viewWillLayoutSubviews` (instead of
/// `DispatchQueue.main.async`) ensures they land before the sheet's first frame is painted,
/// so the sheet is already leading-aligned when it appears instead of visibly jumping there
/// from a center-aligned first frame.
fileprivate class AdaptiveSheetContainerController: UIViewController {
    var width: CGFloat = 0
    var isActive: Bool = false
    private var hasAppliedInitialLayout = false

    func setActive(_ newValue: Bool) {
        let changed = isActive != newValue
        isActive = newValue
        guard hasAppliedInitialLayout, changed else { return }
        applyConstraints(animated: true)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard !hasAppliedInitialLayout,
              sheetPresentationController?.containerView != nil,
              view.window != nil else {
            return
        }
        hasAppliedInitialLayout = true
        applyConstraints(animated: false)
    }

    private func applyConstraints(animated: Bool) {
        guard let sheetController = sheetPresentationController,
              let sheet = sheetController.containerView,
              let window = view.window else {
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

        let updates = { [isActive, width] in
            if isActive {
                // Adding Set of constraints to limit the sheet container view's width, this automatically pushes it towards the leading side without any additional code.
                sheet.translatesAutoresizingMaskIntoConstraints = false

                NSLayoutConstraint.activate([
                    sheet.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                    sheet.topAnchor.constraint(equalTo: window.topAnchor),
                    sheet.bottomAnchor.constraint(equalTo: window.bottomAnchor),
                    sheet.widthAnchor.constraint(lessThanOrEqualToConstant: width),
                    sheet.widthAnchor.constraint(equalTo: window.widthAnchor).priority(.defaultHigh)
                ])
            } else {
                // Resetting Layout Constraints
                sheet.translatesAutoresizingMaskIntoConstraints = true
                sheet.frame = window.frame
                sheet.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            }
        }

        if animated {
            sheetController.animateChanges(updates)
        } else {
            updates()
        }
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
