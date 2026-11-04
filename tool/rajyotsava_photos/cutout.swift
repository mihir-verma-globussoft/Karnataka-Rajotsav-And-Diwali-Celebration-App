// Cuts the main subject out of a photo with Apple's Vision subject lifting
// (the same as "lift subject" in Photos) and saves it as a transparent PNG.
// Runs locally on macOS 14 or later; nothing is uploaded.
//
//   swift tool/rajyotsava_photos/cutout.swift IN.jpg OUT.png
//
// Prints the share of the picture the subject covers, or exits with 2 when
// Vision finds no subject.
import AppKit
import CoreImage
import Vision

let args = CommandLine.arguments
guard args.count == 3 else {
  FileHandle.standardError.write("usage: cutout.swift IN OUT.png\n".data(using: .utf8)!)
  exit(1)
}
let input = URL(fileURLWithPath: args[1])
let output = URL(fileURLWithPath: args[2])

guard let image = CIImage(contentsOf: input) else {
  FileHandle.standardError.write("cannot read \(input.path)\n".data(using: .utf8)!)
  exit(1)
}
let request = VNGenerateForegroundInstanceMaskRequest()
let handler = VNImageRequestHandler(ciImage: image)
try handler.perform([request])
guard let result = request.results?.first, !result.allInstances.isEmpty else {
  print("no subject")
  exit(2)
}
let buffer = try result.generateMaskedImage(
  ofInstances: result.allInstances, from: handler, croppedToInstancesExtent: false)
let masked = CIImage(cvPixelBuffer: buffer)

let mask = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
let maskImage = CIImage(cvPixelBuffer: mask)
var coverage: Float = 0
let context = CIContext()
if let avg = CIFilter(name: "CIAreaAverage", parameters: [
  kCIInputImageKey: maskImage, kCIInputExtentKey: CIVector(cgRect: maskImage.extent),
])?.outputImage {
  var pixel = [Float](repeating: 0, count: 4)
  context.render(avg, toBitmap: &pixel, rowBytes: 16,
                 bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBAf, colorSpace: nil)
  coverage = pixel[0]
}

try context.writePNGRepresentation(
  of: masked, to: output, format: .RGBA8,
  colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
print(String(format: "subject covers %.0f%% of the photo", coverage * 100))
