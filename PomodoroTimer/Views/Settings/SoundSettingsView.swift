import SwiftUI

struct SoundSettingsView: View {
    @Environment(SettingsViewModel.self) private var settingsVM
    @Environment(AudioService.self) private var audio

    var body: some View {
        @Bindable var vm = settingsVM

        Form {
            Section("Ambient Sound") {
                Toggle("Enable ambient sound during focus", isOn: $vm.settings.ambientSoundEnabled)

                if settingsVM.settings.ambientSoundEnabled {
                    Picker("Sound", selection: $vm.settings.selectedAmbientSound) {
                        ForEach(AmbientSound.allCases) { sound in
                            Text(sound.displayName).tag(sound)
                        }
                    }

                    HStack {
                        Image(systemName: "speaker.fill")
                        Slider(value: $vm.settings.ambientVolume, in: 0...1)
                        Image(systemName: "speaker.wave.3.fill")
                    }

                    HStack {
                        Spacer()
                        Button("Preview") {
                            audio.preview(
                                sound: settingsVM.settings.selectedAmbientSound,
                                volume: settingsVM.settings.ambientVolume
                            )
                        }
                        Button("Stop") { audio.stop() }
                        Spacer()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: settingsVM.settings.ambientVolume) { _, newVolume in
            audio.setVolume(newVolume)
        }
    }
}
