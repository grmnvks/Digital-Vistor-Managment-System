
import SwiftUI
import Combine
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

// MARK: - CU THEME

enum CUTheme {
    static let red = Color(red: 0.72, green: 0.04, blue: 0.12)
    static let darkRed = Color(red: 0.48, green: 0.02, blue: 0.08)
    static let lightRed = Color(red: 1.0, green: 0.93, blue: 0.94)
    static let background = Color.white
    static let text = Color(red: 0.12, green: 0.12, blue: 0.15)
    static let secondary = Color.gray
}

// MARK: - USER ROLES

enum UserRole: String {
    case security = "Security"
    case faculty = "Faculty"
}

struct AppUser {
    let ecode: String
    let password: String
    let name: String
    let role: UserRole
}

// MARK: - STUDENT MODEL

struct Student: Identifiable, Codable {
    var id: String
    var name: String
    var branch: String
    var year: String
}

// MARK: - APPOINTMENT MODEL

struct Appointment: Identifiable, Codable {
    var id: String
    var visitorName: String
    var phone: String
    var purpose: String
    var facultyEcode: String
    var facultyName: String
    var date: Date
    var approved: Bool
    var checkedIn: Bool
    var checkedOut: Bool
}

// MARK: - VISITOR MODEL

struct Visitor: Identifiable, Codable {
    var id: String
    var name: String
    var phone: String
    var purpose: String
    var host: String
    var date: Date
    var approved: Bool
    var checkedIn: Bool
    var checkedOut: Bool
}

// MARK: - STUDENT ATTENDANCE MODEL

struct StudentAttendance: Identifiable, Codable {
    var id: UUID
    var studentUID: String
    var studentName: String
    var branch: String
    var year: String
    var purpose: String
    var time: Date
    var checkedOut: Bool
}

// MARK: - SECURITY EVENT MODEL

struct SecurityEvent: Identifiable, Codable {
    var id: UUID
    var title: String
    var details: String
    var time: Date
}

// MARK: - APP STORE

@MainActor
final class AppStore: ObservableObject {

    @Published var currentUser: AppUser?

    @Published var appointments: [Appointment] = []
    @Published var visitors: [Visitor] = []
    @Published var attendance: [StudentAttendance] = []
    @Published var events: [SecurityEvent] = []

    @Published var emergencyMode = false

    @Published var students: [Student] = [
        Student(
            id: "CU2024001",
            name: "Gurmanveer",
            branch: "Computer Science",
            year: "2024"
        ),
        Student(
            id: "CU2024002",
            name: "Priyanka",
            branch: "Computer Science",
            year: "2024"
        ),
        Student(
            id: "CU2024003",
            name: "Kashish",
            branch: "Computer Science",
            year: "2024"
        ),
        Student(
            id: "CU2024004",
            name: "Akshita",
            branch: "Computer Science",
            year: "2024"
        )
    ]

    // DEMONSTRATION ACCOUNTS
    // These are sample credentials, not university accounts.

    private let users: [AppUser] = [
        AppUser(
            ecode: "SEC001",
            password: "1234",
            name: "Security Guard",
            role: .security
        ),
        AppUser(
            ecode: "FAC001",
            password: "1234",
            name: "Faculty Member",
            role: .faculty
        )
    ]

    init() {
        loadData()
    }

    // MARK: LOGIN

    func login(
        ecode: String,
        password: String
    ) -> Bool {

        guard let user = users.first(where: {
            $0.ecode.lowercased() == ecode.lowercased()
            && $0.password == password
        }) else {
            return false
        }

        currentUser = user

        addEvent(
            title: "User Login",
            details: "\(user.name) logged in."
        )

        return true
    }

    func logout() {
        if let user = currentUser {
            addEvent(
                title: "User Logout",
                details: "\(user.name) logged out."
            )
        }

        currentUser = nil
    }

    // MARK: PERSISTENCE

    func loadData() {
        let decoder = JSONDecoder()

        if let data = UserDefaults.standard.data(
            forKey: "CU_Appointments"
        ),
        let saved = try? decoder.decode(
            [Appointment].self,
            from: data
        ) {
            appointments = saved
        }

        if let data = UserDefaults.standard.data(
            forKey: "CU_Visitors"
        ),
        let saved = try? decoder.decode(
            [Visitor].self,
            from: data
        ) {
            visitors = saved
        }

        if let data = UserDefaults.standard.data(
            forKey: "CU_Attendance"
        ),
        let saved = try? decoder.decode(
            [StudentAttendance].self,
            from: data
        ) {
            attendance = saved
        }

        if let data = UserDefaults.standard.data(
            forKey: "CU_Events"
        ),
        let saved = try? decoder.decode(
            [SecurityEvent].self,
            from: data
        ) {
            events = saved
        }

        emergencyMode = UserDefaults.standard.bool(
            forKey: "CU_Emergency"
        )
    }

