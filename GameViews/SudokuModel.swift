import Foundation
import UIKit

struct CellPosition: Hashable {
    let row: Int
    let col: Int
}

class SudokuModel: ObservableObject {
    @Published var grid: [[Int?]]
    @Published var notes: [[[Bool]]]
    @Published var selectedCell: CellPosition?
    @Published var selectedNumber: Int?
    @Published var isNoteMode: Bool = false
    @Published var mistakeCount: Int = 0
    @Published var isGameOver: Bool = false
    @Published var difficulty: Difficulty
    @Published var elapsedTime: TimeInterval = 0
    @Published var isPaused: Bool = false
    private var timer: Timer?

    private(set) var solution: [[Int]]
    private var solutions: [[[Int]]] // Add this line
    private var mistakeCells: Set<CellPosition> = []
    private var mistakeNumbers: Set<Int> = []
    
    @Published var isLoading: Bool = false
    @Published var showNotes: Bool = false
    private(set) var undoStack: [(CellPosition, Int?)] = []

    @Published var hasOngoingGame: Bool = false

    @Published var bestTimes: [Difficulty: TimeInterval] = [:]
    @Published var gamesWon: [Difficulty: Int] = [:]
    @Published var gamesPlayed: [Difficulty: Int] = [:]
    
    private let defaults = UserDefaults.standard

    @Published var hintsRemaining: Int = 3
    @Published var showingHint: Bool = false
    private var hintCell: CellPosition?

    private let haptics = UINotificationFeedbackGenerator()
    private let selectionHaptics = UISelectionFeedbackGenerator()

    init(difficulty: Difficulty) {
        self.difficulty = difficulty
        self.grid = Array(repeating: Array(repeating: nil, count: 9), count: 9)
        self.notes = Array(repeating: Array(repeating: Array(repeating: false, count: 9), count: 9), count: 9)
        self.solutions = []
        self.solution = []
        self.isLoading = true
        self.hasOngoingGame = false
        
        // Load saved statistics
        loadStatistics()
        // Try to restore saved game
        loadSavedGame()

        self.hintsRemaining = 3
    }

    func initialize() async {
        await self.newGame(difficulty: self.difficulty)
    }

    @MainActor
    private func generateInitialPuzzle() async {
        self.isLoading = true
        await generateSolutions()
        self.solution = self.solutions.randomElement()!
        self.grid = SudokuGenerator.createPuzzle(from: self.solution, difficulty: self.difficulty)
        self.notes = Array(repeating: Array(repeating: Array(repeating: false, count: 9), count: 9), count: 9)
        self.isLoading = false
    }
    
    private func generateSolutions() async {
        self.solutions = await withTaskGroup(of: [[Int]].self) { group in
            for _ in 0..<10 {
                group.addTask {
                    SudokuGenerator.generateSolution()
                }
            }
            
            var solutions = [[[Int]]]()
            for await solution in group {
                solutions.append(solution)
            }
            return solutions
        }
    }

    func newGame(difficulty: Difficulty) async {
        hintsRemaining = 3
        showingHint = false
        hintCell = nil
        gamesPlayed[difficulty, default: 0] += 1
        saveStatistics()
        clearSavedGame()
        
        await MainActor.run {
            self.isLoading = true
            self.difficulty = difficulty
        }
        
        do {
            let newSolution = try await generateNewSolution()
            let newGrid = SudokuGenerator.createPuzzle(from: newSolution, difficulty: difficulty)
            
            await MainActor.run {
                self.solution = newSolution
                self.grid = newGrid
                self.selectedCell = nil
                self.selectedNumber = nil
                self.isNoteMode = false
                self.mistakeCount = 0
                self.isGameOver = false
                self.mistakeCells.removeAll()
                self.mistakeNumbers.removeAll()
                self.notes = Array(repeating: Array(repeating: Array(repeating: false, count: 9), count: 9), count: 9)
                self.isLoading = false
                self.hasOngoingGame = true
            }
        } catch {
            await MainActor.run {
                print("Error generating new game: \(error)")
                self.isLoading = false
            }
        }
    }
    
    private func generateNewSolution() async throws -> [[Int]] {
        if solutions.isEmpty {
            await generateSolutions()
        }
        guard let newSolution = solutions.randomElement() else {
            throw SudokuError.noSolutionAvailable
        }
        return newSolution
    }
    
