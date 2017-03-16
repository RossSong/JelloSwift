//
//  SpringComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 16/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

/// Represents a Spring component that can be added to a body to include 
/// spring-based physics in the body's point masses
public final class SpringComponent: BodyComponent {
    
    /// Gets the count of springs on this spring component
    public var springCount: Int {
        return springs.count
    }
    
    /// The list of internal springs for the body
    fileprivate var springs: [InternalSpring] = []
    
    /// Whether the shape matching is on - turning on shape matching will make 
    /// the soft body try to mantain its original shape as specified by its
    /// `baseShape` property
    fileprivate var shapeMatchingOn = true
    
    /// The spring constant for the edges of the spring body
    fileprivate var edgeSpringK: JFloat = 50
    /// The spring damping for the edges of the spring body
    fileprivate var edgeSpringDamp: JFloat = 2
    
    /// The spring constant for the shape matching of the body - ignored if
    /// shape matching is off
    fileprivate var shapeSpringK: JFloat = 200
    /// The spring damping for the shape matching of the body - ignored if the
    /// shape matching is off
    fileprivate var shapeSpringDamp: JFloat = 10
    
    override public func prepare(_ body: Body) {
        clearAllSprings(body)
    }
    
    /// Adds an internal spring to this body
    @discardableResult
    public func addInternalSpring(_ body: Body, pointA: Int, pointB: Int,
                                  springK: JFloat, damping: JFloat,
                                  dist: JFloat? = nil) -> InternalSpring {
        let pointA = body.pointMasses[pointA]
        let pointB = body.pointMasses[pointB]
        
        let dist = dist ?? pointA.position.distance(to: pointB.position)
        
        let spring = InternalSpring(pointA, pointB, dist, springK, damping)
        
        springs.append(spring)
        
        return spring
    }
    
    /// Clears all the internal springs from the body.
    /// The original edge springs are mantained
    public func clearAllSprings(_ body: Body) {
        springs = []
        
        buildDefaultSprings(body)
    }
    
    /// Builds the default edge internal springs for this spring body
    public func buildDefaultSprings(_ body: Body) {
        for i in 0..<body.pointMasses.count {
            let pointB = (i + 1) % body.pointMasses.count
            addInternalSpring(body, pointA: i, pointB: pointB,
                              springK: edgeSpringK, damping: edgeSpringDamp)
        }
    }
    
    /// Sets the shape-matching spring constants
    public func setShapeMatchingConstants(_ springK: JFloat, _ damping: JFloat) {
        shapeSpringK = springK
        shapeSpringDamp = damping
    }
    
    /// Changes the spring constants for the springs around the shape itself 
    /// (edge springs)
    public func setEdgeSpringConstants(_ body: Body, edgeSpringK: JFloat,
                                       _ edgeSpringDamp: JFloat) {
        // we know that the first n springs in the list are the edge springs.
        for i in 0..<body.pointMasses.count {
            springs[i].coefficient = edgeSpringK
            springs[i].damping = edgeSpringDamp
        }
    }
    
    /// Sets the spring constant for the given spring index.
    /// The spring index starts from pointMasses.count and onwards, so the first
    /// spring will not be the first edge spring.
    public func setSpringConstants(_ body: Body, springID: Int,
                                   _ springK: JFloat, _ springDamp: JFloat) {
        // index is for all internal springs, AFTER the default internal springs.
        let index = body.pointMasses.count + springID
        
        springs[index].coefficient = springK
        springs[index].damping = springDamp
    }
    
    /// Gets the spring constant of a spring at the specified index.
    /// This ignores the default edge springs, so the index is always 
    /// `+ body.pointMasses.count`
    public func springCoefficient(forSpringIndex springID: Int, in body: Body) -> JFloat {
        return springs[body.pointMasses.count + springID].coefficient
    }
    
    /// Gets the spring damping of a spring at the specified index
    /// This ignores the default edge springs, so the index is always 
    /// `+ body.pointMasses.count`
    public func springDamping(forSpringIndex springID: Int, in body: Body) -> JFloat {
        return springs[body.pointMasses.count + springID].damping
    }
    