    func saveData() {
        let encoder = JSONEncoder()

        if let data = try? encoder.encode(appointments) {
            UserDefaults.standard.set(
                data,
                forKey: "CU_Appointments"
            )
        }

        if let data = try? encoder.encode(visitors) {
            UserDefaults.standard.set(
                data,
                forKey: "CU_Visitors"
            )
        }

        if let data = try? encoder.encode(attendance) {
            UserDefaults.standard.set(
                data,
                forKey: "CU_Attendance"
            )
        }

        if let data = try? encoder.encode(events) {
            UserDefaults.standard.set(
                data,
                forKey: "CU_Events"
            )
        }

        UserDefaults.standard.set(
            emergencyMode,
            forKey: "CU_Emergency"
        )
    }

    // MARK: APPOINTMENTS

    func createAppointment(
        visitorName: String,
        phone: String,
        purpose: String,
        date: Date
    ) {

        guard let user = currentUser,
              user.role == .faculty else {
            return
        }

        let appointment = Appointment(
            id: UUID().uuidString,
            visitorName: visitorName,
            phone: phone,
            purpose: purpose,
            facultyEcode: user.ecode,
            facultyName: user.name,
            date: date,
            approved: true,
            checkedIn: false,
            checkedOut: false
        )

        appointments.insert(
            appointment,
            at: 0
        )

        addEvent(
            title: "Appointment Created",
            details: "\(visitorName) - \(user.name)"
        )

        saveData()
    }

    func updateAppointmentCheckIn(
        _ appointment: Appointment
    ) {

        guard let index = appointments.firstIndex(
            where: { $0.id == appointment.id }
        ) else {
            return
        }

        appointments[index].checkedIn = true
        appointments[index].checkedOut = false

        addEvent(
            title: "Appointment Check-In",
            details: "\(appointment.visitorName) checked in."
        )

        saveData()
    }

    func updateAppointmentCheckOut(
        _ appointment: Appointment
    ) {

        guard let index = appointments.firstIndex(
            where: { $0.id == appointment.id }
        ) else {
            return
        }

        appointments[index].checkedIn = false
        appointments[index].checkedOut = true

        addEvent(
            title: "Appointment Check-Out",
            details: "\(appointment.visitorName) checked out."
        )

        saveData()
    }

    // MARK: VISITOR REGISTRATION

    func registerVisitor(
        name: String,
        phone: String,
        purpose: String,
        host: String
    ) {

        let visitor = Visitor(
            id: UUID().uuidString,
            name: name,
            phone: phone,
            purpose: purpose,
            host: host,
            date: Date(),
            approved: true,
            checkedIn: false,
            checkedOut: false
        )

        visitors.insert(visitor, at: 0)

        addEvent(
            title: "Visitor Registered",
            details: "\(name) registered by security."
        )

        saveData()
    }

    func visitorCheckIn(_ visitor: Visitor) {

        guard let index = visitors.firstIndex(
            where: { $0.id == visitor.id }
        ) else {
            return
        }

        visitors[index].checkedIn = true
        visitors[index].checkedOut = false

        addEvent(
            title: "Visitor Check-In",
            details: "\(visitor.name) entered campus."
        )

        saveData()
    }

    func visitorCheckOut(_ visitor: Visitor) {

        guard let index = visitors.firstIndex(
            where: { $0.id == visitor.id }
        ) else {
            return
        }

        visitors[index].checkedIn = false
        visitors[index].checkedOut = true

        addEvent(
            title: "Visitor Check-Out",
            details: "\(visitor.name) exited campus."
        )

        saveData()
    }

    // MARK: STUDENT CHECK-IN

    func findStudent(uid: String) -> Student? {
        students.first {
            $0.id.lowercased() == uid
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .lowercased()
        }
    }

    func studentCheckIn(
        student: Student,
        purpose: String
    ) {

        let record = StudentAttendance(
            id: UUID(),
            studentUID: student.id,
            studentName: student.name,
            branch: student.branch,
            year: student.year,
            purpose: purpose,
            time: Date(),
            checkedOut: false
        )

        attendance.insert(record, at: 0)

        addEvent(
            title: "Student Check-In",
            details: "\(student.name) (\(student.id))"
        )

        saveData()
    }

