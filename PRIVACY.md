# Privacy Policy

**Effective date:** 2026-03-06

Tattoo is an open-source, third-party mobile application designed for National Taipei University of Technology (NTUT) students. It is developed by NPC (NTUT Programming Club) and is not affiliated with or endorsed by NTUT. This policy describes how the app collects, processes, uses, and protects your personal data.

## 1. Scope of This Policy

This policy applies to the collection, processing, use, and protection of personal data when you use this app. It does not apply to other systems or websites linked from this app (including NTUT's own service systems). When you access other systems through this app, the privacy policies of those systems apply.

## 2. Collection, Processing, and Use of Personal Data

When you use this app, we collect, process, and use the following data:

### (1) NTUT Credentials

Your student ID and password are required to access NTUT services on your behalf. Credentials are:

- Stored locally on your device using platform-secure storage (Keychain on iOS, EncryptedSharedPreferences on Android)
- Sent only to official NTUT servers (`ntut.edu.tw`) to authenticate your session
- Never transmitted to any server operated by us

### (2) Academic and Personal Data

After authentication, the app retrieves your academic data from NTUT systems, including course, grade, and profile information. This data is cached in a local database on your device to reduce network requests. It is not sent to any external service.

### (3) Preferences

App settings (display preferences, theme, language) are stored locally on your device.

## 3. Data Protection

All personal data (credentials, academic records, preferences) is stored locally on your device. Credentials are protected by platform-level encryption and are accessible only to you. You can delete all stored data at any time by clearing the app's data or uninstalling it.

This app does not operate any backend server. We do not collect, store, or process your data on any server we control.

## 4. Sharing of Personal Data with Third Parties

This app will never provide, exchange, rent, or sell any of your personal data to any individual, organization, private enterprise, or government agency.

This app uses the following third-party services:

### (1) Firebase (Release Builds Only)

Release builds of the app may include Firebase Analytics and Firebase Crashlytics, provided by Google. When enabled, these services collect:

- **Crashlytics:** Crash reports, device model, OS version, and app state at the time of a crash
- **Analytics:** Anonymous usage events (e.g., screen views) and device information

Firebase data collection is controlled by a compile-time flag and is disabled in debug builds. Firebase is governed by [Google's Privacy Policy](https://policies.google.com/privacy).

### (2) GitHub

The app fetches contributor data from the GitHub API for the "About" screen. This request does not include any personal information.

## 5. External Links

This app links to NTUT's service systems and other external websites. Those linked sites are not governed by this privacy policy. You should refer to the privacy policies of each respective site.

## 6. Exercising Your Data Rights

Under Taiwan's Personal Data Protection Act, you may exercise the following rights:

- Request access to or review of your personal data
- Request correction or supplementation
- Request cessation of collection, processing, or use
- Request deletion

Since all data is stored locally on your device, you can exercise any of the above rights at any time by clearing the app's data or uninstalling it.

## 7. NTUT's Privacy Practices

Your data on NTUT's servers is subject to NTUT's own privacy policy and Taiwan's Personal Data Protection Act. This app acts as a client to those services and does not control how NTUT handles your data.

## 8. Children's Privacy

This app is intended for university students and is not directed at children under 13.

## 9. Changes to This Policy

This privacy policy may be revised as needed. Updated terms will be committed to this repository, and the effective date at the top will be revised accordingly.

## 10. Contact

For questions or concerns about this policy, open an issue at [github.com/NTUT-NPC/tattoo](https://github.com/NTUT-NPC/tattoo/issues).
