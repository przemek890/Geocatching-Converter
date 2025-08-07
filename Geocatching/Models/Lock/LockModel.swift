struct LockModel {
    var enteredLetters: String = ""
    var lockDigits: Int = 4
    
    func getLettersArray(lockDigits: Int = 4) -> [String] {
        let letters = Array(enteredLetters)
        return (0..<lockDigits).map { i in
            i < letters.count ? String(letters[i]) : ""
        }
    }
    
    func generateCode(using alphabetViewModel: AlphabetViewModel) -> String {
        return getLettersArray().map { letter in
            let upper = letter.uppercased()
            if alphabetViewModel.currentAlphabet.contains(upper),
               let number = alphabetViewModel.letterNumbers[upper],
               !number.isEmpty {
                return number
            } else {
                return "_"
            }
        }.joined()
    }
}