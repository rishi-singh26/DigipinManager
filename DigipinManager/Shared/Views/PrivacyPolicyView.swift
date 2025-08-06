//
//  PrivacyPolicyView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 04/08/25.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                Text("Digipin Manager Privacy Policy")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                Text("Effective Date: 6th August, 2025")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Group {
                    Text("1. No Data Collection")
                        .font(.title2)
                        .bold()
                    Text("We do not collect, store, or share any personal information or user data.")
                    BulletPoint("The app does not include analytics, tracking technologies, or third-party advertising.")
                    BulletPoint("No personally identifiable information (PII) is collected from your device or account.")
                }
                
                Group {
                    Text("2. Local and Cloud Data Storage")
                        .font(.title2)
                        .bold()
                    Text("The app uses SwiftData and CloudKit to store your DIGIPIN data.")
                    BulletPoint("Your data is stored locally on your device and optionally synced to your private iCloud account using CloudKit.")
                    BulletPoint("We do not have access to any data stored in your iCloud account.")
                    BulletPoint("All data synced to iCloud is governed by Apple’s iCloud privacy policies.")
                }
                
                Group {
                    Text("3. Security")
                        .font(.title2)
                        .bold()
                    Text("All data is stored securely using the platform features provided by Apple (SwiftData, CloudKit, and iCloud). We rely on Apple’s built-in security to protect your information on-device and in the cloud.")
                }
                
                Group {
                    Text("4. Children’s Privacy")
                        .font(.title2)
                        .bold()
                    Text("This app does not collect data from children under the age of 13. As no personal data is collected, it complies with privacy laws applicable to children.")
                }
                
                Group {
                    Text("5. Changes to This Policy")
                        .font(.title2)
                        .bold()
                    Text("This Privacy Policy may be updated at any time without prior notice. Any revisions will be posted with an updated effective date. Continued use of the application signifies your acceptance of any changes.")
                }
                
                Group {
                    Text("6. Contact")
                        .font(.title2)
                        .bold()
                    Text("If you have any questions about this privacy policy, you may contact us at:")
                    Text("Email: [email@rishisingh.in](mailto:email@rishisingh.in)")
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct BulletPoint: View {
    var text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .fontWeight(.bold)
            Text(text)
        }
        .padding(.leading, 10)
    }
}

#Preview {
    PrivacyPolicyView()
}
