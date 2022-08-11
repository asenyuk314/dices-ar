//
//  ViewController.swift
//  DicesAR
//
//  Created by Александр Сенюк on 11.08.2022.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
  var diceArray: [SCNNode] = []
  @IBOutlet var sceneView: ARSCNView!

  override func viewDidLoad() {
    super.viewDidLoad()
    sceneView.delegate = self
    sceneView.autoenablesDefaultLighting = true
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = .horizontal
    sceneView.session.run(configuration)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sceneView.session.pause()
  }

  // MARK: - Dice Rendering Methods

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touch = touches.first {
      let touchLocation = touch.location(in: sceneView)
      if let query = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneGeometry, alignment: .any) {
        let results = sceneView.session.raycast(query)
        if let hitResult = results.first {
          addDice(atLocation: hitResult)
        }
      }
    }
  }

  func addDice(atLocation location: ARRaycastResult) {
    let diceScene = SCNScene(named: "art.scnassets/dice.scn")!
    if let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true) {
      diceNode.position = SCNVector3(
        x: location.worldTransform.columns.3.x,
        y: location.worldTransform.columns.3.y + diceNode.boundingSphere.radius,
        z: location.worldTransform.columns.3.z
      )
      diceArray.append(diceNode)
      sceneView.scene.rootNode.addChildNode(diceNode)
      roll(dice: diceNode)
    }
  }

  func roll(dice: SCNNode) {
    let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi / 2)
    let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi / 2)
    dice.runAction(SCNAction.rotateBy(
      x: CGFloat(randomX * 5),
      y: 0,
      z: CGFloat(randomZ * 5),
      duration: 0.5
    ))
  }

  func rollAll() {
    for dice in diceArray {
      roll(dice: dice)
    }
  }

  @IBAction func rollAgain(_ sender: UIBarButtonItem) {
    rollAll()
  }

  override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    rollAll()
  }

  @IBAction func removeAllDices(_ sender: Any) {
    for dice in diceArray {
      dice.removeFromParentNode()
    }
    diceArray.removeAll()
  }

  // MARK: - ARSCNViewDelegateMethods

  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    guard let planeAnchor = anchor as? ARPlaneAnchor else {
      return
    }
    let planeNode = createPlane(withPlaneAnchor: planeAnchor)
    node.addChildNode(planeNode)
  }

  // MARK: - Plane Rendering Methods

  func createPlane(withPlaneAnchor planeAnchor: ARPlaneAnchor) -> SCNNode {
    let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
    let planeNode = SCNNode()
    planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
    planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
    let gridMaterial = SCNMaterial()
    gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
    plane.materials = [gridMaterial]
    planeNode.geometry = plane
    return planeNode
  }
}
