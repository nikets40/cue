import CueKit
import SwiftUI

/// VLC's playlist, pulled on demand. Tapping an entry jumps VLC to it.
struct PlaylistSheet: View {
    @EnvironmentObject private var client: CueClient
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if client.playlistLoading && client.playlist == nil {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let items = client.playlist, !items.isEmpty {
                    List(items) { item in
                        Button {
                            client.send(.playPlaylistItem, value: Double(item.id))
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.isCurrent ? "speaker.wave.2.fill" : "music.note")
                                    .font(.footnote)
                                    .foregroundStyle(item.isCurrent ? .white : .white.opacity(0.4))
                                    .frame(width: 20)
                                Text(item.title)
                                    .lineLimit(1)
                                    .foregroundStyle(item.isCurrent ? .white : .white.opacity(0.85))
                                Spacer()
                                if let duration = item.duration {
                                    Text(RemoteView.timeString(duration))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .listRowBackground(Color.white.opacity(item.isCurrent ? 0.10 : 0.04))
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 36))
                            .foregroundStyle(.white.opacity(0.4))
                        Text("No playlist available")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Cue Booth reaches VLC through its web interface. Enable it in VLC's preferences, then restart VLC.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(BackdropView(artwork: nil, brand: nil))
            .navigationTitle("Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}
