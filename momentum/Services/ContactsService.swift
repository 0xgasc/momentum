import Foundation
@preconcurrency import Contacts
import SwiftUI
import Combine

// MARK: - Contacts Service
@MainActor
class ContactsService: ObservableObject {
    @Published var authorizationStatus: CNAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let store = CNContactStore()

    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization
    func checkAuthorizationStatus() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            authorizationStatus = granted ? .authorized : .denied
            return granted
        } catch {
            errorMessage = error.localizedDescription
            authorizationStatus = .denied
            return false
        }
    }

    var isAuthorizedOrLimited: Bool {
        if #available(iOS 18.0, *) {
            return authorizationStatus == .authorized || authorizationStatus == .limited
        }
        return authorizationStatus == .authorized
    }

    // MARK: - Fetch Contacts
    func fetchContacts(matching name: String? = nil) async -> [ContactInfo] {
        guard isAuthorizedOrLimited else {
            return []
        }

        isLoading = true
        defer { isLoading = false }

        let store = self.store
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = Self.performFetch(store: store, name: name)
                continuation.resume(returning: result)
            }
        }
    }

    private nonisolated static func performFetch(store: CNContactStore, name: String?) -> [ContactInfo] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactJobTitleKey as CNKeyDescriptor
        ]

        var contacts: [ContactInfo] = []

        do {
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)

            if let name = name, !name.isEmpty {
                request.predicate = CNContact.predicateForContacts(matchingName: name)
            }

            try store.enumerateContacts(with: request) { contact, _ in
                let info = ContactInfo(
                    id: contact.identifier,
                    firstName: contact.givenName,
                    lastName: contact.familyName,
                    organization: contact.organizationName,
                    jobTitle: contact.jobTitle,
                    phoneNumber: contact.phoneNumbers.first?.value.stringValue,
                    email: contact.emailAddresses.first?.value as String?,
                    thumbnailData: contact.thumbnailImageData
                )
                contacts.append(info)
            }
        } catch {
            return []
        }

        // Sort by name
        return contacts.sorted {
            let a = "\($0.firstName) \($0.lastName)".trimmingCharacters(in: .whitespaces)
            let b = "\($1.firstName) \($1.lastName)".trimmingCharacters(in: .whitespaces)
            return a < b
        }
    }

    func searchContacts(query: String) async -> [ContactInfo] {
        guard !query.isEmpty else { return [] }
        return await fetchContacts(matching: query)
    }
}

// MARK: - Contact Info
struct ContactInfo: Identifiable, Hashable {
    let id: String
    let firstName: String
    let lastName: String
    let organization: String
    let jobTitle: String
    let phoneNumber: String?
    let email: String?
    let thumbnailData: Data?

    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var initials: String {
        let first = firstName.first.map { String($0) } ?? ""
        let last = lastName.first.map { String($0) } ?? ""
        let result = (first + last).uppercased()
        return result.isEmpty ? "?" : result
    }

    // Suggest relationship category based on contact info
    var suggestedCategory: RelationshipCategory {
        let jobTitle = self.jobTitle.lowercased()
        let org = self.organization.lowercased()

        if jobTitle.contains("mentor") || jobTitle.contains("coach") {
            return .mentor
        } else if jobTitle.contains("ceo") || jobTitle.contains("founder") || jobTitle.contains("director") {
            return .aspirational
        } else if !org.isEmpty {
            return .professional
        } else {
            return .personal
        }
    }
}