    func studentCheckOut(
        _ record: StudentAttendance
    ) {

        guard let index = attendance.firstIndex(
            where: { $0.id == record.id }
        ) else {
            return
        }

        attendance[index].checkedOut = true

        addEvent(
            title: "Student Check-Out",
            details: "\(record.studentName) checked out."
        )

        saveData()
    }

    // MARK: EVENTS

    func addEvent(
        title: String,
        details: String
    ) {

        let event = SecurityEvent(
            id: UUID(),
            title: title,
            details: details,
            time: Date()
        )

        events.insert(event, at: 0)

        if events.count > 500 {
            events = Array(events.prefix(500))
        }

        saveData()
    }

    // MARK: EMERGENCY

    func toggleEmergency() {

        emergencyMode.toggle()

        addEvent(
            title: emergencyMode
                ? "Emergency Activated"
                : "Emergency Deactivated",
            details: "Emergency mode changed by \(currentUser?.name ?? "Security")."
        )

        saveData()
    }
}

// MARK: - ROOT VIEW

struct ContentView: View {

    @StateObject private var store = AppStore()

    var body: some View {

        Group {

            if let user = store.currentUser {

                DashboardView(
                    store: store,
                    user: user
                )

            } else {

                LoginView(store: store)
            }
        }
        .preferredColorScheme(.light)
        .tint(CUTheme.red)
    }
}

// MARK: - LOGIN SCREEN

struct LoginView: View {

    @ObservedObject var store: AppStore

    @State private var ecode = ""
    @State private var password = ""
    @State private var errorMessage = ""

    var body: some View {

        NavigationStack {

            ZStack {

                CUTheme.background
                    .ignoresSafeArea()

                ScrollView {

                    VStack(spacing: 25) {

                        Spacer(minLength: 30)

                        // CU LOGO AREA

                        VStack(spacing: 12) {

                            ZStack {

                                RoundedRectangle(
                                    cornerRadius: 24
                                )
                                .fill(CUTheme.red)
                                .frame(
                                    width: 100,
                                    height: 100
                                )

                                Image(
                                    systemName: "building.2.crop.circle.fill"
                                )
                                .font(.system(size: 52))
                                .foregroundColor(.white)
                            }

                            Text("CU DIGITAL")
                                .font(
                                    .system(
                                        size: 25,
                                        weight: .black
                                    )
                                )
                                .foregroundColor(CUTheme.red)

                            Text(
                                "VISITOR MANAGEMENT SYSTEM"
                            )
                            .font(
                                .system(
                                    size: 16,
                                    weight: .bold
                                )
                            )
                            .multilineTextAlignment(.center)
                            .foregroundColor(CUTheme.text)

                            Text(
                                "CHANDIGARH UNIVERSITY"
                            )
                            .font(
                                .system(
                                    size: 12,
                                    weight: .semibold
                                )
                            )
                            .tracking(2)
                            .foregroundColor(CUTheme.secondary)
                        }

                        VStack(
                            alignment: .leading,
                            spacing: 18
                        ) {

                            Text("Welcome Back")
                                .font(.title2.bold())
                                .foregroundColor(CUTheme.text)

                            Text(
                                "Sign in using your authorized Ecode."
                            )
                            .font(.subheadline)
                            .foregroundColor(CUTheme.secondary)

                            VStack(
                                alignment: .leading,
                                spacing: 8
                            ) {

                                Text("University Ecode")
                                    .font(.subheadline.bold())
                                    .foregroundColor(CUTheme.text)

                                TextField(
                                    "Enter Ecode",
                                    text: $ecode
                                )
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding()
                                .background(
                                    Color.gray.opacity(0.08)
                                )
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 12
                                    )
                                )
                            }

                            VStack(
                                alignment: .leading,
                                spacing: 8
                            ) {

                                Text("Password")
                                    .font(.subheadline.bold())
                                    .foregroundColor(CUTheme.text)

                                SecureField(
                                    "Enter password",
                                    text: $password
                                )
                                .padding()
                                .background(
                                    Color.gray.opacity(0.08)
                                )
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 12
                                    )
                                )
                            }

                            if !errorMessage.isEmpty {

                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(CUTheme.red)
                            }

                            Button {

                                let success = store.login(
                                    ecode: ecode,
                                    password: password
                                )

                                if !success {
                                    errorMessage =
                                        "Invalid Ecode or password."
                                } else {
                                    errorMessage = ""
                                }

                            } label: {

                                HStack {

                                    Spacer()

                                    Text("SIGN IN")
                                        .font(
                                            .headline.bold()
                                        )

                                    Image(
                                        systemName: "arrow.right"
                                    )

                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(CUTheme.red)
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 14
                                    )
                                )
                            }
                            .buttonStyle(.plain)

                            VStack(spacing: 6) {

                                Text("DEMO CREDENTIALS")
                                    .font(
                                        .caption.bold()
                                    )
                                    .foregroundColor(CUTheme.red)

                                Text(
                                    "Security: SEC001 / 1234"
                                )

                                Text(
                                    "Faculty: FAC001 / 1234"
                                )
                            }
                            .font(.caption)
                            .foregroundColor(CUTheme.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(CUTheme.lightRed)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 14
                                )
                            )
                        }
                        .padding(22)
                        .background(.white)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 24
                            )
                        )
                        .overlay {
                            RoundedRectangle(
                                cornerRadius: 24
                            )
                            .stroke(
                                CUTheme.lightRed,
                                lineWidth: 1
                            )
                        }

                        Text(
                            "Authorized Personnel Only"
                        )
                        .font(.caption)
                        .foregroundColor(CUTheme.secondary)

                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - DASHBOARD

