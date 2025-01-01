import SwiftUI

struct SudokuView: View {
    @EnvironmentObject var model: SudokuModel
    @EnvironmentObject var settings: Settings
    
    @AppStorage("showDifficultySelection") private var showDifficultySelection = true
    @State private var showPauseView = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSettings = false
    @State private var showGameContinuation = false
    @State private var showStatistics = false

    var body: some View {
        ZStack {
            backgroundColor
                .edgesIgnoringSafeArea(.all)

            if showDifficultySelection {
                if model.isGameInProgress() && !showGameContinuation {
                    GameContinuationView(model: model, showDifficultySelection: $showDifficultySelection)
                } else {
                    SudokuDifficultyView(difficulty: $model.difficulty) {
                        showDifficultySelection = false
                        Task {
                            await model.newGame(difficulty: model.difficulty)
                            model.startTimer()
                        }
                    }
                }
            } else {
                VStack {
                    HStack {
                        Text("Difficulty: \(model.difficulty.rawValue.capitalized)")
                        Spacer()
                        Text("Time: \(formatTime(model.elapsedTime))")
                        Spacer()
                        Text("Hints: \(model.hintsRemaining)")
                        Button(action: {
                            model.requestHint()
                        }) {
                            Image(systemName: "lightbulb")
                                .font(.title2)
                        }
                        .disabled(model.hintsRemaining == 0)
                        Button(action: {
                            model.pauseGame()
                            showPauseView = true
                        }) {
                            Image(systemName: "pause.circle")
                                .font(.title2)
                        }
                        Button(action: {
                            showStatistics = true
                        }) {
                            Image(systemName: "chart.bar")
                                .font(.title2)
                        }
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gear")
                                .font(.title2)
                        }
                    }
                    .padding()
                    .foregroundColor(textColor)

                    HStack {
                        Button(action: {
                            model.toggleNotes()
                        }) {
                            Image(systemName: model.isNoteMode ? "pencil.circle.fill" : "pencil.circle")
                                .font(.title2)
                        }

                        Button(action: {
                            model.undo()
                        }) {
                            Image(systemName: "arrow.uturn.backward.circle")
                                .font(.title2)
                        }
                        .disabled(model.undoStack.isEmpty)

                        Button(action: {
                            model.clearCell()
                        }) {
                            Image(systemName: "eraser")
                                .font(.title2)
                        }
                        .disabled(model.selectedCell == nil || (model.selectedCell != nil && model.grid[model.selectedCell!.row][model.selectedCell!.col] == nil))
                    }
                    .padding()
                    .foregroundColor(textColor)

                    Text("Mistakes: \(model.mistakeCount)/3")
                        .font(.headline)
                        .padding()
                        .foregroundColor(textColor)

                    if model.isLoading {
                        ProgressView("Generating puzzle...")
                            .foregroundColor(textColor)
                    } else {
                        SudokuGridView(model: model)
                            .background(backgroundColor)
                    }

                    NumberPadView(model: model)
                }
                .blur(radius: showPauseView ? 5 : 0)
                .allowsHitTesting(!showPauseView)
                .onKeyPress { press in
                    model.handleKeyPress(press.characters)
                    return .handled
                }
            }

            if showPauseView {
                SudokuPauseView(model: model, isPresented: $showPauseView)
            }
        }
        .alert(isPresented: $model.isGameOver) {
            if model.mistakeCount >= 3 {
                Alert(
                    title: Text("Game Over"),
                    message: Text("You've made 3 mistakes. Start a new game?"),
                    primaryButton: .default(Text("New Game")) {
                        showDifficultySelection = true
                        model.resetGame()
                    },
                    secondaryButton: .cancel()
                )
            } else {
                Alert(
                    title: Text("Congratulations!"),
                    message: Text("You've completed the puzzle!\nTime: \(formatTime(model.elapsedTime))\nDifficulty: \(model.difficulty.rawValue.capitalized)"),
                    primaryButton: .default(Text("New Game")) {
                        showDifficultySelection = true
                        model.resetGame()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showStatistics) {
            StatisticsView(model: model)
        }
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
        .onAppear {
            if model.isGameInProgress() {
                showGameContinuation = true
                showDifficultySelection = false
            }
        }
    }

    private var backgroundColor: Color {
        settings.isDarkMode ? Color(white: 0.1) : Color.white
    }

    private var textColor: Color {
        settings.isDarkMode ? Color.white : Color.black
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct SudokuGridView: View {
    @ObservedObject var model: SudokuModel
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<3) { blockRow in
                HStack(spacing: 0) {
                    ForEach(0..<3) { blockCol in
                        SudokuBlockView(model: model, blockRow: blockRow, blockCol: blockCol)
                    }
                }
            }
        }
        .background(backgroundColor)
        .padding(2)
        .background(Color.black)
        .padding()
    }
    
    private var backgroundColor: Color {
        settings.isDarkMode ? Color(white: 0.1) : Color.white
    }
}

struct SudokuBlockView: View {
    @ObservedObject var model: SudokuModel
    let blockRow: Int
    let blockCol: Int
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<3) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3) { col in
                        SudokuCellView(model: model, row: blockRow * 3 + row, col: blockCol * 3 + col)
                    }
                }
            }
        }
        .background(Color.black)
        .padding(0.5)
    }
}

