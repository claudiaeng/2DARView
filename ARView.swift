//
//  ARView.swift
//  HUGO
//
//  Created by Claudia Eng on 11/11/19.
//  Copyright © 2019 Claudia Eng. All rights reserved.
//

import Foundation
import SwiftUI
import SceneKit
import ARKit
import UIKit

//missing
//   sceneView.session.pause() on dissapear

struct ARView: View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {

    let sceneView = ARSCNView(frame: .zero)

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> ARSCNView {

        //good

        sceneView.showsStatistics = true
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints

        let scene = SCNScene()
        sceneView.scene = scene

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical

        let gestureRecognizer = UITapGestureRecognizer(target: context.coordinator,
        action: #selector(Coordinator.tapped))
        
        sceneView.addGestureRecognizer(gestureRecognizer)

        sceneView.session.run(configuration)

        sceneView.delegate = context.coordinator

        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        print()
    }


    class Coordinator: NSObject, ARSCNViewDelegate {

        var arViewContainer: ARViewContainer

        var grids = [Grid]()


        init(_ arViewContainer: ARViewContainer) {
            self.arViewContainer = arViewContainer
        }

        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {

        }

        @objc func tapped(gesture: UITapGestureRecognizer) {
            // Get 2D position of touch event on screen
            let touchPosition = gesture.location(in: arViewContainer.sceneView)

            // Translate those 2D points to 3D points using hitTest (existing plane)
            let hitTestResults = arViewContainer.sceneView.hitTest(touchPosition, types: .existingPlaneUsingExtent)

            // Get hitTest results and ensure that the hitTest corresponds to a grid that has been placed on a wall
            guard let hitTest = hitTestResults.first, let anchor = hitTest.anchor as? ARPlaneAnchor, let gridIndex = grids.firstIndex(where: { $0.anchor == anchor }) else {
                return
            }
            addPainting(hitTest, grids[gridIndex])
        }

        func addPainting(_ hitResult: ARHitTestResult, _ grid: Grid) {
            // 1.
            let planeGeometry = SCNPlane(width: 0.2, height: 0.35)
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: "mona-lisa")
            planeGeometry.materials = [material]

            // 2.
            let paintingNode = SCNNode(geometry: planeGeometry)
            paintingNode.transform = SCNMatrix4(hitResult.anchor!.transform)
            paintingNode.eulerAngles = SCNVector3(paintingNode.eulerAngles.x + (-Float.pi / 2), paintingNode.eulerAngles.y, paintingNode.eulerAngles.z)
            paintingNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)

            arViewContainer.sceneView.scene.rootNode.addChildNode(paintingNode)
            grid.removeFromParentNode()
        }

        //good

        func sessionWasInterrupted(_ session: ARSession) {
            // Inform the user that the session has been interrupted, for example, by presenting an overlay

        }

        func sessionInterruptionEnded(_ session: ARSession) {
            // Reset tracking and/or remove existing anchors if consistent tracking is required

        }

        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else { return }
            let grid = Grid(anchor: planeAnchor)
            self.grids.append(grid)
            node.addChildNode(grid)
        }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else { return }
            let grid = self.grids.filter { grid in
                return grid.anchor.identifier == planeAnchor.identifier
            }.first

            guard let foundGrid = grid else {
                return
            }

            foundGrid.update(anchor: planeAnchor)
        }

        //good
    }

}

struct ARView_Previews: PreviewProvider {
    static var previews: some View {
        ARView()
    }
}



class Grid : SCNNode {

    var anchor: ARPlaneAnchor
    var planeGeometry: SCNPlane!

    init(anchor: ARPlaneAnchor) {
        self.anchor = anchor
        super.init()
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(anchor: ARPlaneAnchor) {
        planeGeometry.width = CGFloat(anchor.extent.x);
        planeGeometry.height = CGFloat(anchor.extent.z);
        position = SCNVector3Make(anchor.center.x, 0, anchor.center.z);

        let planeNode = self.childNodes.first!
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: self.planeGeometry, options: nil))
    }

    private func setup() {
        planeGeometry = SCNPlane(width: CGFloat(self.anchor.extent.x), height: CGFloat(self.anchor.extent.z))

        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named:"overlay_grid.png")

        planeGeometry.materials = [material]
        let planeNode = SCNNode(geometry: self.planeGeometry)
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: self.planeGeometry, options: nil))
        planeNode.physicsBody?.categoryBitMask = 2

        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z);
        planeNode.transform = SCNMatrix4MakeRotation(Float(-Double.pi / 2.0), 1.0, 0.0, 0.0);

        addChildNode(planeNode)
    }
}