struct DashboardView: View {

    @ObservedObject var store: AppStore

    let user: AppUser

    @State private var selectedTab = 0

    private var tabs: [(String, String)] {

        if user.role == .security {

            return [
                ("Dashboard", "house.fill"),
                ("Students", "person.fill"),
                ("Appointments", "calendar"),
                ("Visitors", "person.badge.plus"),
                ("Events", "video.fill")
            ]

        } else {

            return [
                ("Dashboard", "house.fill"),
                ("Generate", "calendar.badge.plus"),
                ("Appointments", "calendar"),
                ("Status", "person.crop.rectangle"),
                ("Events", "clock.fill")
            ]
        }
    }

    private var dashboardTitle: String {

        user.role == .security
            ? "Security Dashboard"
            : "Teacher Appointment Dashboard"
    }

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                // TOP HEADER

                HStack(spacing: 10) {

                    Image(
                        systemName: "shield.lefthalf.filled"
                    )
                    .font(.title2)
                    .foregroundColor(.white)

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {

                        Text(dashboardTitle)
                            .font(
                                .system(
                                    size: 15,
                                    weight: .bold
                                )
                            )
                            .foregroundColor(.white)

                        Text(user.name)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.85))
                    }

                    Spacer()

                    Button {

                        store.logout()

                    } label: {

                        Image(
                            systemName: "rectangle.portrait.and.arrow.right"
                        )
                        .font(.title3)
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(CUTheme.red)

                // EMERGENCY BANNER

                if store.emergencyMode {

                    HStack {

                        Image(
                            systemName: "exclamationmark.triangle.fill"
                        )

                        Text("CAMPUS EMERGENCY ACTIVE")
                            .font(.caption.bold())

                        Spacer()
                    }
                    .padding(12)
                    .foregroundColor(.white)
                    .background(CUTheme.darkRed)
                }

                // MAIN CONTENT

                Group {

                    if user.role == .security {

                        securityContent

                    } else {

                        facultyContent
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .background(CUTheme.background)

                // BOTTOM NAVIGATION

                HStack(spacing: 0) {

                    ForEach(
                        Array(tabs.enumerated()),
                        id: \.offset
                    ) { index, tab in

                        Button {

                            selectedTab = index

                        } label: {

                            VStack(spacing: 5) {

                                Image(systemName: tab.1)
                                    .font(.system(size: 18))

                                Text(tab.0)
                                    .font(
                                        .system(
                                            size: 9,
                                            weight: .medium
                                        )
                                    )
                                    .lineLimit(1)
                            }
                            .foregroundColor(
                                selectedTab == index
                                    ? CUTheme.red
                                    : CUTheme.secondary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(.white)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(CUTheme.lightRed)
                        .frame(height: 1)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: SECURITY CONTENT

    @ViewBuilder
    private var securityContent: some View {

        switch selectedTab {

        case 0:
            SecurityHomeView(
                store: store,
                user: user
            )

        case 1:
            StudentCheckInView(store: store)

        case 2:
            SecurityAppointmentsView(store: store)

        case 3:
            VisitorRegistrationView(store: store)

        default:
            EventLogView(store: store)
        }
    }

    // MARK: FACULTY CONTENT

    @ViewBuilder
    private var facultyContent: some View {

        switch selectedTab {

        case 0:
            FacultyHomeView(
                store: store,
                user: user
            )

        case 1:
            AppointmentCreationView(store: store)

        case 2:
            FacultyAppointmentsView(
                store: store,
                user: user
            )

        case 3:
            FacultyStatusView(
                store: store,
                user: user
            )

        default:
            EventLogView(store: store)
        }
    }
}

// MARK: - SECURITY HOME

struct SecurityHomeView: View {

    @ObservedObject var store: AppStore

    let user: AppUser

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                PageTitle(
                    title: "Campus Security",
                    subtitle: "Visitor and student access management."
                )

                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 12
                ) {

                    StatCard(
                        title: "Students",
                        value: "\(store.attendance.filter { !$0.checkedOut }.count)",
                        icon: "person.fill"
                    )

                    StatCard(
                        title: "Appointments",
                        value: "\(store.appointments.filter { !$0.checkedOut }.count)",
                        icon: "calendar"
                    )

                    StatCard(
                        title: "Visitors",
                        value: "\(store.visitors.filter { $0.checkedIn }.count)",
                        icon: "person.2.fill"
                    )

                    StatCard(
                        title: "Events",
                        value: "\(store.events.count)",
                        icon: "video.fill"
                    )
                }

                Text("SECURITY OPERATIONS")
                    .font(.caption.bold())
                    .foregroundColor(CUTheme.secondary)

                Text(
                    "Use the navigation bar below to access student check-in, teacher appointments, visitor registration and the security event log."
                )
                .font(.subheadline)
                .foregroundColor(CUTheme.secondary)

                Button {

                    store.toggleEmergency()

                } label: {

                    Label(
                        store.emergencyMode
                            ? "Deactivate Emergency"
                            : "Activate Emergency",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .primaryButton()
                }

                Text("RECENT ACTIVITY")
                    .font(.caption.bold())
                    .foregroundColor(CUTheme.secondary)

                ForEach(
                    Array(store.events.prefix(5))
                ) { event in

                    EventRow(event: event)
                }
            }
            .padding()
        }
    }
}

// MARK: - FACULTY HOME

struct FacultyHomeView: View {

    @ObservedObject var store: AppStore

    let user: AppUser

    private var myAppointments: [Appointment] {

        store.appointments.filter {
            $0.facultyEcode == user.ecode
        }
    }

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                PageTitle(
                    title: "Welcome, \(user.name)",
                    subtitle: "Faculty appointment management."
                )

                StatCard(
                    title: "My Appointments",
                    value: "\(myAppointments.count)",
                    icon: "calendar"
                )

                Text("FACULTY SERVICES")
                    .font(.caption.bold())
                    .foregroundColor(CUTheme.secondary)

                Text(
                    "Generate visitor appointments, review appointment status and monitor visitor check-in and check-out."
                )
                .font(.subheadline)
                .foregroundColor(CUTheme.secondary)

                Text("UPCOMING APPOINTMENTS")
                    .font(.caption.bold())
                    .foregroundColor(CUTheme.secondary)

                ForEach(
                    Array(myAppointments.prefix(5))
                ) { appointment in

                    AppointmentCard(
                        appointment: appointment
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - APPOINTMENT CREATION

struct AppointmentCreationView: View {

    @ObservedObject var store: AppStore

    @State private var visitorName = ""
    @State private var phone = ""
    @State private var purpose = ""
    @State private var date = Date()

    @State private var message = ""

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                PageTitle(
                    title: "Generate Appointment",
                    subtitle: "Create a visitor appointment for campus entry."
                )

                FormField(
                    title: "Visitor Name",
                    placeholder: "Enter full name",
                    text: $visitorName
                )

                FormField(
                    title: "Phone Number",
                    placeholder: "Enter phone number",
                    text: $phone
                )
                .keyboardType(.phonePad)

                FormField(
                    title: "Visit Purpose",
                    placeholder: "Meeting / Guest Lecture / Other",
                    text: $purpose
                )

                DatePicker(
                    "Appointment Date & Time",
                    selection: $date,
                    in: Date()...,
                    displayedComponents: [
                        .date,
                        .hourAndMinute
                    ]
                )
                .tint(CUTheme.red)

                if !message.isEmpty {

                    Text(message)
                        .font(.caption)
                        .foregroundColor(CUTheme.red)
                }

                Button {

                    createAppointment()

                } label: {

                    Label(
                        "Generate Appointment",
                        systemImage: "calendar.badge.plus"
                    )
                    .primaryButton()
                }
            }
            .padding()
        }
    }

    private func createAppointment() {

        guard !visitorName.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty,
        !phone.isEmpty,
        !purpose.isEmpty else {

            message = "Please fill in all fields."
            return
        }

        store.createAppointment(
            visitorName: visitorName,
            phone: phone,
            purpose: purpose,
            date: date
        )

        message = "Appointment generated successfully."

        visitorName = ""
        phone = ""
        purpose = ""
        date = Date()
    }
}

// MARK: - FACULTY APPOINTMENTS

struct FacultyAppointmentsView: View {

    @ObservedObject var store: AppStore

    let user: AppUser

    private var appointments: [Appointment] {

        store.appointments.filter {
            $0.facultyEcode == user.ecode
        }
    }

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                PageTitle(
                    title: "My Appointments",
                    subtitle: "Appointments created using your Ecode."
                )

                if appointments.isEmpty {

                    EmptyState(
                        message: "No appointments generated yet."
                    )
                }

                ForEach(appointments) { appointment in

                    AppointmentCard(
                        appointment: appointment
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - FACULTY VISITOR STATUS

struct FacultyStatusView: View {

    @ObservedObject var store: AppStore

    let user: AppUser

    private var appointments: [Appointment] {

        store.appointments.filter {
            $0.facultyEcode == user.ecode
        }
    }

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                PageTitle(
                    title: "Visitor Status",
                    subtitle: "Track the status of your appointments."
                )

                ForEach(appointments) { appointment in

                    AppointmentCard(
                        appointment: appointment
                    )
                }

                ForEach(
                    store.visitors.filter {
                        $0.host == user.name
                    }
                ) { visitor in

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text(visitor.name)
                            .font(.headline)

                        Text("Purpose: \(visitor.purpose)")

                        Text(
                            visitor.checkedOut
                                ? "Checked Out"
                                : visitor.checkedIn
                                    ? "Checked In"
                                    : "Not Checked In"
                        )
                        .font(.caption.bold())
                        .foregroundColor(CUTheme.red)
                    }
                    .cardStyle()
                }
            }
            .padding()
        }
    }
}

// MARK: - SECURITY APPOINTMENTS

struct SecurityAppointmentsView: View {

    @ObservedObject var store: AppStore

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                PageTitle(
                    title: "Teacher Appointments",
                    subtitle: "View appointments generated by faculty."
                )

                if store.appointments.isEmpty {

                    EmptyState(
                        message: "No appointments have been generated."
                    )
                }

                ForEach(store.appointments) { appointment in

                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {

                        AppointmentCard(
                            appointment: appointment
                        )

                        if !appointment.checkedIn
                            && !appointment.checkedOut {

                            Button {

                                store.updateAppointmentCheckIn(
                                    appointment
                                )

                            } label: {

                                Label(
                                    "Verify & Check In",
                                    systemImage: "checkmark.shield.fill"
                                )
                                .primaryButton()
                            }

                        } else if appointment.checkedIn {

                            Button {

                                store.updateAppointmentCheckOut(
                                    appointment
                                )

                            } label: {

                                Label(
                                    "Check Out",
                                    systemImage: "rectangle.portrait.and.arrow.right"
                                )
                                .primaryButton()
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - STUDENT CHECK-IN

struct StudentCheckInView: View {

    @ObservedObject var store: AppStore

    @State private var uid = ""
    @State private var purpose = ""

    @State private var student: Student?
    @State private var message = ""

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                PageTitle(
                    title: "Student Check-In",
                    subtitle: "Manually verify students using their university UID."
                )

                FormField(
                    title: "Student UID",
                    placeholder: "Example: CU2024001",
                    text: $uid
                )
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()

                FormField(
                    title: "Visit Purpose",
                    placeholder: "Class / Faculty Visit / Other",
                    text: $purpose
                )

                Button {

                    student = store.findStudent(uid: uid)

                    if student == nil {

                        message =
                            "Student not found. Verify the UID manually."

                    } else {

                        message = "Student record found."
                    }

                } label: {

                    Label(
                        "Verify Student",
                        systemImage: "person.text.rectangle"
                    )
                    .primaryButton()
                }

                if let student = student {

                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {

                        Text("STUDENT VERIFIED")
                            .font(.caption.bold())
                            .foregroundColor(.green)

                        Text(student.name)
                            .font(.title2.bold())
                            .foregroundColor(CUTheme.red)

                        DetailRow(
                            title: "UID",
                            value: student.id
                        )

                        DetailRow(
                            title: "Branch",
                            value: student.branch
                        )

                        DetailRow(
                            title: "Academic Year",
                            value: student.year
                        )

                        Button {

                            guard !purpose.isEmpty else {
                                message = "Enter visit purpose."
                                return
                            }

                            store.studentCheckIn(
                                student: student,
                                purpose: purpose
                            )

                            message =
                                "Student checked in successfully."

                            self.student = nil
                            uid = ""
                            purpose = ""

                        } label: {

                            Label(
                                "Confirm Student Check-In",
                                systemImage: "checkmark.circle.fill"
                            )
                            .primaryButton()
                        }
                    }
                    .cardStyle()
                }

                if !message.isEmpty {

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(CUTheme.red)
                }

                Divider()

                Text("STUDENT ATTENDANCE")
                    .font(.caption.bold())
                    .foregroundColor(CUTheme.secondary)

                ForEach(store.attendance) { record in

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text(record.studentName)
                            .font(.headline)

                        Text(record.studentUID)
                            .font(.caption)

                        Text("Purpose: \(record.purpose)")
                            .font(.subheadline)

                        Text(
                            record.checkedOut
                                ? "Checked Out"
                                : "Currently Checked In"
                        )
                        .font(.caption.bold())
                        .foregroundColor(CUTheme.red)

                        if !record.checkedOut {

                            Button {

                                store.studentCheckOut(record)

                            } label: {

                                Text("Check Out Student")
                                    .primaryButton()
                            }
                        }
                    }
                    .cardStyle()
                }
            }
            .padding()
        }
    }
}

// MARK: - VISITOR REGISTRATION

struct VisitorRegistrationView: View {

    @ObservedObject var store: AppStore

    @State private var name = ""
    @State private var phone = ""
    @State private var purpose = ""
    @State private var host = ""

    @State private var message = ""

    @State private var generatedID: String?

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                PageTitle(
                    title: "Visitor Registration",
                    subtitle: "Register visitors and generate digital passes."
                )

                FormField(
                    title: "Visitor Name",
                    placeholder: "Full name",
                    text: $name
                )

                FormField(
                    title: "Phone Number",
                    placeholder: "Phone number",
                    text: $phone
                )
                .keyboardType(.phonePad)

                FormField(
                    title: "Visit Purpose",
                    placeholder: "Purpose",
                    text: $purpose
                )

                FormField(
                    title: "Host / Teacher",
                    placeholder: "Host name",
                    text: $host
                )

                Button {

                    register()

                } label: {

                    Label(
                        "Register Visitor",
                        systemImage: "person.badge.plus"
                    )
                    .primaryButton()
                }

                if !message.isEmpty {

                    Text(message)
                        .font(.caption)
                        .foregroundColor(CUTheme.red)
                }

                if let id = generatedID {

                    VStack(spacing: 12) {

                        Text("VISITOR DIGITAL PASS")
                            .font(.headline.bold())
                            .foregroundColor(CUTheme.red)

                        QRCodeImageView(value: id)
                            .frame(
                                width: 180,
                                height: 180
                            )

                        Text(name)
                            .font(.title3.bold())

                        Text("Pass ID: \(id)")
                            .font(.caption2)
                            .textSelection(.enabled)

                        Text("Registered by Security")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                    .cardStyle()
                }

                Text("REGISTERED VISITORS")
                    .font(.caption.bold())
                    .foregroundColor(CUTheme.secondary)

                ForEach(store.visitors) { visitor in

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text(visitor.name)
                            .font(.headline)

                        Text("Host: \(visitor.host)")
                        Text("Purpose: \(visitor.purpose)")

                        Text(
                            visitor.checkedOut
                                ? "Checked Out"
                                : visitor.checkedIn
                                    ? "Checked In"
                                    : "Awaiting Entry"
                        )
                        .font(.caption.bold())
                        .foregroundColor(CUTheme.red)

                        if !visitor.checkedIn
                            && !visitor.checkedOut {

                            Button {

                                store.visitorCheckIn(visitor)

                            } label: {

                                Text("Check In")
                                    .primaryButton()
                            }

                        } else if visitor.checkedIn {

                            Button {

                                store.visitorCheckOut(visitor)

                            } label: {

                                Text("Check Out")
                                    .primaryButton()
                            }
                        }
                    }
                    .cardStyle()
                }
            }
            .padding()
        }
    }

    private func register() {

        guard !name.isEmpty,
              !phone.isEmpty,
              !purpose.isEmpty,
              !host.isEmpty else {

            message = "Please complete all fields."
            return
        }

        store.registerVisitor(
            name: name,
            phone: phone,
            purpose: purpose,
            host: host
        )

        generatedID = store.visitors.first?.id

        message = "Visitor registered successfully."

        phone = ""
        purpose = ""
        host = ""
    }
}