    func selectCell(row: Int, col: Int) {
        selectedCell = CellPosition(row: row, col: col)
        selectedNumber = grid[row][col]
        selectionHaptics.selectionChanged()
    }
    
    func setNumber(_ number: Int) {
        guard let cell = selectedCell, !isGameOver, !isPaused else { return }
        
        if grid[cell.row][cell.col] == nil && !isNoteMode {
            undoStack.append((cell, nil))
        }

        if isNoteMode {
            notes[cell.row][cell.col][number - 1].toggle()
            selectionHaptics.selectionChanged()
        } else {
            if let previousNumber = grid[cell.row][cell.col], previousNumber != number {
                undoStack.append((cell, previousNumber))
            }
            grid[cell.row][cell.col] = number
            selectedNumber = number

            if solution[cell.row][cell.col] != number {
                mistakeCount += 1
                mistakeCells.insert(cell)
                mistakeNumbers.insert(number)
                haptics.notificationOccurred(.error)
                
                if mistakeCount >= 3 {
                    isGameOver = true
                    isPaused = true
                    timer?.invalidate()
                    haptics.notificationOccurred(.error)
                }
            } else {
                mistakeCells.remove(cell)
                if !isMistakeNumberElsewhere(number) {
                    mistakeNumbers.remove(number)
                }
                haptics.notificationOccurred(.success)
                
                if checkWinCondition() {
                    isGameOver = true
                    isPaused = true
                    timer?.invalidate()
                    haptics.notificationOccurred(.success)
                    
                    // Update statistics
                    gamesWon[difficulty, default: 0] += 1
                    if bestTimes[difficulty] == nil || elapsedTime < bestTimes[difficulty]! {
                        bestTimes[difficulty] = elapsedTime
                    }
                    saveStatistics()
                    clearSavedGame()
                } else {
                    saveGameState()
                }
            }
        }
    }

    func toggleNotes() {
        isNoteMode.toggle()
    }

    func undo() {
        guard let (lastCell, previousNumber) = undoStack.popLast() else { return }

        // If we're undoing a mistake, decrement the mistake count and update related sets
        if let previousNumber = previousNumber, solution[lastCell.row][lastCell.col] != previousNumber {
            mistakeCount -= 1
            mistakeCells.remove(lastCell)
            if !isMistakeNumberElsewhere(previousNumber) {
                mistakeNumbers.remove(previousNumber)
            }
        } else if previousNumber == nil, let currentNumber = grid[lastCell.row][lastCell.col], solution[lastCell.row][lastCell.col] != currentNumber {
            // If we're undoing a correct move that was a mistake before, add back to mistake sets
            mistakeCount += 1
            mistakeCells.insert(lastCell)
            mistakeNumbers.insert(currentNumber)
        }

        grid[lastCell.row][lastCell.col] = previousNumber
        // You might need to update selectedNumber here depending on your game logic
    }
    
    func clearCell() {
        guard let cell = selectedCell else { return }
        if let number = grid[cell.row][cell.col] {
            mistakeCells.remove(cell)
            if !isMistakeNumberElsewhere(number) {
                mistakeNumbers.remove(number)
            }
        }
        grid[cell.row][cell.col] = nil
        notes[cell.row][cell.col] = Array(repeating: false, count: 9)
        selectedNumber = nil
    }
    
    func shouldHighlight(row: Int, col: Int) -> Bool {
        guard let selectedCell = selectedCell else { return false }
        return row == selectedCell.row || col == selectedCell.col
    }
    
    func isSelectedNumber(_ number: Int?) -> Bool {
        return selectedNumber == number
    }
    
    func isMistake(row: Int, col: Int) -> Bool {
        return mistakeCells.contains(CellPosition(row: row, col: col))
    }
    
    func isMistakeNumber(_ number: Int) -> Bool {
        return mistakeNumbers.contains(number)
    }
    
