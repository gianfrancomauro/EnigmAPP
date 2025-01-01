import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Last updated: 04/09/2024")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("This Privacy Policy describes how your personal information is collected, used, and shared when you use our EnigmApp.")
                    
                    Text("Information We Collect")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("We do not collect any personal information from you when you use our app. The app operates entirely on your device and does not transmit any data to external servers.")
                    
                    Text("How We Use Your Information")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Since we do not collect any personal information, we do not use your data for any purpose.")
                    
                    Text("Changes to This Privacy Policy")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("We may update this privacy policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.")
                    
                    Text("Contact Us")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("If you have any questions about this Privacy Policy, please contact us at:")
                    Text("Email: [Your Contact Email]")
                    Text("Address: [Your Company Address]")
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
    }
}