struct SudokuCellView: View {
    @ObservedObject var model: SudokuModel
    @EnvironmentObject var settings: Settings
    let row: Int
    let col: Int
    
    private var highlightColor: Color {
        settings.isDarkMode ? Color(white: 0.3) : Color(red: 0.9, green: 0.9, blue: 0.9)
    }
    private var selectedColor: Color {
        settings.isDarkMode ? Color(white: 0.4) : Color(red: 0.8, green: 0.8, blue: 0.8)
    }
    private let lightBlack = Color(white: 0.2)
    
    @State private var scale: CGFloat = 1.0
    @State private var rotationDegrees: Double = 0
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(cellBackgroundColor)
                .border(Color.black, width: 0.5)
            
            if model.isHintCell(row: row, col: col) {
                Rectangle()
                    .fill(Color.yellow.opacity(0.3))
                    .scaleEffect(scale)
                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: scale)
                    .onAppear {
                        scale = 1.2
                    }
            }
            
            if let number = model.grid[row][col] {
                Text("\(number)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(textColor(for: number))
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotationDegrees))
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: number)
                    .onAppear {
                        withAnimation {
                            scale = 1.0
                            rotationDegrees = 0
                        }
                    }
            } else {
                NotesView(notes: model.notes[row][col])
            }
        }
        .frame(width: 35, height: 35)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                scale = 1.2
                rotationDegrees = 360
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.0
                    rotationDegrees = 0
                }
                model.selectCell(row: row, col: col)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(determineAccessibilityTraits())
    }
    
    private var accessibilityLabel: Text {
        if model.isHintCell(row: row, col: col) {
            return Text("Hint available at row \(row + 1), column \(col + 1)")
        }
        return Text("Cell at row \(row + 1), column \(col + 1)")
    }
    
    private var accessibilityValue: Text {
        if let number = model.grid[row][col] {
            let status = model.isMistake(row: row, col: col) ? "incorrect" : "correct"
            return Text("Number \(number), \(status)")
        } else if model.notes[row][col].contains(true) {
            let noteNumbers = model.notes[row][col].enumerated()
                .filter { $0.element }
                .map { String($0.offset + 1) }
                .joined(separator: ", ")
            return Text("Notes: \(noteNumbers)")
        }
        return Text("Empty")
    }
    
    private var accessibilityHint: Text {
        if model.grid[row][col] == nil {
            return Text("Double tap to select this cell")
        }
        return Text("")
    }
    
    private func determineAccessibilityTraits() -> AccessibilityTraits {
        var traits: AccessibilityTraits = [.updatesFrequently]
        if let selectedCell = model.selectedCell, selectedCell.row == row && selectedCell.col == col {
            traits.insert(.isSelected)
        }
        if model.grid[row][col] != nil {
            traits.insert(.isStaticText)
        } else {
            traits.insert(.allowsDirectInteraction)
        }
        return traits
    }
    
    private var cellBackgroundColor: Color {
        if let selectedCell = model.selectedCell {
            if selectedCell.row == row && selectedCell.col == col {
                return selectedColor
            } else if let selectedNumber = model.grid[selectedCell.row][selectedCell.col],
                      model.grid[row][col] == selectedNumber,
                      !model.isMistakeNumber(selectedNumber) {
                return selectedColor
            } else if shouldHighlightEmptyCell(selectedCell) {
                return highlightColor
            }
        }
        if model.shouldHighlight(row: row, col: col) {
            return highlightColor
        }
        return settings.isDarkMode ? Color(white: 0.2) : .white
    }
    
    private func shouldHighlightEmptyCell(_ selectedCell: CellPosition) -> Bool {
        guard model.grid[selectedCell.row][selectedCell.col] == nil else { return false }
        let selectedBlockRow = selectedCell.row / 3
        let selectedBlockCol = selectedCell.col / 3
        let currentBlockRow = row / 3
        let currentBlockCol = col / 3
        return row == selectedCell.row || col == selectedCell.col || (selectedBlockRow == currentBlockRow && selectedBlockCol == currentBlockCol)
    }
    
    private func textColor(for number: Int) -> Color {
        if model.isMistake(row: row, col: col) {
            return .red
        } else if model.isMistakeNumber(number) {
            return .black
        } else if model.isSelectedNumber(number) {
            return .blue
        } else {
            return .black
        }
    }
}

