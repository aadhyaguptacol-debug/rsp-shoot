import SwiftUI

// MARK: - Game Move Model & Constants
enum MoveType: String, CaseIterable, Identifiable {
    case rock = "Rock"
    case paper = "Paper"
    case scissors = "Scissors"
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .rock: return "✊"
        case .paper: return "✋"
        case .scissors: return "✌️"
        }
    }
}

// MARK: - Main Game View
struct ContentView: View {
    // MARK: - Game Data (Requirements 3 & 6)
    // Array containing Rock, Paper, and Scissors
    let moves: [String] = ["Rock", "Paper", "Scissors"]
    
    // Winning moves array representing winning response for ["Rock", "Paper", "Scissors"]
    // Rock -> Paper, Paper -> Scissors, Scissors -> Rock
    let winningMoves: [String] = ["Paper", "Scissors", "Rock"]
    
    // Losing moves array representing losing response for ["Rock", "Paper", "Scissors"]
    // Rock -> Scissors, Paper -> Rock, Scissors -> Paper
    let losingMoves: [String] = ["Scissors", "Rock", "Paper"]
    
    let moveEmojis: [String: String] = [
        "Rock": "✊",
        "Paper": "✋",
        "Scissors": "✌️"
    ]
    
    let totalRounds: Int = 10
    
    // MARK: - Game State (Requirement 3)
    // 1. App's current move
    @State private var appCurrentMove: Int = Int.random(in: 0...2)
    // 2. WIN/LOSE instruction (alternates every round)
    @State private var shouldWin: Bool = Bool.random()
    // 3. Current score
    @State private var score: Int = 0
    // 4. Current round (1 to 10)
    @State private var currentRound: Int = 1
    // 5. Game status
    @State private var isGameOver: Bool = false
    
    // MARK: - Visual & Interaction Feedback State
    @State private var selectedPlayerMoveIndex: Int? = nil
    @State private var lastAnswerCorrect: Bool? = nil
    @State private var feedbackMessage: String = ""
    @State private var isInteractingLocked: Bool = false
    @State private var correctAnswersCount: Int = 0
    @State private var incorrectAnswersCount: Int = 0
    @State private var currentStreak: Int = 0
    @State private var bestStreak: Int = 0
    
    // Visual micro-animations
    @State private var pulsePrompt: Bool = false
    @State private var appMoveScale: CGFloat = 1.0
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background Theme
            backgroundGradient
            
