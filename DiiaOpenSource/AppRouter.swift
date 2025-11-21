import UIKit
import SwiftUI
import Combine
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonTypes
import DiiaAuthorization
import DiiaAuthorizationPinCode

class AppRouter {

    private var window: UIWindow!
    private var navigationController: UINavigationController!
    private var tabBarController: MainTabRoutingProtocol?

    private var pincodeContainer: ContainerProtocol?
    private var pincodeView: UIViewController?
    private var defferedAction: ((BaseView?) -> Void)?
    private var defferedSafeAction: ((BaseView?) -> Void)?

    var didFinishStarting: Bool = false {
        didSet {
            guard didFinishStarting else { return }
            self.defferedAction?(self.currentView())
            self.defferedAction = nil
        }
    }
    var didFinishStartingWithPincode: Bool = false {
        didSet {
            guard didFinishStartingWithPincode else { return }
            self.defferedSafeAction?(self.currentView())
            self.defferedSafeAction = nil
        }
    }

    static let instance = AppRouter()
    
    private init() {}
    
    func configure(window: UIWindow, navigationController: UINavigationController = BaseNavigationController()) {
        self.window = window
        navigationController.setNavigationBarHidden(true, animated: false)
        self.navigationController = navigationController
    }
    
    func start() {
        self.window.rootViewController = navigationController
        self.window.makeKeyAndVisible()
        self.didFinishStartingWithPincode = false
        self.didFinishStarting = false
        self.tabBarController = nil
        
        routeStart()
        didFinishStarting = true
    }
    
    /// Navigate to destination module or make it root in navigation. Start deffered action if needed
    /// - Parameters:
    ///   - module: Destination module
    ///   - needPincode: Define if user need authorization for this navigation
    ///   - asRoot: Define if destination module should be root controller in navigation. If true rewrite tabBarController
    func open(module: BaseModule, needPincode: Bool, asRoot: Bool = false) {
        if needPincode {
            let completion: (Result<String, Error>) -> Void = { [weak self] result in
                guard let self = self, case .success = result else { return }
                
                self.forceOpen(module: module, asRoot: asRoot, completion: { [weak self] in
                    self?.pincodeView = nil
                    self?.didFinishStartingWithPincode = true
                })
            }
            let pincodeView = EnterPinCodeModule(
                context: EnterPinCodeModuleContext.create(flow: .auth, completionHandler: completion),
                flow: .auth,
                viewModel: .auth
            ).viewController()
            self.pincodeView = pincodeView
            navigationController.pushViewController(pincodeView, animated: true)
            return
        } else {
            forceOpen(module: module, asRoot: asRoot, completion: nil)
        }
    }
    
    /// Returns current visible view
    func currentView() -> BaseView? {
        return window.visibleViewController as? BaseView
    }
    
    /// Shows pincode over currentModule
    func showPincode() {
        if pincodeView != nil || pincodeContainer != nil { return }
        didFinishStartingWithPincode = false
        let completion: (Result<String, Error>) -> Void = { [weak self] result in
            guard let self = self, case .success = result else { return }
            self.pincodeContainer?.close()
            self.pincodeContainer = nil
            self.didFinishStartingWithPincode = true
        }
        let module = EnterPinCodeInContainerModule(context: EnterPinCodeModuleContext.create(flow: .auth, completionHandler: completion),
                                                   flow: .auth,
                                                   viewModel: .auth)
        currentView()?.showChild(module: module)
        pincodeContainer = module.viewController() as? ChildContainerViewController
    }
    
    /// Perform navigation action with currentView if route start processing was finished. If not, save it and process after finishing
    /// - Parameters:
    ///   - action: Navigation callback with view parameter which is currentView of AppRouter
    ///   - needPincode: Define if user need authorization for this navigation
    func performOrDefer(action: @escaping ((BaseView?) -> Void), needPincode: Bool = false) {
        if didFinishStarting
            && (!needPincode || didFinishStartingWithPincode) {
            action(currentView())
        } else if !needPincode {
            defferedAction = action
        } else {
            defferedSafeAction = action
        }
    }
    
    /// Pops to Root tab controller if it exists
    /// - Parameter action: Action for processing in tab controller after popping
    func popToTab(with action: MainTabAction) {
        if let tabController = self.tabBarController {
            navigationController.popToViewController(tabController, animated: true)
            tabController.processAction(action: action)
        }
    }
    
