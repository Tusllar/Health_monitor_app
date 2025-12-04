import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class Wrist3DWidget extends StatefulWidget {
  final Map<String, double>? accelData;

  const Wrist3DWidget({Key? key, this.accelData}) : super(key: key);

  @override
  State<Wrist3DWidget> createState() => _Wrist3DWidgetState();
}

class _Wrist3DWidgetState extends State<Wrist3DWidget> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://your-domain.com/wrist_3d_viewer.html'));
    
    // For local development, you can load from assets:
    // ..loadFlutterAsset('assets/wrist_3d_viewer.html');
  }

  @override
  void didUpdateWidget(Wrist3DWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accelData != null && !_isLoading) {
      _updateRotation();
    }
  }

  void _updateRotation() {
    if (widget.accelData == null) return;
    
    final x = widget.accelData!['x'] ?? 0.0;
    final y = widget.accelData!['y'] ?? 0.0;
    final z = widget.accelData!['z'] ?? 0.0;

    final jsCode = 'window.updateWristRotation($x, $y, $z);';
    _controller.runJavaScript(jsCode);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
      ],
    );
  }
}

// Alternative: Inline HTML version (no need to host HTML file)
class Wrist3DWidgetInline extends StatefulWidget {
  final Map<String, double>? accelData;

  const Wrist3DWidgetInline({Key? key, this.accelData}) : super(key: key);

  @override
  State<Wrist3DWidgetInline> createState() => _Wrist3DWidgetInlineState();
}

class _Wrist3DWidgetInlineState extends State<Wrist3DWidgetInline> {
  late WebViewController _controller;
  bool _isLoading = true;

  // HTML content embedded directly
  static const String htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { margin: 0; overflow: hidden; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
        #container { width: 100vw; height: 100vh; }
        #info { position: absolute; top: 10px; left: 10px; color: white; background: rgba(0,0,0,0.5); 
                padding: 10px; border-radius: 8px; font-family: sans-serif; font-size: 12px; }
    </style>
</head>
<body>
    <div id="container"></div>
    <div id="info">
        <div>🤚 Wrist Movement</div>
        <div>X: <span id="x">0.0</span></div>
        <div>Y: <span id="y">0.0</span></div>
        <div>Z: <span id="z">0.0</span></div>
    </div>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
    <script>
        let scene, camera, renderer, wristGroup;
        let targetRotation = { x: 0, y: 0, z: 0 };
        let currentRotation = { x: 0, y: 0, z: 0 };

        function init() {
            scene = new THREE.Scene();
            scene.background = new THREE.Color(0x667eea);
            
            camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 1000);
            camera.position.set(0, 2, 8);
            
            renderer = new THREE.WebGLRenderer({ antialias: true });
            renderer.setSize(window.innerWidth, window.innerHeight);
            renderer.shadowMap.enabled = true;
            document.getElementById('container').appendChild(renderer.domElement);
            
            const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
            scene.add(ambientLight);
            
            const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
            directionalLight.position.set(5, 10, 7);
            directionalLight.castShadow = true;
            scene.add(directionalLight);
            
            wristGroup = new THREE.Group();
            scene.add(wristGroup);
            
            // Forearm
            const forearmGeometry = new THREE.CylinderGeometry(0.6, 0.7, 3, 16);
            const forearmMaterial = new THREE.MeshPhongMaterial({ color: 0xffab91, shininess: 30 });
            const forearm = new THREE.Mesh(forearmGeometry, forearmMaterial);
            forearm.position.y = -1.5;
            forearm.castShadow = true;
            wristGroup.add(forearm);
            
            // Hand
            const hand = new THREE.Group();
            const palmGeometry = new THREE.BoxGeometry(1.5, 0.3, 2);
            const palmMaterial = new THREE.MeshPhongMaterial({ color: 0xffccbc, shininess: 30 });
            const palm = new THREE.Mesh(palmGeometry, palmMaterial);
            palm.castShadow = true;
            hand.add(palm);
            
            // Fingers
            const fingerPositions = [
                { x: -0.6, len: 1.2 },
                { x: -0.3, len: 1.8 },
                { x: 0, len: 2.0 },
                { x: 0.3, len: 1.8 },
                { x: 0.6, len: 1.4 }
            ];
            
            fingerPositions.forEach(finger => {
                const fingerGroup = new THREE.Group();
                for (let j = 0; j < 3; j++) {
                    const segLen = finger.len / 3;
                    const segGeom = new THREE.CylinderGeometry(0.12, 0.1, segLen, 8);
                    const segment = new THREE.Mesh(segGeom, palmMaterial);
                    segment.position.y = segLen / 2 + j * segLen;
                    segment.castShadow = true;
                    fingerGroup.add(segment);
                }
                fingerGroup.position.set(finger.x, 0.15, 0.8);
                fingerGroup.rotation.x = -0.2;
                hand.add(fingerGroup);
            });
            
            hand.position.y = 0.3;
            wristGroup.add(hand);
            
            animate();
        }
        
        function animate() {
            requestAnimationFrame(animate);
            const smoothing = 0.1;
            currentRotation.x += (targetRotation.x - currentRotation.x) * smoothing;
            currentRotation.y += (targetRotation.y - currentRotation.y) * smoothing;
            currentRotation.z += (targetRotation.z - currentRotation.z) * smoothing;
            
            wristGroup.rotation.x = currentRotation.x;
            wristGroup.rotation.y = currentRotation.y;
            wristGroup.rotation.z = currentRotation.z;
            
            renderer.render(scene, camera);
        }
        
        window.updateWristRotation = function(x, y, z) {
            targetRotation.x = x * 0.5;
            targetRotation.z = -y * 0.5;
            targetRotation.y = z * 0.3;
            
            document.getElementById('x').textContent = x.toFixed(2);
            document.getElementById('y').textContent = y.toFixed(2);
            document.getElementById('z').textContent = z.toFixed(2);
        };
        
        init();
    </script>
</body>
</html>
  ''';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  @override
  void didUpdateWidget(Wrist3DWidgetInline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accelData != null && !_isLoading) {
      _updateRotation();
    }
  }

  void _updateRotation() {
    if (widget.accelData == null) return;
    
    final x = widget.accelData!['x'] ?? 0.0;
    final y = widget.accelData!['y'] ?? 0.0;
    final z = widget.accelData!['z'] ?? 0.0;

    final jsCode = 'window.updateWristRotation($x, $y, $z);';
    _controller.runJavaScript(jsCode);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
      ],
    );
  }
}