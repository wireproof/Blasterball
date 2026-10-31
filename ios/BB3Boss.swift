import SpriteKit

/// Source-configured mobile boss encounters. HP, scores, shield duration and motion rates
/// come from shipped boss templates. Flat composition/collision and attack scheduling are
/// adaptations; the original skeletal and per-boss native state machines are not reproduced.
final class BB3BossEncounter {
    struct Impact { let collided:Bool, defeated:Bool; let points:Int }
    let root=SKNode(), body=SKSpriteNode(), shield=SKSpriteNode(), fuse=SKSpriteNode()
    let kind:Int, recycled:Bool, maximumHealth:Int
    private(set) var health:Int
    var defeated:Bool { health<=0 }
    private var elapsed:CGFloat=0, shotClock:CGFloat=0, shieldRemaining:CGFloat=0, hitCooldown:CGFloat=0
    private var origin=CGPoint.zero, unit:CGFloat=1
    private var projectiles:[SKSpriteNode]=[], generators:[SKSpriteNode]=[]
    private let config:[String:String]
    private var arena=CGRect.zero
    static let indexKinds=[1:3,2:4,3:1,4:2,5:5,6:3,7:4,8:1,9:2,10:5]
    static let configs:[String:[String:String]] = {
        guard let url=Bundle.main.url(forResource:"boss-config",withExtension:"json",subdirectory:"BB3"),let data=try? Data(contentsOf:url),let result=try? JSONDecoder().decode([String:[String:String]].self,from:data) else {return [:]}
        return result
    }()
    init?(settings:[String:String],geometry:BoardGeometry,savedHealth:Int?=nil) {
        guard let index=Int(settings["BossIndex"] ?? ""),let kind=Self.indexKinds[index] else {return nil}
        self.kind=kind;recycled=index>5
        config=Self.configs["\(kind):\(index>5 ? "Recycled":"Default")"] ?? [:]
        if let hp=Int(config["HitPoints"] ?? "") {maximumHealth=hp}
        else {maximumHealth=(Int(config[kind==1 ? "HitStatesPoints":"HitStates"] ?? "1") ?? 1)*(Int(config[kind==1 ? "HitPerState":"HitsPerState"] ?? "1") ?? 1)}
        health=max(0,min(maximumHealth,savedHealth ?? maximumHealth));root.name="bb3Boss";root.zPosition=9
        let art=kind==1 ? "boss1_body":"boss_boss\(kind)_body\(kind==2 ? "_01":"")\((kind==2 || kind==3 || kind==5) && recycled ? "_recycle":"")"
        body.texture=OriginalArt.third(art);root.addChild(body)
        shield.texture=OriginalArt.third("boss_boss5_ring");shield.zPosition=1
        fuse.texture=OriginalArt.third("boss_boss5_fuse");fuse.zPosition=2
        if kind==5 {root.addChild(shield);root.addChild(fuse)}
        if kind==4 {
            for _ in 0..<(recycled ? 4:2) {let n=SKSpriteNode(texture:OriginalArt.third("boss_boss4_pipe"));root.addChild(n);generators.append(n)}
        }
        if kind==1 {
            for side:CGFloat in [-1,1] {
                let leg=SKSpriteNode(texture:OriginalArt.third("boss1_leg"));leg.name="leg";leg.position.x=side;leg.zPosition = -1;root.addChild(leg)
            }
        }
        layout(geometry)
    }
    func layout(_ geometry:BoardGeometry) {
        unit=(geometry.right-geometry.left)/60
        arena=CGRect(x:geometry.left,y:geometry.paddleY,width:geometry.right-geometry.left,height:geometry.ceiling-geometry.paddleY)
        origin=CGPoint(x:geometry.center,y:geometry.ceiling-11*unit)
        body.size=CGSize(width:(kind==1 ? 14:12)*unit,height:(kind==4 ? 6:12)*unit)
        body.position=origin
        shield.size=CGSize(width:15*unit,height:15*unit);shield.position=origin
        fuse.size=CGSize(width:10*unit,height:5*unit);fuse.position=CGPoint(x:geometry.center,y:geometry.ceiling-2.5*unit)
        for (i,n) in generators.enumerated() {n.size=CGSize(width:3*unit,height:3*unit);n.position=CGPoint(x:i%2==0 ? geometry.left+2*unit:geometry.right-2*unit,y:geometry.ceiling-(i<2 ? 15:29)*unit)}
        for n in root.children where n.name=="leg" {if let sprite=n as? SKSpriteNode {let side:CGFloat=n.position.x<0 ? -1:1;sprite.size=CGSize(width:4*unit,height:15*unit);sprite.position=CGPoint(x:origin.x+side*8*unit,y:origin.y-5*unit)}}
    }
    private func pair(_ name:String,_ fallback:(CGFloat,CGFloat))->(CGFloat,CGFloat) {
        let values=(config[name] ?? "").replacingOccurrences(of:"(",with:"").replacingOccurrences(of:")",with:"").split(separator:" ").compactMap{Double($0)}
        return values.count>=2 ? (CGFloat(values[0]),CGFloat(values[1])):fallback
    }
    /// Returns true when a mobile boss projectile reaches the paddle.
    func advance(_ dt:CGFloat,geometry:BoardGeometry,paddleX:CGFloat,paddleWidth:CGFloat)->Bool {
        guard !defeated else {return false}
        elapsed += dt;shotClock += dt;shieldRemaining=max(0,shieldRemaining-dt);hitCooldown=max(0,hitCooldown-dt)
        if abs(arena.width-(geometry.right-geometry.left))>0.01 || abs(arena.minY-geometry.paddleY)>0.01 {layout(geometry)}
        if kind==2 || kind==5 {
            let amplitude=pair("MoveAmplitude",(1,1)),speed=pair("MoveAngleSpeed",(30,30))
            body.position=CGPoint(x:origin.x+sin(elapsed*speed.0 * .pi/180)*amplitude.0*unit,y:origin.y+sin(elapsed*speed.1 * .pi/180)*amplitude.1*unit)
        } else if kind==3 {
            let wait=pair("ExtensionAtackWait",(1,3)),cycle=max(4,wait.1+3),phase=elapsed.truncatingRemainder(dividingBy:cycle)
            let extensionFraction=phase<wait.1 ? 0:sin(min(1,(phase-wait.1)/3)*CGFloat.pi)
            body.position=CGPoint(x:origin.x+sin(elapsed*0.6)*arena.width*0.25,y:origin.y-extensionFraction*min(arena.height*0.55,27*unit))
        } else if kind==1 {body.position.x=origin.x+sin(elapsed*0.35)*arena.width*0.18}
        if kind==1 {for (i,n) in root.children.filter({$0.name=="leg"}).enumerated() {n.position=CGPoint(x:body.position.x+(i==0 ? -8:8)*unit,y:body.position.y-5*unit)}}
        shield.position=body.position;shield.zRotation += dt*0.5;shield.isHidden=kind != 5 || shieldRemaining>0
        if shotClock>3 && projectiles.count<(kind==4 ? (recycled ? 12:4):6) {
            shotClock=0
            if kind != 5 && (kind != 1 || recycled) {
                let n=SKSpriteNode(texture:OriginalArt.third(kind==2 ? "boss_boss2_body_01":"boss_boss3_plasma_ball"));n.size=CGSize(width:3*unit,height:3*unit)
                n.position=kind==4 ? (generators.randomElement()?.position ?? body.position):body.position;n.zPosition=3;root.addChild(n);projectiles.append(n)
            }
        }
        var paddleHit=false
        for n in projectiles {
            n.position.y -= (kind==1 ? 35:(kind==2 ? (recycled ? 30:20):(kind==3 ? 33:8)))*unit*dt
            if abs(n.position.y-geometry.paddleY)<2*unit && abs(n.position.x-paddleX)<paddleWidth/2+unit {paddleHit=true;n.removeFromParent()}
            if n.position.y<geometry.paddleY-8*unit {n.removeFromParent()}
        }
        projectiles.removeAll{$0.parent==nil}
        return paddleHit
    }
    private func reflect(_ ball:LiveBall,around center:CGPoint) {
        let dx=ball.node.position.x-center.x,dy=ball.node.position.y-center.y,length=max(0.01,hypot(dx,dy)),nx=dx/length,ny=dy/length
        let dot=ball.velocity.dx*nx+ball.velocity.dy*ny
        if dot<0 {ball.velocity.dx -= 2*dot*nx;ball.velocity.dy -= 2*dot*ny}
    }
    func collide(_ ball:LiveBall,radius:CGFloat)->Impact {
        guard !defeated else {return Impact(collided:false,defeated:false,points:0)}
        for n in projectiles where hypot(n.position.x-ball.node.position.x,n.position.y-ball.node.position.y)<radius+n.size.width/2 {
            reflect(ball,around:n.position);n.removeFromParent();projectiles.removeAll{$0 === n};return Impact(collided:true,defeated:false,points:0)
        }
        if kind==5 && fuse.frame.insetBy(dx:-radius,dy:-radius).contains(ball.node.position) {
            shieldRemaining=CGFloat(Double(config["ShieldOffTime"] ?? "6") ?? 6);reflect(ball,around:fuse.position);return Impact(collided:true,defeated:false,points:0)
        }
        let normalizedX=(ball.node.position.x-body.position.x)/(body.size.width/2+radius),normalizedY=(ball.node.position.y-body.position.y)/(body.size.height/2+radius)
        guard normalizedX*normalizedX+normalizedY*normalizedY<=1 else {return Impact(collided:false,defeated:false,points:0)}
        reflect(ball,around:body.position)
        guard hitCooldown<=0 else {return Impact(collided:true,defeated:false,points:0)}
        hitCooldown=0.12
        if kind==5 && shieldRemaining<=0 {return Impact(collided:true,defeated:false,points:0)}
        health=max(0,health-1);body.run(.sequence([.fadeAlpha(to:0.4,duration:0.04),.fadeAlpha(to:1,duration:0.1)]))
        if defeated {root.run(.sequence([.fadeOut(withDuration:0.3),.removeFromParent()]))}
        return Impact(collided:true,defeated:defeated,points:defeated ? (Int(config["Score"] ?? "10000") ?? 10000):0)
    }
    func resetProjectiles() {projectiles.forEach{$0.removeFromParent()};projectiles=[]}
    static func validation()->[String:Bool] {
        var checks:[String:Bool]=[:]
        let geometry=BoardGeometry.make(viewSize:CGSize(width:640,height:480),safeInsets:.zero,classic:true)
        for index in 1...10 {
            guard let b=BB3BossEncounter(settings:["BossIndex":String(index)],geometry:geometry) else {checks["boss_\(index)_created"]=false;continue}
            checks["boss_\(index)_original_art"]=b.body.texture != nil
            checks["boss_\(index)_health"]=b.maximumHealth>1 && b.health==b.maximumHealth
            let restored=BB3BossEncounter(settings:["BossIndex":String(index)],geometry:geometry,savedHealth:b.maximumHealth-1)
            checks["boss_\(index)_health_restores"]=restored?.health==b.maximumHealth-1
            checks["boss_\(index)_defeat_restores"]=BB3BossEncounter(settings:["BossIndex":String(index)],geometry:geometry,savedHealth:0)?.defeated == true
            checks["boss_\(index)_body_reachable"]=b.body.frame.minX>=geometry.left && b.body.frame.maxX<=geometry.right && b.body.frame.minY>geometry.paddleY && b.body.frame.maxY<=geometry.ceiling
            let ball=LiveBall(node:SKShapeNode(circleOfRadius:4),velocity:CGVector(dx:0,dy:200));ball.node.position=CGPoint(x:b.body.position.x,y:b.body.position.y-b.body.size.height/2)
            if b.kind==5 {
                _=b.collide(ball,radius:4);checks["boss_\(index)_shield_protects"]=b.health==b.maximumHealth
                checks["boss_\(index)_fuse_reachable"]=b.fuse.frame.minY<geometry.ceiling-4 && b.fuse.frame.minY>geometry.paddleY
                ball.node.position=b.fuse.position;_ = b.collide(ball,radius:4);checks["boss_\(index)_fuse_opens"]=b.shieldRemaining>0
            }
            var awarded=0
            for _ in 0..<b.maximumHealth {
                b.hitCooldown=0
                ball.node.position=CGPoint(x:b.body.position.x,y:b.body.frame.minY-3)
                ball.velocity=CGVector(dx:0,dy:200)
                let result=b.collide(ball,radius:4);awarded += result.points
                checks["boss_\(index)_approach_reflects"]=result.collided && ball.velocity.dy<0
            }
            checks["boss_\(index)_defeatable"]=b.defeated
            checks["boss_\(index)_score_once"]=awarded==10000 && b.collide(ball,radius:4).points==0
        }
        return checks
    }
}
