import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var scannedCode: String = "Not scanned yet"
    @State private var isShowingScanner = false
    @State private var showPermissionAlert = false  // Alert for denied permissions
    @State private var productInfo: String = "No product information available"  // NEW: Stores product details

    var body: some View {
        ZStack {
            // Background color
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.green.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 80) {
                // App title
                Text("EcoTrack Barcode Scanner")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()

                // Modern styled button
                Button(action: {
                    checkCameraPermission()
                }) {
                    HStack {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title)
                        Text("Start Scanning")
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }
                .padding(.horizontal, 30)

                // Centered scanned code result
                VStack {
                    Text("Scanned Code:")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                    Text(scannedCode)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .padding()
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 20)

                // NEW: Display product information after fetching from API
                VStack {
                    Text("Product Information:")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                    Text(productInfo)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 50)
            .frame(maxHeight: .infinity, alignment: .center)
        }
        // Present the barcode scanner view
        .sheet(isPresented: $isShowingScanner, onDismiss: fetchProductInfo) {  // NEW: Call API when scanner closes
            BarcodeScannerView(scannedCode: $scannedCode)
        }
        // Show an alert if the user denied camera permission
        .alert("Camera Access Denied", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To scan barcodes, please allow camera access in Settings.")
        }
    }

    // NEW: Fetch product info using OpenFoodFacts API
    func fetchProductInfo() {
        guard scannedCode != "Not scanned yet" else { return }

        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(scannedCode).json"
        guard let url = URL(string: urlString) else {
            productInfo = "Invalid URL"
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    productInfo = "Error fetching data: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    productInfo = "No data received"
                }
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let product = json?["product"] as? [String: Any],
                   let productName = product["product_name"] as? String,
                   let brand = product["brands"] as? String {
                    DispatchQueue.main.async {
                        productInfo = "Name: \(productName)\nBrand: \(brand)"
                    }
                } else {
                    DispatchQueue.main.async {
                        productInfo = "Product not found"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    productInfo = "Error parsing data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    // Function to check camera permission
    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        isShowingScanner = true
                    } else {
                        showPermissionAlert = true
                    }
                }
            }
        case .restricted, .denied:
            showPermissionAlert = true
        case .authorized:
            isShowingScanner = true
        @unknown default:
            print("Unknown camera permission status")
        }
    }

    // Function to open app settings
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ContentView()
}