            // Safe Area Content Container
            VStack(spacing: 0) {
                if isGameOver {
                    gameOverView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.92)),
                            removal: .opacity
                        ))
                } else {
                    gamePlayView
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                }
            }
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 12)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 16)
            }
            .padding(.horizontal, 20)
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isGameOver)
        .animation(.easeInOut(duration: 0.25), value: shouldWin)
        .animation(.easeInOut(duration: 0.2), value: selectedPlayerMoveIndex)
    }
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        ZStack {
            // Deep space midnight gradient
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.07, blue: 0.16),
                    Color(red: 0.03, green: 0.03, blue: 0.08),
                    Color(red: 0.08, green: 0.05, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Dynamic ambient glow spots
            GeometryReader { proxy in
                Circle()
                    .fill(shouldWin ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                    .frame(width: proxy.size.width * 0.85, height: proxy.size.width * 0.85)
                    .blur(radius: 70)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.4)
                
                Circle()
                    .fill(Color.blue.opacity(0.10))
                    .frame(width: proxy.size.width * 0.7, height: proxy.size.width * 0.7)
                    .blur(radius: 70)
                    .position(x: proxy.size.width * 0.85, y: proxy.size.height * 0.85)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Game Screen Layout
    private var gamePlayView: some View {
        VStack(spacing: 0) {
            // Top Navigation & Score Header
            topHeaderBar
            
            // Round & Progress Bar
            roundProgressSection
                .padding(.top, 10)
            
            Spacer(minLength: 6)
            
            // Prominent App's Selected Move Center Display
            appMoveArenaView
            
            Spacer(minLength: 6)
            
            // WIN or LOSE Target Instruction Card
            missionInstructionCard
            
            Spacer(minLength: 6)
            
            // Interactive Move Selection Buttons
            playerSelectionSection
        }
    }
    
    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        HStack(alignment: .center) {
            // Title & Subtitle
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("BRAIN RPS")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(.white)
                }
                
                Text("Reflex Trainer")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Streak Badge (appears on consecutive correct answers)
            if currentStreak > 1 {
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 12))
                    Text("\(currentStreak)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.orange.opacity(0.18))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.orange.opacity(0.4), lineWidth: 1)
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Score Display
            HStack(spacing: 6) {
                Text("SCORE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.0)
                
                Text("\(score)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(score >= 0 ? .green : .red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Round Progress Indicator
    private var roundProgressSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text("ROUND \(currentRound) / \(totalRounds)")
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundColor(.cyan)
                    .tracking(1.0)
                
                Spacer()
                
                Text("\(currentRound * 10)% Progress")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
            
            // Custom Rounded Progress Bar
            GeometryReader { barProxy in
                let progress = min(max(Double(currentRound) / Double(totalRounds), 0.1), 1.0)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 7)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(barProxy.size.width * progress, 14), height: 7)
                        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: currentRound)
                }
            }
            .frame(height: 7)
        }
    }
    
    // MARK: - Center App Move Display
    private var appMoveArenaView: some View {
        VStack(spacing: 6) {
            Text("APP'S MOVE")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2.0)
                .foregroundColor(.white.opacity(0.6))
            
            ZStack {
                // Subtle glowing ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.45),
                                Color.purple.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 130, height: 130)
                    .scaleEffect(appMoveScale)
                
                // Frosted card background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 116, height: 116)
                    .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5)
                    )
                
                // Move Emoji & Name
                VStack(spacing: 2) {
                    Text(moveEmojis[moves[appCurrentMove]] ?? "✊")
                        .font(.system(size: 58))
                        .shadow(color: Color.white.opacity(0.2), radius: 6, x: 0, y: 0)
                        .id("appMoveEmoji_\(appCurrentMove)_\(currentRound)")
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                    
                    Text(moves[appCurrentMove].uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
    }
    
    // MARK: - WIN or LOSE Target Instruction Card
    private var missionInstructionCard: some View {
        VStack(spacing: 4) {
            // Objective Label
            Text("YOUR INSTRUCTION")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2.0)
                .foregroundColor(shouldWin ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
            
            // Bold WIN or LOSE Text (Requirement 4)
            HStack(spacing: 8) {
                Image(systemName: shouldWin ? "trophy.fill" : "xmark.shield.fill")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(shouldWin ? .green : .red)
                
                Text(shouldWin ? "WIN" : "LOSE")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .tracking(3.0)
                    .foregroundColor(shouldWin ? .green : .red)
            }
            .scaleEffect(pulsePrompt ? 1.06 : 1.0)
            
            // Guidance Subtitle
            Text(shouldWin ? "Choose the move that BEATS \(moves[appCurrentMove])" : "Choose the move that LOSES against \(moves[appCurrentMove])")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    shouldWin
                    ? Color(red: 0.05, green: 0.22, blue: 0.12).opacity(0.7)
                    : Color(red: 0.28, green: 0.05, blue: 0.08).opacity(0.7)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    shouldWin ? Color.green.opacity(0.65) : Color.red.opacity(0.65),
                    lineWidth: 2
                )
        )
        .shadow(
            color: shouldWin ? Color.green.opacity(0.3) : Color.red.opacity(0.3),
            radius: 10,
            x: 0,
            y: 3
        )
    }
    
    // MARK: - Answer Feedback Helper
    private var answerFeedbackBanner: some View {
        Group {
            if let isCorrect = lastAnswerCorrect {
                HStack(spacing: 6) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(feedbackMessage)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(isCorrect ? .green : .red)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isCorrect ? Color.green.opacity(0.4) : Color.red.opacity(0.4), lineWidth: 1)
                )
                .transition(.scale.combined(with: .opacity))
            } else {
                Text("Select your counter-move:")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(height: 28)
    }
    
    // MARK: - Button Styling Helpers
    private func buttonBackgroundColor(isSelected: Bool) -> Color {
        if !isSelected {
            return Color.white.opacity(0.10)
        }
        if lastAnswerCorrect == true {
            return Color.green.opacity(0.35)
        } else if lastAnswerCorrect == false {
            return Color.red.opacity(0.35)
        } else {
            return Color.white.opacity(0.20)
        }
    }
    
    private func buttonBorderColor(isSelected: Bool) -> Color {
        if !isSelected {
            return Color.white.opacity(0.20)
        }
        if lastAnswerCorrect == true {
            return Color.green
        } else if lastAnswerCorrect == false {
            return Color.red
        } else {
            return Color.white
        }
    }
    
    private func buttonShadowColor(isSelected: Bool) -> Color {
        if !isSelected {
            return Color.black.opacity(0.25)
        }
        if lastAnswerCorrect == true {
            return Color.green.opacity(0.4)
        } else if lastAnswerCorrect == false {
            return Color.red.opacity(0.4)
        } else {
            return Color.black.opacity(0.3)
        }
    }

    // MARK: - Player Move Selection Buttons
    private var playerSelectionSection: some View {
        VStack(spacing: 8) {
            // Interactive Feedback Message or Prompt
            answerFeedbackBanner
            
            HStack(spacing: 12) {
                // Requirement 3: ForEach loop for move buttons
                ForEach(0..<moves.count, id: \.self) { index in
                    let moveName = moves[index]
                    let emoji = moveEmojis[moveName] ?? "✊"
                    let isSelected = (selectedPlayerMoveIndex == index)
                    
                    Button {
                        playerSelected(moveIndex: index)
                    } label: {
                        VStack(spacing: 5) {
                            Text(emoji)
                                .font(.system(size: 38))
                                .shadow(radius: isSelected ? 6 : 2)
                            
                            Text(moveName)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(buttonBackgroundColor(isSelected: isSelected))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(buttonBorderColor(isSelected: isSelected), lineWidth: isSelected ? 2.5 : 1)
                        )
                        .shadow(
                            color: buttonShadowColor(isSelected: isSelected),
                            radius: isSelected ? 8 : 4,
                            x: 0,
                            y: 3
                        )
                        .scaleEffect(isSelected ? 0.96 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isInteractingLocked || isGameOver)
                }
            }
        }
    }
    
    // MARK: - Game Over Screen Layout
    private var gameOverView: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 4)
            
            // Trophy / Brain Achievement Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                score >= 7 ? Color.yellow.opacity(0.25) : Color.cyan.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 55
                        )
                    )
                    .frame(width: 105, height: 105)
                
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5)
                    )
                
                Text(gameOverBadgeEmoji)
                    .font(.system(size: 40))
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            // "GAME OVER" Title (Requirement 5)
            VStack(spacing: 2) {
                Text("GAME OVER")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .tracking(2.0)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text("10-Round Brain Assessment")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Score Summary Card (Requirement 5)
            VStack(spacing: 8) {
                Text("FINAL SCORE")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2.0)
                    .foregroundColor(.white.opacity(0.65))
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundColor(score >= 5 ? .green : (score >= 0 ? .orange : .red))
                    Text("/ \(totalRounds)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Stat Pills Row
                HStack(spacing: 8) {
                    StatPillView(
                        icon: "checkmark.circle.fill",
                        label: "Correct",
                        value: "\(correctAnswersCount)",
                        color: .green
                    )
                    
                    StatPillView(
                        icon: "xmark.circle.fill",
                        label: "Incorrect",
                        value: "\(incorrectAnswersCount)",
                        color: .red
                    )
                    
                    StatPillView(
                        icon: "flame.fill",
                        label: "Best Streak",
                        value: "\(bestStreak)",
                        color: .orange
                    )
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
            
            // Motivational Message (Requirement 5)
            VStack(spacing: 4) {
                Text("COGNITIVE PERFORMANCE")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.cyan)
                
                Text(motivationalMessage)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cyan.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.cyan.opacity(0.3), lineWidth: 1)
            )
            
            Spacer(minLength: 4)
            
            // Play Again Button (Requirement 2 & 5)
            Button {
                resetGame()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .black))
                    Text("PLAY AGAIN")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .tracking(1.5)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.25, green: 0.95, blue: 0.75),
                            Color(red: 0.15, green: 0.85, blue: 0.95)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.cyan.opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .padding(.bottom, 6)
        }
    }
    
    // MARK: - Motivational Message Helper
    private var motivationalMessage: String {
        switch score {
        case 10:
            return "Perfection! 🏆 Lightning-fast cognitive flexibility and flawless reverse psychology mastery!"
        case 8...9:
            return "Mastermind! 🌟 Exceptional mental speed and focus under alternating rules!"
        case 5...7:
            return "Solid Reflexes! ⚡ Sharp cognitive agility! Daily training will elevate your score to 10/10."
        case 1...4:
            return "Good Effort! 🧠 The switching WIN/LOSE conditions are tricky. Play another round to build reflex stamina!"
        default:
            return "Brain Workout Needed! 🌀 Inverted rules are a tough brain workout. Reset and try again to master the twist!"
        }
    }
    
    private var gameOverBadgeEmoji: String {
        switch score {
        case 10: return "👑"
        case 8...9: return "🏆"
        case 5...7: return "🧠"
        case 1...4: return "⚡️"
        default: return "💡"
        }
    }
    
    // MARK: - Game Logic Engine
    
    /// Checks the player's selected move against the app's move and the WIN/LOSE objective.
    /// Requirements 2, 3 & 6:
    /// - For a WIN instruction, use the corresponding winning move.
    /// - For a LOSE instruction, use the move that loses against the app's move.
    /// - Correct answer: +1 point. Incorrect answer: -1 point.
    private func playerSelected(moveIndex: Int) {
        guard !isInteractingLocked && !isGameOver else { return }
        
        isInteractingLocked = true
        selectedPlayerMoveIndex = moveIndex
        
        let playerMove = moves[moveIndex]
        let appMove = moves[appCurrentMove]
        
        // Winning move for app's current move
        let winningResponse = winningMoves[appCurrentMove]
        // Losing move for app's current move
        let losingResponse = losingMoves[appCurrentMove]
        
        let expectedMove = shouldWin ? winningResponse : losingResponse
        let isCorrect = (playerMove == expectedMove)
        
        // Update score & tracking
        if isCorrect {
            score += 1
            correctAnswersCount += 1
            currentStreak += 1
            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
            feedbackMessage = "+1 Correct! \(playerMove) \(shouldWin ? "beats" : "loses to") \(appMove)"
            triggerHaptic(type: .success)
        } else {
            score -= 1
            incorrectAnswersCount += 1
            currentStreak = 0
            feedbackMessage = "-1 Wrong! Needed \(expectedMove)"
            triggerHaptic(type: .error)
        }
        
        lastAnswerCorrect = isCorrect
        
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            pulsePrompt = true
        }
        
        // Allow brief visual feedback before advancing round
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            pulsePrompt = false
            advanceOrEndGame()
        }
    }
    
    /// Advances to the next round if under totalRounds (10), or triggers Game Over screen.
    private func advanceOrEndGame() {
        if currentRound < totalRounds {
            currentRound += 1
            nextRound()
            isInteractingLocked = false
        } else {
            // Exactly 10 rounds completed!
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                isGameOver = true
                isInteractingLocked = false
            }
        }
    }
    
    /// Prepares next round: selects new app move with Int.random(in:), alternates WIN/LOSE with toggle()
    private func nextRound() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedPlayerMoveIndex = nil
            lastAnswerCorrect = nil
            feedbackMessage = ""
        }
        
        // Requirement 3:
        // Int.random(in:) to select app's move
        appCurrentMove = Int.random(in: 0...2)
        
        // Requirement 3:
        // toggle() to alternate between WIN and LOSE after each round
        shouldWin.toggle()
        
        // Animate app move presentation
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            appMoveScale = 1.10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.2)) {
                appMoveScale = 1.0
            }
        }
    }
    
    /// Resets the game completely back to Round 1 (Requirement 2 & 3)
    private func resetGame() {
        score = 0
        currentRound = 1
        correctAnswersCount = 0
        incorrectAnswersCount = 0
        currentStreak = 0
        selectedPlayerMoveIndex = nil
        lastAnswerCorrect = nil
        feedbackMessage = ""
        isInteractingLocked = false
        
        // Requirement 3: Int.random(in:) for app move, Bool.random() for initial WIN/LOSE
        appCurrentMove = Int.random(in: 0...2)
        shouldWin = Bool.random()
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            isGameOver = false
        }
    }
    
    // MARK: - Haptics Helper
    private func triggerHaptic(type: UINotificationFeedbackGenerator.FeedbackType) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
        #endif
    }
}

// MARK: - Helper Views
struct StatPillView: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview Provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
