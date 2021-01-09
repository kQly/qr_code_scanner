//
//  QRView.swift
//  flutter_qr
//
//  Created by Julius Canute on 21/12/18.
//

import Foundation
import MTBBarcodeScanner

public class QRView:NSObject,FlutterPlatformView {
    @IBOutlet var previewView: UIView!
    var scanner: MTBBarcodeScanner?
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    
    public init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withId id: Int64){
        self.registrar = registrar
        previewView = UIView(frame: frame)
        channel = FlutterMethodChannel(name: "net.touchcapture.qr.flutterqr/qrview_\(id)", binaryMessenger: registrar.messenger())
    }
    
    func isCameraAvailable(success: Bool) -> Void {
        if success {
            do {
                try scanner?.startScanning(resultBlock: { [weak self] codes in
                    if let codes = codes {
                        for code in codes {
                            var typeString: String;
                            switch(code.type) {
                                case AVMetadataObject.ObjectType.aztec:
                                   typeString = "AZTEC"
                                case AVMetadataObject.ObjectType.code39:
                                    typeString = "CODE_39"
                                case AVMetadataObject.ObjectType.code93:
                                    typeString = "CODE_93"
                                case AVMetadataObject.ObjectType.code128:
                                    typeString = "CODE_128"
                                case AVMetadataObject.ObjectType.dataMatrix:
                                    typeString = "DATA_MATRIX"
                                case AVMetadataObject.ObjectType.ean8:
                                    typeString = "EAN_8"
                                case AVMetadataObject.ObjectType.ean13:
                                    typeString = "EAN_13"
                                case AVMetadataObject.ObjectType.itf14:
                                    typeString = "ITF"
                                case AVMetadataObject.ObjectType.pdf417:
                                    typeString = "PDF_417"
                                case AVMetadataObject.ObjectType.qr:
                                    typeString = "QR_CODE"
                                case AVMetadataObject.ObjectType.upce:
                                    typeString = "UPC_E"
                                default:
                                    return
                            }
                            guard let stringValue = code.stringValue else { continue }
                            let result = ["code": stringValue, "type": typeString]
                            self?.channel.invokeMethod("onRecognizeQR", arguments: result)
                        }
                    }
                })
            } catch {
                NSLog("Unable to start scanning")
            }
        } else {
            UIAlertView(title: "Scanning Unavailable", message: "This app does not have permission to access the camera", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "Ok").show()
        }
    }
    
    public func view() -> UIView {
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
            switch(call.method){
                case "setDimensions":
                    let arguments = call.arguments as! Dictionary<String, Double>
                    self?.setDimensions(width: arguments["width"] ?? 0, height: arguments["height"] ?? 0, scanArea: arguments["scanArea"] ?? 0, offset: arguments["offset"] ?? 0)
                case "flipCamera":
                    self?.flipCamera()
                case "toggleFlash":
                    self?.toggleFlash()
                case "pauseCamera":
                    self?.pauseCamera()
                case "resumeCamera":
                    self?.resumeCamera()
                default:
                    result(FlutterMethodNotImplemented)
                    return
            }
        })
        return previewView
    }
    
    func setDimensions(width: Double, height: Double, scanArea: Double, offset: Double) -> Void {
        previewView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        let midX = self.view().bounds.midX
        let midY = self.view().bounds.midY
        if let sc: MTBBarcodeScanner = scanner {
            if let previewLayer = sc.previewLayer {
                previewLayer.frame = previewView.bounds;
            }
        } else {
            scanner = MTBBarcodeScanner(previewView: previewView)
            
            if (scanArea != 0) {
                scanner?.didStartScanningBlock = {
                    self.scanner?.scanRect = CGRect(x: Double(midX) - (scanArea / 2), y: Double(midY) - (scanArea / 2) - offset, width: scanArea, height: scanArea)
                }
            }


            MTBBarcodeScanner.requestCameraPermission(success: isCameraAvailable)
        }
    }
    
    func flipCamera(){
        if let sc: MTBBarcodeScanner = scanner {
            if sc.hasOppositeCamera() {
                sc.flipCamera()
            }
        }
    }
    
    func toggleFlash(){
        if let sc: MTBBarcodeScanner = scanner {
            if sc.hasTorch() {
                sc.toggleTorch()
            }
        }
    }
    
    func pauseCamera() {
        if let sc: MTBBarcodeScanner = scanner {
            if sc.isScanning() {
                sc.freezeCapture()
            }
        }
    }
    
    func resumeCamera() {
        if let sc: MTBBarcodeScanner = scanner {
            if !sc.isScanning() {
                sc.unfreezeCapture()
            }
        }
    }
}