    private func isMistakeNumberElsewhere(_ number: Int) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == number && solution[row][col] != number && CellPosition(row: row, col: col) != selectedCell {
                    return true
                }
            }
        }
        return false
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }
            self.elapsedTime += 1
        }
    }

    func pauseGame() {
        isPaused = true
    }

    func resumeGame() {
        isPaused = false
    }

    func resetGame() {
        hintsRemaining = 3
        showingHint = false
        hintCell = nil
        clearSavedGame()
        elapsedTime = 0
        mistakeCount = 0
        isGameOver = false
        isPaused = false
        timer?.invalidate()
        timer = nil
    }

    func isGameInProgress() -> Bool {
        return !grid.flatMap { $0 }.compactMap { $0 }.isEmpty && !isGameOver
    }

    private func checkWinCondition() -> Bool {
        // Check if all cells are filled
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == nil {
                    return false
                }
                if grid[row][col] != solution[row][col] {
                    return false
                }
            }
        }
        return true
    }

    private func loadStatistics() {
        if let savedBestTimes = defaults.dictionary(forKey: "SudokuBestTimes") as? [String: TimeInterval] {
            bestTimes = Dictionary(uniqueKeysWithValues: savedBestTimes.compactMap { key, value in
                guard let difficulty = Difficulty(rawValue: key) else { return nil }
                return (difficulty, value)
            })
        }
        
        if let savedGamesWon = defaults.dictionary(forKey: "SudokuGamesWon") as? [String: Int] {
            gamesWon = Dictionary(uniqueKeysWithValues: savedGamesWon.compactMap { key, value in
                guard let difficulty = Difficulty(rawValue: key) else { return nil }
                return (difficulty, value)
            })
        }
        
        if let savedGamesPlayed = defaults.dictionary(forKey: "SudokuGamesPlayed") as? [String: Int] {
            gamesPlayed = Dictionary(uniqueKeysWithValues: savedGamesPlayed.compactMap { key, value in
                guard let difficulty = Difficulty(rawValue: key) else { return nil }
                return (difficulty, value)
            })
        }
    }
    
    private func saveStatistics() {
        let bestTimesDict = Dictionary(uniqueKeysWithValues: bestTimes.map { ($0.key.rawValue, $0.value) })
        let gamesWonDict = Dictionary(uniqueKeysWithValues: gamesWon.map { ($0.key.rawValue, $0.value) })
        let gamesPlayedDict = Dictionary(uniqueKeysWithValues: gamesPlayed.map { ($0.key.rawValue, $0.value) })
        
        defaults.set(bestTimesDict, forKey: "SudokuBestTimes")
        defaults.set(gamesWonDict, forKey: "SudokuGamesWon")
        defaults.set(gamesPlayedDict, forKey: "SudokuGamesPlayed")
    }
    
    private func loadSavedGame() {
        guard let savedGrid = defaults.array(forKey: "SudokuGrid") as? [[Int?]],
              let savedNotes = defaults.array(forKey: "SudokuNotes") as? [[[Bool]]],
              let savedDifficulty = defaults.string(forKey: "SudokuDifficulty"),
              let difficulty = Difficulty(rawValue: savedDifficulty),
              let savedSolution = defaults.array(forKey: "SudokuSolution") as? [[Int]],
              let savedTime = defaults.object(forKey: "SudokuTime") as? TimeInterval,
              let savedMistakes = defaults.integer(forKey: "SudokuMistakes") as Int? else {
            return
        }
        
        self.grid = savedGrid
        self.notes = savedNotes
        self.difficulty = difficulty
        self.solution = savedSolution
        self.elapsedTime = savedTime
        self.mistakeCount = savedMistakes
        self.hasOngoingGame = true
    }
    
    private func saveGameState() {
        defaults.set(grid, forKey: "SudokuGrid")
        defaults.set(notes, forKey: "SudokuNotes")
        defaults.set(difficulty.rawValue, forKey: "SudokuDifficulty")
        defaults.set(solution, forKey: "SudokuSolution")
        defaults.set(elapsedTime, forKey: "SudokuTime")
        defaults.set(mistakeCount, forKey: "SudokuMistakes")
    }
    
    private func clearSavedGame() {
        defaults.removeObject(forKey: "SudokuGrid")
        defaults.removeObject(forKey: "SudokuNotes")
        defaults.removeObject(forKey: "SudokuDifficulty")
        defaults.removeObject(forKey: "SudokuSolution")
        defaults.removeObject(forKey: "SudokuTime")
        defaults.removeObject(forKey: "SudokuMistakes")
    }

    func requestHint() {
        guard hintsRemaining > 0, !isGameOver else {
            haptics.notificationOccurred(.error)
            return
        }
        
        // Find the first empty cell or incorrect cell
        var hintPosition: CellPosition?
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == nil || grid[row][col] != solution[row][col] {
                    hintPosition = CellPosition(row: row, col: col)
                    break
                }
            }
            if hintPosition != nil { break }
        }
        
        guard let position = hintPosition else { return }
        
        hintsRemaining -= 1
        hintCell = position
        showingHint = true
        selectedCell = position
        haptics.notificationOccurred(.warning)
    }
    
    func isHintCell(row: Int, col: Int) -> Bool {
        guard showingHint, let hintCell = hintCell else { return false }
        return row == hintCell.row && col == hintCell.col
    }
    
    // Keyboard navigation
    func handleKeyPress(_ key: String) {
        switch key {
        case "1"..."9":
            if let number = Int(key) {
                setNumber(number)
            }
        case " ", "n":
            toggleNotes()
        case "h":
            requestHint()
        case "delete", "backspace":
            clearCell()
        case "up", "down", "left", "right":
            moveSelection(direction: key)
        default:
            break
        }
    }
    
    private func moveSelection(direction: String) {
        guard let current = selectedCell else {
            selectedCell = CellPosition(row: 0, col: 0)
            return
        }
        
        var newRow = current.row
        var newCol = current.col
        
        switch direction {
        case "up":
            newRow = (newRow - 1 + 9) % 9
        case "down":
            newRow = (newRow + 1) % 9
        case "left":
            newCol = (newCol - 1 + 9) % 9
        case "right":
            newCol = (newCol + 1) % 9
        default:
            break
        }
        
        selectedCell = CellPosition(row: newRow, col: newCol)
    }
}

