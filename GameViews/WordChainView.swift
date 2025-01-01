import SwiftUI

struct WordChainView: View {
    @State private var currentWord = ""
    @State private var userInput = ""
    @State private var score = 0
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let startWords = ["swift", "kotlin", "java", "python", "ruby", "golang"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Word Chain")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Enter a word that starts with:")
                .font(.title2)
            
            Text(currentWord.suffix(1).uppercased())
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
            
            TextField("Enter your word", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding()
            
            Button("Submit") {
                checkAnswer()
            }
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Text("Current word: \(currentWord)")
                .font(.title3)
            
            Text("Score: \(score)")
                .font(.title)
        }
        .padding()
        .onAppear(perform: newGame)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Game Over"),
                message: Text(alertMessage),
                dismissButton: .default(Text("New Game")) {
                    newGame()
                }
            )
        }
    }
    
    func newGame() {
        currentWord = startWords.randomElement() ?? "swift"
        userInput = ""
        score = 0
    }
    
    func checkAnswer() {
        let trimmedInput = userInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedInput.isEmpty else {
            alertMessage = "Please enter a word."
            showAlert = true
            return
        }
        
        guard trimmedInput.first == currentWord.last else {
            alertMessage = "Your word must start with the last letter of the current word."
            showAlert = true
            return
        }
        
        guard trimmedInput != currentWord else {
            alertMessage = "You can't use the same word."
            showAlert = true
            return
        }
        
        // Here you would ideally check if the word is valid (e.g., exists in a dictionary)
        // For simplicity, we'll assume all words are valid
        
        score += 1
        currentWord = trimmedInput
        userInput = ""
    }
}

struct WordChainView_Previews: PreviewProvider {
    static var previews: some View {
        WordChainView()
    }
}