// MARK: - EVENT LOG

struct EventLogView: View {

    @ObservedObject var store: AppStore

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                PageTitle(
                    title: "CCTV Event Log",
                    subtitle: "Recorded security and access events."
                )

                Text(
                    "This prototype records application events. It does not connect to physical CCTV cameras."
                )
                .font(.caption)
                .foregroundColor(CUTheme.secondary)

                if store.events.isEmpty {

                    EmptyState(
                        message: "No events recorded."
                    )
                }

                ForEach(store.events) { event in

                    EventRow(event: event)
                }
            }
            .padding()
        }
    }
}

// MARK: - COMMON COMPONENTS

struct PageTitle: View {

    let title: String
    let subtitle: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text(title)
                .font(.title2.bold())
                .foregroundColor(CUTheme.red)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(CUTheme.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

struct StatCard: View {

    let title: String
    let value: String
    let icon: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(CUTheme.red)

            Text(value)
                .font(.largeTitle.bold())
                .foregroundColor(CUTheme.text)

            Text(title)
                .font(.subheadline)
                .foregroundColor(CUTheme.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(CUTheme.lightRed)
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }
}

struct FormField: View {

    let title: String
    let placeholder: String

    @Binding var text: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 7
        ) {

            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(CUTheme.text)

            TextField(
                placeholder,
                text: $text
            )
            .padding()
            .background(
                Color.gray.opacity(0.08)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
            )
            .overlay {

                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        CUTheme.lightRed,
                        lineWidth: 1
                    )
            }
        }
    }
}

