//
//  GameViewController.swift
//  GeometryFighter
//
//  Created by Sergey Blednov on 6/8/17.
//  Copyright © 2017 Pixacore. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController  {
    
    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var spawnTime: TimeInterval = 0
    var game = GameHelper.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        setupHUD()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupView () {
        scnView = self.view as! SCNView
        scnView.showsStatistics = true
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.delegate = self
        scnView.isPlaying = true
    }
    
    func setupScene () {
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnScene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.png"
    }
    
    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 5, 10)
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    func spawnShape() {
        var geometry: SCNGeometry
        switch ShapeType.random() {
        case ShapeType.sphere:
            geometry = SCNSphere(radius: 1.0)
        case ShapeType.capcule:
            geometry = SCNCapsule(capRadius: 1.0, height: 1.0)
        case ShapeType.cone:
            geometry = SCNCone(topRadius: 0, bottomRadius: 1.0, height: 1.0)
        case ShapeType.cylinder:
            geometry = SCNCylinder(radius: 1.0, height: 1.0)
        case ShapeType.pyramid:
            geometry = SCNPyramid(width: 1.0, height: 1.0, length: 1.0)
        case ShapeType.torus:
            geometry = SCNTorus(ringRadius: 1, pipeRadius: 0.5)
        case ShapeType.tube:
            geometry = SCNTube(innerRadius: 0.5, outerRadius: 1.0, height: 1.0)
        default:
            geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0)
        }
        
        let color = UIColor.random()
        geometry.materials.first?.diffuse.contents = color
        let geomentryNode = SCNNode.init(geometry:geometry)
        geomentryNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        let trailEmitter = createTrail(color: color, geometry: geometry)
        geomentryNode.name = color == UIColor.black ? "BAD" : "GOOD"
    
        geomentryNode.addParticleSystem(trailEmitter)
        
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        let force = SCNVector3Make(randomX, randomY, 0)
        let position = SCNVector3Make(0.05, 0.05, 0.05)
        geomentryNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
//        geomentryNode.physicsBody?.applyTorque(SCNVector4Make(5, 0, 0, 30), asImpulse: true)
        
        scnScene.rootNode.addChildNode(geomentryNode)
        
    }
    
    func cleanScene () {
        for node in scnScene.rootNode.childNodes {
            if node.presentation.position.y < -2 {
                node.removeFromParentNode()
            }
        }
    }
    
    func createTrail (color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem {
        let trail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
        trail.particleColor = color
        trail.emitterShape = geometry
        return trail
    }
    
    
    func createExplosion (geometry: SCNGeometry, position: SCNVector3, rotation: SCNVector4) {
        let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)!
        explosion.emitterShape = geometry
        explosion.birthLocation = .surface
        let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
        let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        scnScene.addParticleSystem(explosion, transform: transformMatrix)
    }
    
    func setupHUD () {
        game.hudNode.position = SCNVector3Make(0, 10.0, 0)
        scnScene.rootNode.addChildNode(game.hudNode)
    }
    
    func handleTouchFor (node: SCNNode) {
        if node.name == "GOOD" {
            game.score += 1
            node.removeFromParentNode()
            createExplosion(geometry: node.geometry!, position: node.presentation.position, rotation: node.presentation.rotation)
        } else if node.name == "BAD" {
            game.lives -= 1
            node.removeFromParentNode()
            createExplosion(geometry: node.geometry!, position: node.presentation.position, rotation: node.presentation.rotation)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: scnView)
        let hitResult = scnView.hitTest(location, options: nil)
        if let result = hitResult.first {
            handleTouchFor(node: result.node)
        }
        
    }
}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if time > spawnTime {
            spawnShape()
            spawnTime = time + TimeInterval(Float.random(min: 0.2, max: 1.5))
        }
        cleanScene()
        game.updateHUD()
    }
}
