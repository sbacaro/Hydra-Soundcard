import SwiftUI

struct LicenseView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("License Agreement")
                .font(.system(size: 22, weight: .semibold))

            Text("Please review the following GNU General Public License terms before proceeding.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            ScrollView {
                Text(licenseText)
                    .font(.system(.body, design: .monospaced))
                    .font(.system(size: 11))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )

            Toggle(isOn: $state.licenseAccepted) {
                Text("I agree to the terms of the license agreement.")
                    .font(.system(size: 13))
            }
            .toggleStyle(.checkbox)
        }
    }

    private var licenseText: String {
        if let url = Bundle.main.url(forResource: "LICENSE", withExtension: nil),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            return text
        }
        return """
        GNU GENERAL PUBLIC LICENSE
        Version 3, 29 June 2007

        Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
        Everyone is permitted to copy and distribute verbatim copies
        of this license document, but changing it is not allowed.

        Preamble
        The GNU General Public License is a free, copyleft license for software and other kinds of works...
        """
    }
}