    // MARK: - Private
    private func routeStart() {
        if LocalAuthState.isAuthenticated {
            open(module: MainTabBarModule(), needPincode: false, asRoot: true)
            didFinishStartingWithPincode = true
            return
        }

        let loginController = SwiftUILoginHostingController { [weak self] in
            self?.didFinishStartingWithPincode = true
            self?.open(module: MainTabBarModule(), needPincode: false, asRoot: true)
        }
        navigationController.setViewControllers([loginController], animated: false)
    }
    
    private func forceOpen(module: BaseModule, asRoot: Bool, completion: Callback?) {
        if asRoot {
            tabBarController = module.viewController() as? MainTabRoutingProtocol
            navigationController.setViewControllers([module.viewController()], animated: true, completion: completion)
        } else {
            self.navigationController.pushViewController(module.viewController(), animated: true, completion: completion)
        }
    }
}

extension AppRouter: AppRouterProtocol {}

// MARK: - Local Auth State
enum LocalAuthState {
    private static let userDefaults = UserDefaults.standard
    private static let isAuthenticatedKey = "isAuthenticated"
    
    static var isAuthenticated: Bool {
        userDefaults.bool(forKey: isAuthenticatedKey)
    }
}

// MARK: - DiiaApp-style SwiftUI Auth Host
final class SwiftUILoginHostingController: UIHostingController<DiiaAppLoginContainerView> {
    init(onComplete: @escaping () -> Void) {
        super.init(rootView: DiiaAppLoginContainerView(onComplete: onComplete))
    }
    
    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct DiiaAppLoginContainerView: View {
    @StateObject private var authManager = AuthManager()
    var onComplete: () -> Void
    
    var body: some View {
        AuthView(onLoginSuccess: onComplete)
            .environmentObject(authManager)
    }
}

// MARK: - DiiaApp Auth Copies
class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var hasSeenWelcome: Bool = false
    @Published var userName: String = ""
    @Published var hasSignature: Bool = false
    @Published var userFullName: String = ""
    @Published var userBirthDate: String = ""
    @Published var userId: Int?
    @Published var subscriptionActive: Bool = false
    @Published var subscriptionType: String = ""
    @Published var registeredAt: String = ""
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadAuthState()
    }
    
    private func loadAuthState() {
        isAuthenticated = userDefaults.bool(forKey: "isAuthenticated")
        hasSeenWelcome = userDefaults.bool(forKey: "hasSeenWelcome")
        userName = userDefaults.string(forKey: "userName") ?? ""
        hasSignature = userDefaults.data(forKey: "userSignature") != nil
        userFullName = userDefaults.string(forKey: "userFullName") ?? ""
        userBirthDate = userDefaults.string(forKey: "userBirthDate") ?? ""
        userId = userDefaults.object(forKey: "userId") as? Int
        subscriptionActive = userDefaults.bool(forKey: "subscriptionActive")
        subscriptionType = userDefaults.string(forKey: "subscriptionType") ?? ""
        registeredAt = userDefaults.string(forKey: "registeredAt") ?? ""
    }
    
    func login(username: String, password: String) {
        guard !username.isEmpty && !password.isEmpty else { return }
        
        userName = username
        isAuthenticated = true
        
        userDefaults.set(true, forKey: "isAuthenticated")
        userDefaults.set(username, forKey: "userName")
        userDefaults.set(Date(), forKey: "lastLoginDate")
        
        if userDefaults.object(forKey: "firstLoginDate") == nil {
            userDefaults.set(Date(), forKey: "firstLoginDate")
        }
    }
    
    func updateUserData(fullName: String, birthDate: String, userId: Int, subscriptionActive: Bool, subscriptionType: String, registeredAt: String? = nil) {
        self.userFullName = fullName
        self.userBirthDate = birthDate
        self.userId = userId
        self.subscriptionActive = subscriptionActive
        self.subscriptionType = subscriptionType
        
        userDefaults.set(fullName, forKey: "userFullName")
        userDefaults.set(birthDate, forKey: "userBirthDate")
        userDefaults.set(userId, forKey: "userId")
        userDefaults.set(subscriptionActive, forKey: "subscriptionActive")
        userDefaults.set(subscriptionType, forKey: "subscriptionType")
        
        if let registeredAt = registeredAt {
            self.registeredAt = registeredAt
            userDefaults.set(registeredAt, forKey: "registeredAt")
        }
    }
    
    func logout() {
        isAuthenticated = false
        userName = ""
        userFullName = ""
        userBirthDate = ""
        userId = nil
        subscriptionActive = false
        subscriptionType = ""
        
        userDefaults.set(false, forKey: "isAuthenticated")
        userDefaults.removeObject(forKey: "userName")
        userDefaults.removeObject(forKey: "userFullName")
        userDefaults.removeObject(forKey: "userBirthDate")
        userDefaults.removeObject(forKey: "userId")
        userDefaults.removeObject(forKey: "subscriptionActive")
        userDefaults.removeObject(forKey: "subscriptionType")
        userDefaults.removeObject(forKey: "registeredAt")
    }
    
    func markWelcomeSeen() {
        hasSeenWelcome = true
        userDefaults.set(true, forKey: "hasSeenWelcome")
    }
    
    func completeSignature() {
        hasSignature = true
    }
}

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let baseURL = "https://diia-backend.onrender.com"
    
    private let offlineCredentials: [String: String] = [
        "cmutyy": "password123",
        "test": "test123"
    ]
    
    private func getMockUserData(username: String) -> UserData? {
        switch username {
        case "cmutyy":
            return UserData(
                id: 1,
                full_name: "Максим Ільясов Данилович",
                birth_date: "07.01.2008",
                login: "cmutyy",
                subscription_active: true,
                subscription_type: "premium",
                last_login: nil,
                registered_at: "2024-10-23T16:48:00"
            )
        case "test":
            return UserData(
                id: 2,
                full_name: "Тестовий Користувач Дія",
                birth_date: "01.01.2000",
                login: "test",
                subscription_active: true,
                subscription_type: "basic",
                last_login: nil,
                registered_at: "2024-10-20T10:30:00"
            )
        default:
            return nil
        }
    }
    
    struct LoginResponse: Codable {
        let success: Bool
        let message: String
        let user: UserData?
    }
    
    struct UserData: Codable {
        let id: Int
        let fullName: String
        let birthDate: String
        let login: String
        let subscriptionActive: Bool
        let subscriptionType: String
        let lastLogin: String?
        let registeredAt: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case fullName = "full_name"
            case birthDate = "birth_date"
            case login
            case subscriptionActive = "subscription_active"
            case subscriptionType = "subscription_type"
            case lastLogin = "last_login"
            case registeredAt = "registered_at"
        }
    }
    
    struct LoginRequest: Codable {
        let login: String
        let password: String
    }
    
    func login(username: String, password: String) async -> (success: Bool, message: String, userData: UserData?) {
        if let result = await tryAPILogin(username: username, password: password) {
            return result
        }
        
        if let userData = UserDefaults.standard.data(forKey: "cachedUserData_\(username)"),
           let cachedUser = try? JSONDecoder().decode(UserData.self, from: userData),
           let cachedPassword = UserDefaults.standard.string(forKey: "cachedPassword_\(username)"),
           cachedPassword == password {
            return (true, "Використано кешовані дані", cachedUser)
        }
        
        if let storedPassword = offlineCredentials[username], storedPassword == password {
            let mockUser = getMockUserData(username: username)
            return (true, "Offline авторизація", mockUser)
        }
        
        return (false, "Невірний логін або пароль", nil)
    }
    
    private func tryAPILogin(username: String, password: String) async -> (success: Bool, message: String, userData: UserData?)? {
        guard let url = URL(string: "\(baseURL)/api/auth/login") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.timeoutInterval = 5.0
        
        let loginRequest = LoginRequest(login: username, password: password)
        
        do {
            request.httpBody = try JSONEncoder().encode(loginRequest)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return nil
            }
            
            if httpResponse.statusCode == 200 {
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                
                if loginResponse.success, let userData = loginResponse.user {
                    cacheUserData(username: username, password: password, userData: userData)
                    return (true, loginResponse.message, userData)
                } else {
                    return (false, loginResponse.message, nil)
                }
            }
        } catch {
            print("API Login error: \(error.localizedDescription)")
            return nil
        }
        
        return nil
    }
    
    private func cacheUserData(username: String, password: String, userData: UserData) {
        if let encoded = try? JSONEncoder().encode(userData) {
            UserDefaults.standard.set(encoded, forKey: "cachedUserData_\(username)")
            UserDefaults.standard.set(password, forKey: "cachedPassword_\(username)")
        }
    }
    
    func checkServerHealth() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/health") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.setValue("1", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.timeoutInterval = 3.0
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("Server health check failed: \(error.localizedDescription)")
        }
        
        return false
    }
    
    func downloadUserPhoto(userId: Int) async -> Data? {
        guard let url = URL(string: "\(baseURL)/api/photo/\(userId)") else {
            print("Invalid photo URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("1", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.timeoutInterval = 10.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Failed to download photo: invalid response")
                return nil
            }
            
            print("Info: Photo downloaded: \(data.count) bytes")
            return data
        } catch {
            print("Warn: Photo download error: \(error.localizedDescription)")
            return nil
        }
    }
}

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var networkManager = NetworkManager.shared
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isServerOnline = false
    
    var onLoginSuccess: (() -> Void)?
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Вхід у Дію")
                        .font(.system(size: 30, weight: .regular, design: .default))
                        .padding(.top, 64)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Логін")
                            .font(.system(size: 18, weight: .regular, design: .default))
                        
                        TextField("Введіть логін", text: $username)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .padding()
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.7))
                                    .background(.ultraThinMaterial)
                            )
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Пароль")
                            .font(.system(size: 18, weight: .regular, design: .default))
                        
                        HStack {
                            if showPassword {
                                TextField("Введіть пароль", text: $password)
                            } else {
                                SecureField("Введіть пароль", text: $password)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .padding()
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.7))
                                .background(.ultraThinMaterial)
                        )
                        
                        Button(action: {
                            if let url = URL(string: "https://t.me/diiatest24bot") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Отримати пароль?")
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .foregroundColor(.black)
                        }
                    }
                    
                    HStack {
                        Circle()
                            .fill(isServerOnline ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(isServerOnline ? "Сервер онлайн" : "Offline режим")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .padding(.bottom, 4)
                    
                    Button(action: {
                        Task {
                            await performLogin()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(16)
                        } else {
                            Text("Увійти")
                                .font(.system(size: 18, weight: .regular, design: .default))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.black)
                                .cornerRadius(16)
                        }
                    }
                    .disabled(isLoading || username.isEmpty || password.isEmpty)
                    .opacity((isLoading || username.isEmpty || password.isEmpty) ? 0.5 : 1)
                    .padding(.top, 16)
                    
                    Spacer(minLength: 100)
                    
                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("Не маєш акаунту?")
                                .font(.system(size: 16, weight: .regular, design: .default))
                            Text("Напиши у підтримку та отримай доступ")
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: {
                            if let url = URL(string: "https://t.me/maijediiabot") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Text("Зв’язатися з підтримкою")
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.7))
                                    .background(.ultraThinMaterial)
                            )
                        }
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
                .alert("Помилка", isPresented: $showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage)
                }
                .task {
                    isServerOnline = await networkManager.checkServerHealth()
                }
            }
        }
    }
    
    private func performLogin() async {
        isLoading = true
        
        let result = await networkManager.login(username: username, password: password)
        
        await MainActor.run {
            isLoading = false
            
            if result.success {
                authManager.login(username: username, password: password)
                
                if let userData = result.userData {
                    authManager.updateUserData(
                        fullName: userData.fullName,
                        birthDate: userData.birthDate,
                        userId: userData.id,
                        subscriptionActive: userData.subscriptionActive,
                        subscriptionType: userData.subscriptionType,
                        registeredAt: userData.registeredAt
                    )
                    
                    Task {
                        if let photoData = await networkManager.downloadUserPhoto(userId: userData.id) {
                            await MainActor.run {
                                UserDefaults.standard.set(photoData, forKey: "userPhoto")
                            }
                        }
                    }
                }
                
                onLoginSuccess?()
            } else {
                errorMessage = result.message
                showError = true
            }
        }
    }
}

class GradientManager: ObservableObject {
    static let shared = GradientManager()
    
    @Published var colorIndex = 0
    
    let colorSets: [[Color]] = [
        [
            Color(hex: "6ea8ff"),
            Color(hex: "ffd966"),
            Color(hex: "ff99cc")
        ],
        [
            Color(hex: "ffd966"),
            Color(hex: "ff99cc"),
            Color(hex: "c299ff")
        ],
        [
            Color(hex: "ff99cc"),
            Color(hex: "c299ff"),
            Color(hex: "6ea8ff")
        ],
        [
            Color(hex: "c299ff"),
            Color(hex: "6ea8ff"),
            Color(hex: "ffd966")
        ]
    ]
    
    private var timer: Timer?
    
    private init() {
        startAnimation()
    }
    
    func startAnimation() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            withAnimation(.easeInOut(duration: 2.5)) {
                self.colorIndex = (self.colorIndex + 1) % self.colorSets.count
            }
        }
    }
    
    var currentColors: [Color] {
        colorSets[colorIndex]
    }
}

struct AnimatedGradientBackground: View {
    @ObservedObject private var gradientManager = GradientManager.shared
    
    var body: some View {
        LinearGradient(
            colors: gradientManager.currentColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
