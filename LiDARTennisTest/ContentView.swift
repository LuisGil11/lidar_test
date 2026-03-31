//
//  ContentView.swift
//  LiDAR Tennis Ball Test
//
//  App simple para probar deteccion de pelota de tenis con LiDAR
//

import SwiftUI
import ARKit
import RealityKit

struct ContentView: View {
    @StateObject private var arViewModel = ARViewModel()
    
    var body: some View {
        ZStack {
            // Vista AR con LiDAR
            ARViewContainer(arViewModel: arViewModel)
                .edgesIgnoringSafeArea(.all)
            
            // Overlay con informacion
            VStack {
                // Header
                VStack(spacing: 8) {
                    Text("LiDAR Tennis Ball Test")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                    
                    // Estado del LiDAR
                    HStack(spacing: 12) {
                        Circle()
                            .fill(arViewModel.isLiDARAvailable ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text(arViewModel.isLiDARAvailable ? "LiDAR Activo" : "LiDAR No Disponible")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Panel de informacion
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(label: "Distancia", value: String(format: "%.2f m", arViewModel.centerDistance))
                    InfoRow(label: "Puntos LiDAR", value: "\(arViewModel.pointCount)")
                    InfoRow(label: "Confianza", value: String(format: "%.0f%%", arViewModel.confidence * 100))
                    
                    if arViewModel.ballDetected {
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 16, height: 16)
                            Text("Pelota Detectada")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Posicion 3D
                    if let pos = arViewModel.ballPosition {
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        Text("Posicion 3D:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        InfoRow(label: "X", value: String(format: "%.3f m", pos.x))
                        InfoRow(label: "Y", value: String(format: "%.3f m", pos.y))
                        InfoRow(label: "Z", value: String(format: "%.3f m", pos.z))
                    }
                }
                .padding(20)
                .background(Color.black.opacity(0.8))
                .cornerRadius(15)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            
            // Cruz en el centro para apuntar
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "scope")
                        .font(.system(size: 40))
                        .foregroundColor(.green.opacity(0.7))
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var arViewModel: ARViewModel
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configurar sesion AR con LiDAR
        let configuration = ARWorldTrackingConfiguration()
        
        // Habilitar scene depth (LiDAR)
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        // Habilitar frame semantics para depth
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        
        arView.session.run(configuration)
        arView.session.delegate = context.coordinator
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(arViewModel: arViewModel)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var arViewModel: ARViewModel
        
        init(arViewModel: ARViewModel) {
            self.arViewModel = arViewModel
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // Procesar frame con datos de profundidad
            arViewModel.processFrame(frame)
        }
    }
}

class ARViewModel: NSObject, ObservableObject {
    @Published var isLiDARAvailable = false
    @Published var centerDistance: Float = 0.0
    @Published var pointCount: Int = 0
    @Published var confidence: Float = 0.0
    @Published var ballDetected: Bool = false
    @Published var ballPosition: SIMD3<Float>?
    
    override init() {
        super.init()
        
        // Verificar si LiDAR esta disponible
        isLiDARAvailable = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) &&
                          ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
    }
    
    func processFrame(_ frame: ARFrame) {
        guard let sceneDepth = frame.sceneDepth else {
            return
        }
        
        let depthMap = sceneDepth.depthMap
        let confidenceMap = sceneDepth.confidenceMap
        
        // Obtener dimensiones
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        // Punto central de la imagen
        let centerX = width / 2
        let centerY = height / 2
        
        // Leer profundidad en el centro
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        if let baseAddress = CVPixelBufferGetBaseAddress(depthMap) {
            let rowBytes = CVPixelBufferGetBytesPerRow(depthMap)
            let buffer = baseAddress.assumingMemoryBound(to: Float32.self)
            
            let offset = centerY * (rowBytes / MemoryLayout<Float32>.stride) + centerX
            let depth = buffer[offset]
            
            DispatchQueue.main.async {
                self.centerDistance = depth
            }
        }
        
        // Leer confianza
        CVPixelBufferLockBaseAddress(confidenceMap!, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(confidenceMap!, .readOnly) }
        
        if let confAddress = CVPixelBufferGetBaseAddress(confidenceMap!) {
            let confRowBytes = CVPixelBufferGetBytesPerRow(confidenceMap!)
            let confBuffer = confAddress.assumingMemoryBound(to: UInt8.self)
            
            let confOffset = centerY * confRowBytes + centerX
            let confValue = confBuffer[confOffset]
            
            // Confidence: 0 = low, 1 = medium, 2 = high
            let normalizedConf = Float(confValue) / 2.0
            
            DispatchQueue.main.async {
                self.confidence = normalizedConf
            }
        }
        
        // Contar puntos validos en el depth map
        var validPoints = 0
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        
        if let baseAddress = CVPixelBufferGetBaseAddress(depthMap) {
            let rowBytes = CVPixelBufferGetBytesPerRow(depthMap)
            let buffer = baseAddress.assumingMemoryBound(to: Float32.self)
            
            // Samplear cada 10 pixeles para rendimiento
            for y in stride(from: 0, to: height, by: 10) {
                for x in stride(from: 0, to: width, by: 10) {
                    let offset = y * (rowBytes / MemoryLayout<Float32>.stride) + x
                    let depth = buffer[offset]
                    
                    if depth > 0 && depth < 5.0 {
                        validPoints += 1
                    }
                }
            }
        }
        
        CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
        
        DispatchQueue.main.async {
            self.pointCount = validPoints
        }
        
        // Deteccion simple de pelota
        // (objeto pequeno a distancia especifica)
        detectBall(depthMap: depthMap, confidenceMap: confidenceMap!)
    }
    
    func detectBall(depthMap: CVPixelBuffer, confidenceMap: CVPixelBuffer) {
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        // Buscar cluster pequeno de puntos a distancia similar
        // (caracteristica de pelota: objeto pequeno y redondo)
        
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else { return }
        
        let rowBytes = CVPixelBufferGetBytesPerRow(depthMap)
        let buffer = baseAddress.assumingMemoryBound(to: Float32.self)
        
        // Region central (donde apuntamos)
        let regionSize = 100
        let startX = max(0, width/2 - regionSize/2)
        let endX = min(width, width/2 + regionSize/2)
        let startY = max(0, height/2 - regionSize/2)
        let endY = min(height, height/2 + regionSize/2)
        
        var depths: [Float] = []
        
        for y in startY..<endY {
            for x in startX..<endX {
                let offset = y * (rowBytes / MemoryLayout<Float32>.stride) + x
                let depth = buffer[offset]
                
                if depth > 0.3 && depth < 5.0 {  // Rango valido
                    depths.append(depth)
                }
            }
        }
        
        if depths.count > 10 {
            // Calcular estadisticas
            let avgDepth = depths.reduce(0, +) / Float(depths.count)
            let variance = depths.map { pow($0 - avgDepth, 2) }.reduce(0, +) / Float(depths.count)
            let stdDev = sqrt(variance)
            
            // Pelota: cluster pequeno con baja varianza
            let isBall = stdDev < 0.05 && depths.count < 500
            
            DispatchQueue.main.async {
                self.ballDetected = isBall
                
                if isBall {
                    // Estimar posicion 3D en centro de la region
                    let x = Float(width/2 - width/2) / Float(width) * avgDepth
                    let y = Float(height/2 - height/2) / Float(height) * avgDepth
                    self.ballPosition = SIMD3<Float>(x, y, avgDepth)
                } else {
                    self.ballPosition = nil
                }
            }
        } else {
            DispatchQueue.main.async {
                self.ballDetected = false
                self.ballPosition = nil
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
