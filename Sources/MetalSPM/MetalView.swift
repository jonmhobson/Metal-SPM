import SwiftUI
import MetalKit

struct Vertex {
    let position: vector_float2
    let color: vector_float4
}

enum VertexInputIndex: Int {
    case vertices = 0
    case viewportSize = 1
}

public class MetalViewInteractor: NSObject, ObservableObject {
    let metalView = MTKView()
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private var viewportSize: vector_uint2 = [0, 0]

    public override init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else { fatalError() }

        self.device = device
        self.commandQueue = commandQueue

        metalView.device = device
        metalView.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.6, alpha: 1.0)

        guard let libraryURL = Bundle.module.url(forResource: "default", withExtension: "metallib"),
              let defaultLibrary = try? device.makeLibrary(URL: libraryURL),
              let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader"),
              let fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShader") else {
            fatalError()
        }

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "Simple Pipeline"
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat

        self.pipelineState = {
            do {
                return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
            } catch {
                fatalError()
            }
        }()

        super.init()

        metalView.delegate = self
    }
}

extension MetalViewInteractor: MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize = [UInt32(size.width), UInt32(size.height)]
    }

    static let triangleVertices: [Vertex] = [
        Vertex(position: [250, -200], color: [1, 0, 0, 1]),
        Vertex(position: [-250, -200], color: [0, 1, 0, 1]),
        Vertex(position: [0, 200], color: [0, 0, 1, 1]),
    ]

    public func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBytes(
            Self.triangleVertices,
            length: Self.triangleVertices.count * MemoryLayout<Vertex>.stride,
            index: VertexInputIndex.vertices.rawValue
        )
        renderEncoder.setVertexBytes(
            &viewportSize,
            length: MemoryLayout<vector_uint2>.stride,
            index: VertexInputIndex.viewportSize.rawValue
        )
        renderEncoder.drawPrimitives(
            type: .triangle,
            vertexStart: 0, vertexCount: 3
        )

        renderEncoder.endEncoding()

        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }

        commandBuffer.commit()
    }
}

struct MetalViewRepresentable: NSViewRepresentable {
    let metalView: MTKView
    func makeNSView(context: Context) -> MTKView { metalView }
    func updateNSView(_ nsView: MTKView, context: Context) {}
    typealias NSViewType = MTKView
}

public struct ContentView: View {
    @StateObject var viewInteractor: MetalViewInteractor

    public init(viewInteractor: MetalViewInteractor = MetalViewInteractor()) {
        self._viewInteractor = StateObject(wrappedValue: viewInteractor)
    }

    public var body: some View {
        VStack {
            MetalViewRepresentable(metalView: viewInteractor.metalView)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
