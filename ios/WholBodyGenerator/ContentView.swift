import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var vm = GeneratorViewModel()
    @State private var selectedItem: PhotosPickerItem?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Face photo picker
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        FacePickerCard(image: vm.faceImage)
                    }
                    .onChange(of: selectedItem) { _, item in
                        Task { await vm.loadImage(from: item) }
                    }

                    // Optional prompt
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Custom prompt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("e.g. wearing a blue jacket, outdoor", text: $vm.customPrompt)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                    }
                    .padding(.horizontal)

                    // Generate button
                    Button {
                        Task { await vm.generate() }
                    } label: {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text(vm.isGenerating ? "Generating…" : "Generate Full Body")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(vm.canGenerate ? Color.accentColor : Color.secondary.opacity(0.4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!vm.canGenerate)
                    .padding(.horizontal)
                    .animation(.easeInOut(duration: 0.2), value: vm.canGenerate)

                    // Result image
                    if let result = vm.resultImage {
                        ResultCard(image: result) {
                            showShareSheet = true
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle("Body Generator")
            .overlay {
                if vm.isGenerating { GeneratingOverlay() }
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { vm.showError },
                set: { if !$0 { vm.dismissError() } }
            )) {
                Button("OK", role: .cancel) { vm.dismissError() }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .sheet(isPresented: $showShareSheet) {
                if let result = vm.resultImage {
                    ShareSheet(items: [result])
                }
            }
        }
    }
}

// MARK: - Sub-views

struct FacePickerCard: View {
    let image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .frame(height: 220)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "person.crop.square.badge.plus")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("Tap to select a face photo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .overlay(alignment: .topTrailing) {
            if image != nil {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white, Color.accentColor)
                    .padding(20)
            }
        }
    }
}

struct ResultCard: View {
    let image: UIImage
    let onShare: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Generated")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .shadow(radius: 6, y: 3)

            Button(action: onShare) {
                Label("Save / Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
    }
}

struct GeneratingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.6)
                    .tint(.white)
                Text("Generating full body…")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Text("~20 seconds")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