enum Difficulty: String, CaseIterable {
    case easy, medium, hard, expert, extreme
}

enum SudokuError: Error {
    case noSolutionAvailable
}

struct SudokuGenerator {
    static func generateSolution() -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = solveSudoku(&grid)
        return grid
    }
    
    static func createPuzzle(from solution: [[Int]], difficulty: Difficulty) -> [[Int?]] {
        var puzzle = solution.map { $0.map { Int?($0) } }
        let cellsToRemove: Int
        
        switch difficulty {
        case .easy: cellsToRemove = 35
        case .medium: cellsToRemove = 45
        case .hard: cellsToRemove = 52
        case .expert: cellsToRemove = 58
        case .extreme: cellsToRemove = 64
        }
        
        let cellsToKeep = 81 - cellsToRemove
        var keptCells = [(Int, Int)]()
        
        // Keep a minimum number of cells to ensure a valid puzzle
        while keptCells.count < cellsToKeep {
            let row = Int.random(in: 0..<9)
            let col = Int.random(in: 0..<9)
            if puzzle[row][col] != nil && !keptCells.contains(where: { $0 == (row, col) }) {
                keptCells.append((row, col))
            }
        }
        
        // Remove all cells except the kept ones
        for row in 0..<9 {
            for col in 0..<9 {
                if !keptCells.contains(where: { $0 == (row, col) }) {
                    puzzle[row][col] = nil
                }
            }
        }
        
        return puzzle
    }
    
    private static func solveSudoku(_ grid: inout [[Int]]) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == 0 {
                    for num in 1...9 {
                        if isValid(grid, row, col, num) {
                            grid[row][col] = num
                            if solveSudoku(&grid) {
                                return true
                            }
                            grid[row][col] = 0
                        }
                    }
                    return false
                }
            }
        }
        return true
    }
    
    private static func isValid(_ grid: [[Int]], _ row: Int, _ col: Int, _ num: Int) -> Bool {
        for x in 0..<9 {
            if grid[row][x] == num { return false }
        }
        
        for x in 0..<9 {
            if grid[x][col] == num { return false }
        }
        
        let startRow = row - row % 3, startCol = col - col % 3
        for i in 0..<3 {
            for j in 0..<3 {
                if grid[i + startRow][j + startCol] == num { return false }
            }
        }
        
        return true
    }
    
    private static func hasUniqueSolution(_ puzzle: [[Int?]]) -> Bool {
        var grid = puzzle.map { $0.map { $0 ?? 0 } }
        var solutionCount = 0
        
        func solve(_ row: Int, _ col: Int) {
            if row == 9 {
                solutionCount += 1
                return
            }
            
            let nextRow = col == 8 ? row + 1 : row
            let nextCol = col == 8 ? 0 : col + 1
            
            if grid[row][col] != 0 {
                solve(nextRow, nextCol)
            } else {
                for num in 1...9 {
                    if isValid(grid, row, col, num) {
                        grid[row][col] = num
                        solve(nextRow, nextCol)
                        if solutionCount > 1 { return }
                        grid[row][col] = 0
                    }
                }
            }
        }
        
        solve(0, 0)
        return solutionCount == 1
    }
}