struct DetailRow: View {

    let title: String
    let value: String

    var body: some View {

        HStack {

            Text(title)
                .foregroundColor(CUTheme.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(CUTheme.text)
        }
        .font(.subheadline)
    }
}

struct EventRow: View {

    let event: SecurityEvent

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Image(systemName: "video.fill")
                .foregroundColor(CUTheme.red)

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(event.title)
                    .font(.headline)
                    .foregroundColor(CUTheme.text)

                Text(event.details)
                    .font(.subheadline)
                    .foregroundColor(CUTheme.secondary)

                Text(
                    event.time.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.caption)
                .foregroundColor(CUTheme.secondary)
            }

            Spacer()
        }
        .cardStyle()
    }
}

struct AppointmentCard: View {

    let appointment: Appointment

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack {

                Text(appointment.visitorName)
                    .font(.headline)
                    .foregroundColor(CUTheme.text)

                Spacer()

                Text(
                    appointment.checkedOut
                        ? "CHECKED OUT"
                        : appointment.checkedIn
                            ? "CHECKED IN"
                            : "SCHEDULED"
                )
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(CUTheme.red)
            }

            DetailRow(
                title: "Faculty",
                value: appointment.facultyName
            )

            DetailRow(
                title: "Phone",
                value: appointment.phone
            )

