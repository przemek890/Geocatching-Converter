import SwiftUI

struct AlphabetConfigTabView: View {
    @ObservedObject var alphabetViewModel: AlphabetViewModel

    var body: some View {
        NavigationView {
            AlphabetConfigView(
                alphabet: alphabetViewModel.currentAlphabet,
                letterNumbers: $alphabetViewModel.letterNumbers,
                letterImages: $alphabetViewModel.letterImages,
                onSave: {
                    alphabetViewModel.saveLetterData()
                }
            )
            .id(alphabetViewModel.selectedAlphabet)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