struct NotesView: View {
    let notes: [Bool]
    private let darkGrey = Color(white: 0.3)
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height) / 3
            VStack(spacing: 0) {
                ForEach(0..<3) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<3) { col in
                            let number = row * 3 + col + 1
                            if notes[number - 1] {
                                Text("\(number)")
                                    .font(.system(size: size * 0.7))
                                    .foregroundColor(darkGrey)
                                    .frame(width: size, height: size)
                            } else {
                                Color.clear
                                    .frame(width: size, height: size)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct NumberPadView: View {
    @ObservedObject var model: SudokuModel
    @State private var selectedScale: [Int: CGFloat] = [:]
    
    var body: some View {
        HStack {
            ForEach(1...9, id: \.self) { number in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        selectedScale[number] = 1.2
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            selectedScale[number] = 1.0
                        }
                        model.setNumber(number)
                    }
                }) {
                    Text("\(number)")
                        .font(.title2)
                        .frame(width: 35, height: 35)
                        .background(model.isSelectedNumber(number) ? Color.blue.opacity(0.3) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                        .scaleEffect(selectedScale[number] ?? 1.0)
                }
                .accessibilityLabel("Number \(number)")
                .accessibilityHint(model.isNoteMode ? "Add note \(number)" : "Enter number \(number)")
                .accessibilityValue(model.isSelectedNumber(number) ? "Selected" : "")
                .disabled(model.selectedCell == nil)
            }
        }
        .padding()
    }
}

struct StatisticsView: View {
    @ObservedObject var model: SudokuModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Best Times")) {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        HStack {
                            Text(difficulty.rawValue.capitalized)
                            Spacer()
                            if let bestTime = model.bestTimes[difficulty] {
                                Text(formatTime(bestTime))
                            } else {
                                Text("--:--")
                            }
                        }
                    }
                }
                
                Section(header: Text("Games Statistics")) {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(difficulty.rawValue.capitalized)
                                .font(.headline)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Games Played")
                                    Text("\(model.gamesPlayed[difficulty, default: 0])")
                                        .font(.subheadline)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Games Won")
                                    Text("\(model.gamesWon[difficulty, default: 0])")
                                        .font(.subheadline)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Win Rate")
                                    Text(String(format: "%.1f%%", calculateWinRate(difficulty: difficulty)))
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func calculateWinRate(difficulty: Difficulty) -> Double {
        let played = model.gamesPlayed[difficulty, default: 0]
        let won = model.gamesWon[difficulty, default: 0]
        guard played > 0 else { return 0 }
        return Double(won) / Double(played) * 100
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct SudokuView_Previews: PreviewProvider {
    static var previews: some View {
        SudokuView()
    }
}