            DetailRow(
                title: "Purpose",
                value: appointment.purpose
            )

            DetailRow(
                title: "Date",
                value: appointment.date.formatted(
                    date: .abbreviated,
                    time: .shortened
                )
            )

            Text("Pass ID: \(appointment.id)")
                .font(.caption2)
                .foregroundColor(CUTheme.secondary)
                .textSelection(.enabled)

            QRCodeImageView(
                value: appointment.id
            )
            .frame(
                width: 130,
                height: 130
            )
            .frame(
                maxWidth: .infinity,
                alignment: .center
            )
        }
        .cardStyle()
    }
}

struct EmptyState: View {

    let message: String

    var body: some View {

        VStack(spacing: 10) {

            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(CUTheme.red)

            Text(message)
                .font(.subheadline)
                .foregroundColor(CUTheme.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(CUTheme.lightRed)
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }
}

extension View {

    func cardStyle() -> some View {

        self
            .padding()
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(.white)
            .overlay {

                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        CUTheme.lightRed,
                        lineWidth: 1
                    )
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
    }

    func primaryButton() -> some View {

        self
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(CUTheme.red)
            .foregroundColor(.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 14)
            )
    }
}

// MARK: - QR CODE GENERATOR

struct QRCodeImageView: View {

    let value: String

    var body: some View {

        if let image = generateQR() {

            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()

        } else {

            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .foregroundColor(CUTheme.red)
        }
    }

    private func generateQR() -> UIImage? {

        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(value.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else {
            return nil
        }

        let scaled = output.transformed(
            by: CGAffineTransform(
                scaleX: 10,
                y: 10
            )
        )

        let context = CIContext()

        guard let cgImage = context.createCGImage(
            scaled,
            from: scaled.extent
        ) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

// MARK: - PREVIEW

#Preview {
    ContentView()
}
