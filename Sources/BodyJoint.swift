//
//  BodyJoint.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

public func ==(lhs: BodyJoint, rhs: BodyJoint) -> Bool {
    return lhs === rhs
}

/// Base class for joints which unites two separate bodies
open class BodyJoint: Equatable {
    
    /// Gets the first link that contins informationa bout the first body linked
    /// by this joint
    public final let bodyLink1: JointLinkType
    /// Gets the second link that contins informationa bout the first body
    /// linked by this joint
    public final let bodyLink2: JointLinkType
    
    /// Whether to allow collisions between the two objects joined by this
    /// BodyJoint.
    /// Defaults to false.
    open var allowCollisions = false
    
    /// Controls whether this valubody joint is enabled.
    /// Disabling body joints disables all of the physics of the joint.
    /// Note that collisions between bodies are still governed by
    /// `.allowCollisions` even if the joint is disabled.
    open var enabled = true
    
    /// Gets or sets the rest distance for this joint
    /// In case the rest distance represents a ranged distance 
    /// (`RestDistance.ranged`), the joint only applies forces if the distance
    /// between the links is `dist > restDistance.min && dist < restDistance.max`.
    open var restDistance: RestDistance
    
    /// Initializes a body joint on a given world, linking the two given links.
    /// Optionally provides the distance.
    /// In case the distance was not provided, it will be automatically
    /// calculated based off of the position of each link.
    public init(on world: World, link1: JointLinkType, link2: JointLinkType, distance: RestDistance? = nil) {
        bodyLink1 = link1
        bodyLink2 = link2
        
        // Automatic distance calculation
        restDistance =
                distance ?? .fixed(link1.position.distance(to: link2.position))
    }
    
    /// Resolves this joint
    ///
    /// - Parameter dt: The delta time to update the resolve on
    open func resolve(_ dt: JFloat) {
        
    }
}

/// Protocol to be implemented by objects that specify the way a joint links
/// with a body
public protocol JointLinkType {
    
    /// Gets the body that this joint link is linked to
    unowned var body: Body { get }
    
    /// Gets the type of joint this joint link represents
    var linkType: LinkType { get }
    
    /// Gets the position, in world coordinates, at which this joint links with
    /// the underlying body
    var position: Vector2 { get }
    
    /// Gets the velocity of the object this joint links to
    var velocity: Vector2 { get }
    
    /// Gets the total mass of the subject of this joint link
    var mass: JFloat { get }
    
    /// Gets a value specifying whether the object referenced by this
    /// JointLinkType is static
    var isStatic: Bool { get }
    
    /// Appies a given force to the subject of this joint link
    ///
    /// - parameter force: A force to apply to the subjects of this joint link
    func applyForce(of force: Vector2)
}

/// The type of joint link of a BodyJointLink class
public enum LinkType {
    /// Specifies that the joint links at the whole body, relative to the center
    case body
    /// Specifies that the joint links at a body's point
    case point
    /// Specifies that the joint links at a body's edge (set of two points)
    case edge
    /// Specifies that the joint links at an arbitrary set of points of a body
    case shape
}
