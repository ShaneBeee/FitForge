import SwiftUI
import AVFoundation

/// Lets the user preview and choose the voice used for workout prompts.
struct VoicePickerView: View {
    @AppStorage(VoiceCoach.voiceDefaultsKey) private var selectedID = ""
    @State private var coach = VoiceCoach()
    @State private var voices: [AVSpeechSynthesisVoice] = []

    private let sampleLine = "Rest's up. Set 2 of 3. You've got this."

    /// The voice actually in use (the automatic pick if nothing was chosen).
    private var activeID: String? {
        selectedID.isEmpty ? VoiceCoach.bestAvailableVoice()?.identifier : selectedID
    }

    var body: some View {
        List {
            Section {
                Button {
                    selectedID = ""
                    coach.speak(sampleLine, voice: VoiceCoach.bestAvailableVoice())
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Automatic")
                                .foregroundStyle(.primary)
                            Text("The best-quality voice on this phone")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedID.isEmpty {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.blue)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }

            ForEach(["Premium", "Enhanced", "Standard"], id: \.self) { quality in
                let group = voices.filter { $0.qualityLabel == quality }
                if !group.isEmpty {
                    Section(quality) {
                        ForEach(group, id: \.identifier) { voice in
                            voiceRow(voice)
                        }
                    }
                }
            }

            Section {
                Text("Want more natural voices? Download free Premium or Enhanced voices in **Settings → Accessibility → Read & Speak → Voices → English**, then come back here. Siri's own voices can't be used by other apps.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Coach voice")
        .onAppear { voices = VoiceCoach.availableVoices }
        .onDisappear { coach.stop() }
    }

    private func voiceRow(_ voice: AVSpeechSynthesisVoice) -> some View {
        Button {
            selectedID = voice.identifier
            coach.speak(sampleLine, voice: voice)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(voice.name)
                        .foregroundStyle(.primary)
                    Text(voice.languageLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "speaker.wave.2")
                    .foregroundStyle(.secondary)
                if !selectedID.isEmpty && voice.identifier == activeID {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Theme.blue)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
