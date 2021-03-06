//
//  EdgeBodyJointLink.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

/// Represents a joint link that links to an edge of a body
open class EdgeJointLink: JointLinkType {
    /// The first point mass this joint is linked to
    fileprivate let _pointMass1: PointMass
    /// The second point mass this joint is linked to
    fileprivate let _pointMass2: PointMass
    
    /// The ratio of the edge this edge joint is linked to.
    /// Values must range between [0 - 1] inclusive, and dictate the middle
    /// point of the edge.
    /// Specifying either 0 or 1 makes this edge joint link behave essentially
    /// like a PointJointLink
    open var edgeRatio: JFloat
    
    /// Gets the body that this joint link is linked to
    open fileprivate(set) unowned var body: Body
    
    /// Gets the type of joint this joint link represents
    open let linkType = LinkType.edge
    
    /// Gets the position, in world coordinates, at which this joint links with 
    /// the underlying body
    open var position: Vector2 {
        return calculateVectorRatio(_pointMass1.position,
                                    vec2: _pointMass2.position,
                                    ratio: edgeRatio)
    }
    
    /// Gets the velocity of the object this joint links to
    open var velocity: Vector2 {
        return calculateVectorRatio(_pointMass1.velocity,
                                    vec2: _pointMass2.velocity,
                                    ratio: edgeRatio)
    }
    
    /// Gets the total mass of the subject of this joint link
    open var mass: JFloat {
        return _pointMass1.mass * (1 - edgeRatio) + _pointMass2.mass * (edgeRatio)
    }
    
    /// Gets a value specifying whether the object referenced by this 
    /// JointLinkType is static
    open var isStatic: Bool {
        return _pointMass1.mass.isInfinite && _pointMass2.mass.isInfinite
    }
    
    /// Inits a new edge joint link with the specified parameters
    public init(body: Body, edgeIndex: Int, edgeRatio: JFloat = 0.5) {
        self.body = body
        _pointMass1 = body.pointMasses[edgeIndex % body.pointMasses.count]
        _pointMass2 = body.pointMasses[(edgeIndex + 1) % body.pointMasses.count]
        
        self.edgeRatio = edgeRatio
    }
    
    /// Appies a given force to the subject of this joint link
    ///
    /// - parameter force: A force to apply to the subjects of this joint link
    open func applyForce(of force: Vector2) {
        _pointMass1.applyForce(of: force * (1 - edgeRatio))
        _pointMass2.applyForce(of: force * (edgeRatio))
        
        // Torque - this depends on how far down the middle of the edge the
        // force is being applied at.
        // Torque is applied at most as half the actual torque when along the
        // middle of the edge, and 0 torque at the very corners.
        if edgeRatio > 0 && edgeRatio < 1 {
            var torqueF = (body.derivedPos - position) • force.perpendicular()
            torqueF = 1 - abs(1 - edgeRatio * 2)
            body.applyTorque(of: torqueF)
        }
    }
}