// MARK: - Contact Picker View
struct ContactPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var contactsService = ContactsService()

    @State private var searchText = ""
    @State private var contacts: [ContactInfo] = []
    @State private var isSearching = false

    let onSelect: (ContactInfo) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Authorization state
                if !contactsService.isAuthorizedOrLimited {
                    ContactsPermissionView(contactsService: contactsService)
                } else {
                    // Search bar
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.momentum.gray)

                        TextField("Search contacts...", text: $searchText)
                            .font(.bodyMedium)
                            .autocorrectionDisabled()

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.momentum.gray)
                            }
                        }
                    }
                    .padding(Spacing.md)
                    .background(Color.momentum.cream)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                    .padding(Spacing.md)

                    // Results
                    if isSearching {
                        ProgressView()
                            .padding(Spacing.xl)
                        Spacer()
                    } else if contacts.isEmpty && !searchText.isEmpty {
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "person.slash")
                                .font(.system(size: 40))
                                .foregroundColor(Color.momentum.gray.opacity(0.5))

                            Text("No contacts found")
                                .font(.bodyMedium)
                                .foregroundColor(Color.momentum.gray)
                        }
                        .padding(Spacing.xl)
                        Spacer()
                    } else if contacts.isEmpty {
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 40))
                                .foregroundColor(Color.momentum.sage.opacity(0.5))

                            Text("No contacts found. Try searching by name.")
                                .font(.bodyMedium)
                                .foregroundColor(Color.momentum.gray)
                        }
                        .padding(Spacing.xl)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Spacing.xs) {
                                ForEach(contacts) { contact in
                                    ContactRow(contact: contact) {
                                        onSelect(contact)
                                        dismiss()
                                    }
                                }
                            }
                            .padding(Spacing.md)
                        }
                    }
                }
            }
            .background(Color.momentum.white.ignoresSafeArea())
            .navigationTitle("Import from Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                // Load all contacts on appear
                if contactsService.isAuthorizedOrLimited {
                    isSearching = true
                    contacts = await contactsService.fetchContacts()
                    isSearching = false
                }
            }
            .onChange(of: searchText) { _, newValue in
                Task {
                    isSearching = true
                    if newValue.isEmpty {
                        contacts = await contactsService.fetchContacts()
                    } else {
                        contacts = await contactsService.searchContacts(query: newValue)
                    }
                    isSearching = false
                }
            }
            .onChange(of: contactsService.authorizationStatus) { _, _ in
                // Reload contacts after permission granted
                if contactsService.isAuthorizedOrLimited {
                    Task {
                        isSearching = true
                        contacts = await contactsService.fetchContacts()
                        isSearching = false
                    }
                }
            }
        }
    }
}

// MARK: - Contact Row
struct ContactRow: View {
    let contact: ContactInfo
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                // Avatar
                if let imageData = contact.thumbnailData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(contact.suggestedCategory.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(contact.initials)
                                .font(.titleSmall)
                                .foregroundColor(contact.suggestedCategory.color)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.fullName)
                        .font(.titleSmall)
                        .foregroundColor(Color.momentum.charcoal)

                    if !contact.organization.isEmpty {
                        Text(contact.organization)
                            .font(.caption)
                            .foregroundColor(Color.momentum.gray)
                    }
                }

                Spacer()

                // Suggested category badge
                Text(contact.suggestedCategory.displayName)
                    .font(.caption)
                    .foregroundColor(contact.suggestedCategory.color)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(contact.suggestedCategory.color.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(Spacing.md)
            .background(Color.momentum.cream.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }
}

// MARK: - Permission View
struct ContactsPermissionView: View {
    @ObservedObject var contactsService: ContactsService

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(Color.momentum.coral)

            VStack(spacing: Spacing.sm) {
                Text("Connect Your Contacts")
                    .font(.displaySmall)
                    .foregroundColor(Color.momentum.charcoal)

                Text("Import people directly from your contacts to easily track your relationships and stay connected.")
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.gray)
                    .multilineTextAlignment(.center)
            }

            if contactsService.authorizationStatus == .denied {
                VStack(spacing: Spacing.sm) {
                    Text("Contacts access was denied")
                        .font(.bodySmall)
                        .foregroundColor(Color.momentum.coral)

                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.bodySmall)
                    .foregroundColor(Color.momentum.plum)
                }
            } else {
                MomentumButton("Allow Access", icon: "person.crop.circle.badge.checkmark") {
                    Task {
                        await contactsService.requestAccess()
                    }
                }
            }

            Spacer()
        }
        .padding(Spacing.xl)
    }
}
