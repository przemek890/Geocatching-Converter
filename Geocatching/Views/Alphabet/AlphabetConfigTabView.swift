import SwiftUI

struct AlphabetConfigTabView: View {
    @ObservedObject var alphabetViewModel: AlphabetViewModel
    let snapshotID: String
    @State private var viewRefreshToggle = false
    @State private var isViewActive = false

    var body: some View {
        NavigationView {
            AlphabetConfigView(
                alphabet: alphabetViewModel.currentAlphabet,
                letterNumbers: $alphabetViewModel.letterNumbers,
                letterImages: $alphabetViewModel.letterImages,
                onSave: {
                    alphabetViewModel.saveLetterData(forSnapshotID: snapshotID)
                }
            )
            .id("\(alphabetViewModel.selectedAlphabet)_\(viewRefreshToggle)_\(snapshotID)")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            alphabetViewModel.loadLetterData(forSnapshotID: snapshotID)
            viewRefreshToggle.toggle()
        }
        .onDisappear {
            isViewActive = false
            alphabetViewModel.saveLetterData(forSnapshotID: snapshotID)
        }
    }
}
