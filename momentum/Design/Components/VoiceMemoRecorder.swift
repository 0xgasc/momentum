import SwiftUI
import AVFoundation
import Combine

// MARK: - Voice Memo Manager

@MainActor
class VoiceMemoManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var hasRecording = false
    @Published var isPlaying = false
    @Published var permissionDenied = false

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingURL: URL?
    private var timer: Timer?

    override init() {
        super.init()
    }

    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func requestPermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func startRecording() {
        Task {
            let granted = await requestPermission()

            await MainActor.run {
                if granted {
                    beginRecording()
                } else {
                    permissionDenied = true
                }
            }
        }
    }

    private func beginRecording() {
        // Generate unique filename
        let fileName = "voice_memo_\(UUID().uuidString).m4a"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent(fileName)

        guard let url = recordingURL else { return }

        // Configure audio session
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }

        // Recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true
            recordingDuration = 0

            // Start timer for duration
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.recordingDuration += 0.1
                }
            }

            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecording() -> String? {
        timer?.invalidate()
        timer = nil

        audioRecorder?.stop()
        isRecording = false
        hasRecording = recordingURL != nil

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        return recordingURL?.lastPathComponent
    }

    func playRecording() {
        guard let url = recordingURL else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play recording: \(error)")
        }
    }

    func stopPlaying() {
        audioPlayer?.stop()
        isPlaying = false
    }

    func deleteRecording() {
        stopPlaying()

        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }

        recordingURL = nil
        hasRecording = false
        recordingDuration = 0
    }

    func loadExisting(path: String?) {
        guard let path = path else {
            hasRecording = false
            return
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsPath.appendingPathComponent(path)

        if FileManager.default.fileExists(atPath: url.path) {
            recordingURL = url
            hasRecording = true

            // Get duration
            if let player = try? AVAudioPlayer(contentsOf: url) {
                recordingDuration = player.duration
            }
        }
    }
}

extension VoiceMemoManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
        }
    }
}

// MARK: - Voice Memo Recorder View

struct VoiceMemoRecorderView: View {
    @Binding var voiceMemoPath: String?
    @StateObject private var recorder = VoiceMemoManager()

    var body: some View {
        VStack(spacing: Spacing.sm) {
            if recorder.isRecording {
                // Recording in progress
                VStack(spacing: Spacing.xs) {
                    // Pulsing record indicator
                    ZStack {
                        Circle()
                            .fill(Color.momentum.coral.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .scaleEffect(recorder.isRecording ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: recorder.isRecording)

                        Circle()
                            .fill(Color.momentum.coral)
                            .frame(width: 60, height: 60)

                        Image(systemName: "waveform")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }

                    Text(recorder.formattedDuration)
                        .font(.titleSmall)
                        .foregroundColor(Color.momentum.charcoal)
                        .monospacedDigit()

                    Button {
                        voiceMemoPath = recorder.stopRecording()
                    } label: {
                        Text("Stop Recording")
                            .font(.bodySmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.momentum.coral)
                            .clipShape(Capsule())
                    }
                }
            } else if recorder.hasRecording {
                // Has recording - show playback controls
                VStack(spacing: Spacing.sm) {
                    HStack(spacing: Spacing.md) {
                        // Play/Stop button
                        Button {
                            if recorder.isPlaying {
                                recorder.stopPlaying()
                            } else {
                                recorder.playRecording()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.momentum.sage.opacity(0.15))
                                    .frame(width: 50, height: 50)

                                Image(systemName: recorder.isPlaying ? "stop.fill" : "play.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.momentum.sage)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Voice Memo")
                                .font(.bodySmall)
                                .foregroundColor(Color.momentum.charcoal)

                            Text(recorder.formattedDuration)
                                .font(.caption)
                                .foregroundColor(Color.momentum.gray)
                                .monospacedDigit()
                        }

                        Spacer()

                        // Delete button
                        Button {
                            recorder.deleteRecording()
                            voiceMemoPath = nil
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(Color.momentum.coral)
                        }
                    }
                    .padding(Spacing.sm)
                    .background(Color.momentum.cream)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                }
            } else {
                // No recording - show record button
                Button {
                    recorder.startRecording()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.momentum.coral)

                        Text("Voice")
                            .font(.bodySmall)
                            .foregroundColor(Color.momentum.charcoal)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.momentum.cream)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                }
            }

            if recorder.permissionDenied {
                Text("Microphone access denied. Enable in Settings.")
                    .font(.caption)
                    .foregroundColor(Color.momentum.coral)
            }
        }
        .onAppear {
            recorder.loadExisting(path: voiceMemoPath)
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        VoiceMemoRecorderView(voiceMemoPath: .constant(nil))

        Divider()

        VoiceMemoRecorderView(voiceMemoPath: .constant("test.m4a"))
    }
    .padding()
    .background(Color.momentum.white)
}