    override public func accumulateInternalForces(in body: Body) {
        super.accumulateInternalForces(in: body)
        
        for s in springs {
            let p1 = s.pointMassA
            let p2 = s.pointMassB
            
            let force = calculateSpringForce(posA: p1.position,
                                             velA: p1.velocity,
                                             posB: p2.position,
                                             velB: p2.velocity,
                                             distance: s.distance,
                                             springK: s.coefficient,
                                             springD: s.damping)
            
            p1.applyForce(of: force)
            p2.applyForce(of: -force)
        }
        
        if(shapeMatchingOn && shapeSpringK > 0) {
            applyShapeMatching(on: body)
        }
    }
    
    /// Applies shape-matching on the given body.
    /// Shape-matching applies spring forces to each point masses on the
    /// direction of the body's original global shape
    fileprivate func applyShapeMatching(on body: Body) {
        
        let matrix = Vector2.matrix(scalingBy: body.scale,
                                    rotatingBy: body.derivedAngle,
                                    translatingBy: body.derivedPos)
        
        body.baseShape.transformVertices(&body.globalShape, matrix: matrix)
        
        for (global, p) in zip(body.globalShape, body.pointMasses) {
            let force: Vector2
            
            let velB = body.isKinematic ? Vector2.zero : p.velocity
            
            force = calculateSpringForce(posA: p.position, velA: p.velocity,
                                         posB: global, velB: velB,
                                         distance: 0.0,
                                         springK: shapeSpringK,
                                         springD: shapeSpringDamp)
            
            p.applyForce(of: force)
        }
    }
}

/// Creator for the Spring component
open class SpringComponentCreator : BodyComponentCreator {
    /// Whether the shape matching is on - turning on shape matching will make
    /// the soft body try to mantain its original shape as specified by its
    /// baseShape
    open var shapeMatchingOn = true
    
    /// The spring constant for the edges of the spring body
    open var edgeSpringK: JFloat = 50
    /// The spring damping for the edges of the spring body
    open var edgeSpringDamp: JFloat = 2
    
    /// The spring constant for the shape matching of the body - ignored if
    /// shape matching is off
    open var shapeSpringK: JFloat = 200
    /// The spring damping for the shape matching of the body - ignored if the 
    /// shape matching is off
    open var shapeSpringDamp: JFloat = 10
    
    /// An array of inner springs for a body
    open var innerSprings: [SpringComponentInnerSpring] = []
    
    public required init(shapeMatchingOn: Bool = true,
                         edgeSpringK: JFloat = 50,
                         edgeSpringDamp: JFloat = 2,
                         shapeSpringK: JFloat = 200,
                         shapeSpringDamp: JFloat = 10,
                         innerSprings: [SpringComponentInnerSpring] = []) {
        self.shapeMatchingOn = shapeMatchingOn
        
        self.edgeSpringK = edgeSpringK
        self.edgeSpringDamp = edgeSpringDamp
        
        self.shapeSpringK = shapeSpringK
        self.shapeSpringDamp = shapeSpringDamp
        
        self.innerSprings = innerSprings
        
        super.init()
        
        bodyComponentClass = SpringComponent.self
    }
    
    open override func prepareBodyAfterComponent(_ body: Body) {
        guard let comp = body.component(ofType: SpringComponent.self) else {
            return
        }
        
        comp.shapeMatchingOn = shapeMatchingOn
        
        comp.setEdgeSpringConstants(body, edgeSpringK: edgeSpringK, edgeSpringDamp)
        comp.setShapeMatchingConstants(shapeSpringK, shapeSpringDamp)
        
        for element in innerSprings {
            comp.addInternalSpring(body, pointA: element.indexA,
                                   pointB: element.indexB,
                                   springK: element.coefficient,
                                   damping: element.damping, dist: element.dist)
        }
    }
}

/// Specifies a template for an inner spring
public struct SpringComponentInnerSpring {
    
    /// Index of the first point mass of the spring, in the `pointMasses` 
    /// property of the target body
    public var indexA = 0
    /// Index of the second point mass of the spring, in the `pointMasses` 
    /// property of the target body
    public var indexB = 0
    
    /// The spring coefficient for this spring
    public var coefficient: JFloat = 0
    /// Damping coefficient for this spring
    public var damping: JFloat = 0
    
    /// The rest distance for this spring, as in, the distance this spring will
    /// try to mantain between the two point masses.
    public var dist: JFloat = 0
    
    public init(a: Int, b: Int, coefficient: JFloat, damping: JFloat,
                dist: JFloat = -1) {
        indexA = a
        indexB = b
        
        self.coefficient = coefficient
        self.damping = damping
        
        self.dist = dist
    }
}
