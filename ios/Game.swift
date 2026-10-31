import UIKit
import SpriteKit

struct Cell: Codable {
    let row, column, type, property, powerup, critter:Int
    var x:Double?=nil, y:Double?=nil, width:Double?=nil, height:Double?=nil
    var shape:String?=nil, art:String?=nil, hits:Int?=nil, score:Int?=nil, powerupName:String?=nil, rotation:Double?=nil
    var polygon:[[Double]]?=nil
    var powerupProbability:Double?=nil, special:String?=nil
    var specialSettings:[String:String]?=nil
    var key:String { "\(row):\(column)" }
}
struct Stage: Decodable { let index, levelType, background: Int; let critterSpawns: [Int]; let cells: [Cell]; var backgroundArt:String?=nil; var sourceName:String?=nil, sourceSettings:[String:String]?=nil; var hidden:Bool?=nil }
struct Campaign: Decodable { let levels: [Stage] }
struct SavedRun: Codable { let stage, score, lives: Int; let hits: [String:Int]; var multiplier:Int?=nil; var returnStage:Int?=nil; var tokens:[MultiplierToken]?=nil }
struct MultiplierToken:Codable { var value:Int; var seconds:Double }
enum StageLoadError: Error { case missingResource, invalidGrid }

@main class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Blasterball", sessionRole: session.role)
        configuration.delegateClass = BlasterballSceneDelegate.self
        return configuration
    }
}
final class BlasterballSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let navigation=GameNavigationController(rootViewController:GameController())
        navigation.setNavigationBarHidden(true,animated:false)
        window.rootViewController = navigation
        self.window = window
        window.makeKeyAndVisible()
    }
    func sceneWillResignActive(_ scene: UIScene) {
        ((window?.rootViewController as? UINavigationController)?.topViewController as? GameController)?.backgroundPause()
    }
}

// Unmodified game pixels: crop verified atlas cells, then let SpriteKit interpolate display scaling.
enum OriginalArt {
    static var edition = "revolution"
    static var images:[String:CGImage] = [:]
    static var textures:[String:SKTexture] = [:]
    static func source(_ name:String)->CGImage? {
        let key="\(edition):\(name)"
        if let image=images[key] { return image }
        guard let url=Bundle.main.url(forResource:name,withExtension:"png",subdirectory:"Editions/\(edition)"), let image=UIImage(contentsOfFile:url.path)?.cgImage else { return nil }
        images[key]=image; return image
    }
    static func third(_ name:String)->SKTexture? {
        let name=name.hasPrefix("BB3/") ? String(name.dropFirst(4)):name
        let key="bb3:\(name)"
        if let t=textures[key] { return t }
        guard let url=Bundle.main.url(forResource:name,withExtension:"png",subdirectory:"BB3"),let image=UIImage(contentsOfFile:url.path)?.cgImage else { return nil }
        let t=SKTexture(cgImage:image);t.filteringMode = .linear;textures[key]=t;return t
    }
    static func thirdCrop(_ name:String,_ rect:CGRect)->SKTexture? {
        let key="bb3crop:\(name):\(rect)"
        if let t=textures[key] {return t}
        guard let image=third(name)?.cgImage().cropping(to:rect) else {return nil}
        let t=SKTexture(cgImage:image);t.filteringMode = .linear;textures[key]=t;return t
    }
    static func rgba(_ image:CGImage)->[UInt8]? {
        var pixels=[UInt8](repeating:0,count:image.width*image.height*4)
        let drawn=pixels.withUnsafeMutableBytes { bytes -> Bool in
            guard let context=CGContext(data:bytes.baseAddress,width:image.width,height:image.height,bitsPerComponent:8,bytesPerRow:image.width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo.byteOrder32Big.rawValue|CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image,in:CGRect(x:0,y:0,width:image.width,height:image.height)); return true
        }
        return drawn ? pixels:nil
    }
    static func texture(_ name:String,rect:CGRect,maskRect:CGRect?=nil,trimAlpha:Bool=false)->SKTexture? {
        let key="\(edition)-\(name)-\(rect)-\(String(describing:maskRect))-\(trimAlpha)"
        if let texture=textures[key] { return texture }
        guard let source=source(name), CGRect(x:0,y:0,width:source.width,height:source.height).contains(rect), var crop=source.cropping(to:rect) else { return nil }
        if let maskRect=maskRect {
            guard let mask=source.cropping(to:maskRect), mask.width == crop.width, mask.height == crop.height, var colors=rgba(crop), let grayscale=rgba(mask) else { return nil }
            for i in stride(from:0,to:colors.count,by:4) {
                // Native separate masks: grayscale 0 is transparent, 255 is opaque.
                let alpha=(Int(grayscale[i])+Int(grayscale[i+1])+Int(grayscale[i+2]))/3
                for channel in 0..<3 { colors[i+channel]=UInt8((Int(colors[i+channel])*alpha+127)/255) }
                colors[i+3]=UInt8(alpha)
            }
            guard let provider=CGDataProvider(data:Data(colors) as CFData), let masked=CGImage(width:crop.width,height:crop.height,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:crop.width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo(rawValue:CGBitmapInfo.byteOrder32Big.rawValue|CGImageAlphaInfo.premultipliedLast.rawValue),provider:provider,decode:nil,shouldInterpolate:true,intent:.defaultIntent) else { return nil }
            crop=masked
        }
        if trimAlpha, let pixels=rgba(crop) {
            let width=crop.width,height=crop.height; var minX=width,minY=height,maxX = -1,maxY = -1
            for y in 0..<height { for x in 0..<width where pixels[(y*width+x)*4+3] > 0 { minX=min(minX,x); maxX=max(maxX,x); minY=min(minY,y); maxY=max(maxY,y) } }
            if maxX >= minX, maxY >= minY, let trimmed=crop.cropping(to:CGRect(x:minX,y:minY,width:maxX-minX+1,height:maxY-minY+1)) { crop=trimmed }
        }
        let texture=SKTexture(cgImage:crop); texture.filteringMode = .linear; textures[key]=texture; return texture
    }
    // Editor and native REA: brick type t is opaque, top-row cell (t-1)*30,0,30,15.
    static func brick(_ type:Int,frame:Int=0)->SKTexture? { guard (1...14).contains(type) else { return nil }; return texture("BB2-bricks",rect:CGRect(x:(type-1)*30,y:(frame%17)*15,width:30,height:15)) }
    static func door(_ frame:Int)->SKTexture? { texture("BB2-door",rect:CGRect(x:0,y:min(7,max(0,frame))*23,width:67,height:23)) }
    static func critter(_ kind:Int,frame:Int)->SKTexture? {
        let names=[0:"drifter",1:"darter",2:"breaker",4:"exploder",5:"layer"]
        guard let name=names[kind] else { return nil }
        let f=frame%16,x=(f/4)*32,y=(f%4)*32
        return texture("BB2-"+name,rect:CGRect(x:x,y:y,width:32,height:32),maskRect:CGRect(x:x,y:y+128,width:32,height:32))
    }
    static func backdrop(_ id:Int)->SKTexture? { texture("BB2-background-\(id)",rect:CGRect(x:110,y:0,width:420,height:480)) }
    // Native first animation frame; variants horizontal, animation frames vertical.
    static func paddle(frame:Int=0)->SKTexture? { if edition == "bb3" { return third("paddle_\(frame%8)") }; return texture("BB2-paddle",rect:CGRect(x:0,y:(frame%8)*24,width:128,height:24),maskRect:CGRect(x:0,y:192+(frame%8)*24,width:128,height:24),trimAlpha:true) }
    static func ball()->SKTexture? { if edition == "bb3" { return third("ball") }; return texture("BB2-ball",rect:CGRect(x:0,y:0,width:16,height:16),maskRect:CGRect(x:0,y:16,width:16,height:16),trimAlpha:true) }
    static func drop(_ id:Int,frame:Int=0)->SKTexture? {
        if edition == "bb3" { let names=[1:"SplitBall",3:"SlowBall",6:"SmallPaddle",8:"GrowPaddle",9:"1Up",15:"FastBall",20:"Scorex2",21:"Scorex3",22:"BigBall",23:"ExplosiveBall",24:"Flash",25:"8Ball",26:"Vision",27:"ReplicateBall",28:"InertialPaddle",29:"Laser",30:"Zap",31:"BlasterBall",32:"EnergyBall",33:"Hovering",34:"TwinPaddles",35:"PhantomPaddle",36:"Attach",37:"Catcher",38:"NightBall"]; return names[id].flatMap { third("powerup_\($0)") } }
        return texture("BB2-powerup",rect:CGRect(x:(id-1)*32,y:(frame%16)*32,width:32,height:32),maskRect:CGRect(x:(id-1)*32,y:512+(frame%16)*32,width:32,height:32)) }
}

enum GameEdition: String, CaseIterable {
    case revolution, remix, holidays, bb3
    var title:String { switch self { case .revolution:return "Revolution"; case .remix:return "Remix"; case .holidays:return "Holidays"; case .bb3:return "Blasterball 3" } }
    var detail:String { switch self { case .revolution:return "The original Blasterball 2 campaign"; case .remix:return "A new arrangement of classic stages"; case .holidays:return "The seasonal Blasterball 2 edition"; case .bb3:return "100 stages · 10 secret layouts" } }
    var saveKey:String { self == .revolution ? "wireproof.blasterball.v02.run" : "wireproof.blasterball.v03.\(rawValue).run" }
}

final class LibraryController: UITableViewController {
    enum Page { case games, editions, third }
    let page:Page
    var choose:((GameEdition)->Void)?
    var cancel:(()->Void)?
    init(page:Page) { self.page=page; super.init(style:.insetGrouped) }
    required init?(coder:NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad(); overrideUserInterfaceStyle = .dark
        view.backgroundColor=UIColor(red:0.015,green:0.055,blue:0.09,alpha:1)
        tableView.rowHeight=110; tableView.separatorStyle = .none
        title=page == .games ? "Blasterball" : (page == .editions ? "Blasterball 2" : "Blasterball 3")
        navigationController?.navigationBar.prefersLargeTitles=true
        if page == .games, cancel != nil { navigationItem.rightBarButtonItem=UIBarButtonItem(title:"Return",style:.plain,target:self,action:#selector(closeLibrary)) }
        if page == .third {
            let text=UILabel(); text.text="Blasterball 3\nIn development\n\nThe original files are preserved. Its levels and mechanics are still being decoded for iOS.\n\nChoose Blasterball 2 to play now."; text.numberOfLines=0; text.textColor = .lightGray; text.font = .systemFont(ofSize:18); text.frame=CGRect(x:24,y:0,width:view.bounds.width-48,height:310)
            let box=UIView(frame:CGRect(x:0,y:0,width:view.bounds.width,height:330)); box.addSubview(text); text.autoresizingMask=[.flexibleWidth]; tableView.tableHeaderView=box
        }
    }
    @objc func closeLibrary() { cancel?() }
    override func tableView(_ tableView:UITableView,numberOfRowsInSection section:Int)->Int { page == .games ? 2 : (page == .editions ? 3:0) }
    override func tableView(_ tableView:UITableView,titleForHeaderInSection section:Int)->String? { page == .games ? "CHOOSE A GAME" : (page == .editions ? "CHOOSE AN EDITION" : nil) }
    override func tableView(_ tableView:UITableView,titleForFooterInSection section:Int)->String? { page == .editions ? "Each edition includes its first 12 original layouts. Some special mechanics remain under reconstruction. Progress is saved separately." : nil }
    override func tableView(_ tableView:UITableView,cellForRowAt indexPath:IndexPath)->UITableViewCell {
        let cell=UITableViewCell(style:.subtitle,reuseIdentifier:nil); cell.accessoryType = .disclosureIndicator; cell.backgroundColor=UIColor(red:0.035,green:0.13,blue:0.19,alpha:1)
        cell.textLabel?.font = .systemFont(ofSize:25,weight:.bold); cell.textLabel?.textColor = .white
        cell.detailTextLabel?.font = .systemFont(ofSize:13); cell.detailTextLabel?.textColor = .systemCyan; cell.detailTextLabel?.numberOfLines=2
        if page == .games {
            cell.textLabel?.text=indexPath.row == 0 ? "Blasterball 2" : "Blasterball 3"
            cell.detailTextLabel?.text=indexPath.row == 0 ? "Revolution · Remix · Holidays" : "Play the recovered campaign"
        } else {
            let edition=GameEdition.allCases[indexPath.row]; cell.textLabel?.text=edition.title
            var detail=edition.detail
            if let data=UserDefaults.standard.data(forKey:edition.saveKey), let saved=try? JSONDecoder().decode(SavedRun.self,from:data) { detail += "\nContinue at stage \(saved.stage+1)" }
            cell.detailTextLabel?.text=detail
        }
        let resource:String, directory:String
        if page == .games && indexPath.row == 1 { resource="BB3-title"; directory="Menu" }
        else { resource="BB2-title"; directory="Editions/\(page == .editions ? GameEdition.allCases[indexPath.row].rawValue : "revolution")" }
        if let url=Bundle.main.url(forResource:resource,withExtension:"png",subdirectory:directory),let image=UIImage(contentsOfFile:url.path) {
            cell.imageView?.image=image.preparingThumbnail(of:CGSize(width:76,height:76)); cell.imageView?.contentMode = .scaleAspectFit; cell.imageView?.layer.cornerRadius=9; cell.imageView?.clipsToBounds=true
        }
        return cell
    }
    override func tableView(_ tableView:UITableView,didSelectRowAt indexPath:IndexPath) {
        tableView.deselectRow(at:indexPath,animated:true)
        if page == .games { if indexPath.row == 1 { choose?(.bb3) } else { let next=LibraryController(page:.editions); next.choose=choose; navigationController?.pushViewController(next,animated:true) } }
        else if page == .editions { choose?(GameEdition.allCases[indexPath.row]) }
    }
}

struct DisplayLayout {
    let frame:CGRect, thumb:CGRect, compact:Bool
    var extendedFrame:CGRect { CGRect(x:frame.minX,y:frame.minY,width:frame.width,height:thumb.maxY-frame.minY) }
    static func make(bounds:CGRect,safe:UIEdgeInsets,closed:Bool?,mode:String="auto")->DisplayLayout {
        let available=bounds.inset(by:safe)
        let compact=bounds.height > bounds.width // Portrait uses an adaptive arena; landscape uses PC composition.
        let thumbHeight=min(96,max(64,available.height*0.1))
        let frame=CGRect(x:available.minX,y:available.minY,width:available.width,height:max(1,available.height-thumbHeight))
        let thumb=CGRect(x:available.minX,y:frame.maxY,width:available.width,height:bounds.maxY-frame.maxY)
        return DisplayLayout(frame:frame,thumb:thumb,compact:compact)
    }
}
final class SteeringStrip:UIView {
    var steer:((CGPoint)->Void)?, release:(()->Void)?
    override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?) { move(touches) }
    override func touchesMoved(_ touches:Set<UITouch>,with event:UIEvent?) { move(touches) }
    override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?) { release?() }
    override func touchesCancelled(_ touches:Set<UITouch>,with event:UIEvent?) { }
    private func move(_ touches:Set<UITouch>) { if let t=touches.first { steer?(t.location(in:superview)) } }
}

final class GameNavigationController: UINavigationController {
    override var childForStatusBarHidden:UIViewController? { topViewController }
}
final class GameController: UIViewController {
    let scene=GameScene(size:CGSize(width:390,height:844))
    let menu=UIButton(type:.system), gameView=SKView()
    let steering=SteeringStrip(), steeringHint=UILabel()
    let railStatus=UILabel(), railScroll=UIScrollView()
    let railTokens=UIStackView()
    lazy var nativePause=UIBarButtonItem(image:UIImage(systemName:"pause.fill"),style:.plain,target:self,action:#selector(showPause))
    lazy var nativeLibrary=UIBarButtonItem(image:UIImage(systemName:"square.grid.2x2"),style:.plain,target:self,action:#selector(openLibrary))
    var nativeRail=false
    var hingeClosed:Bool?
    var layoutRefresh:DispatchWorkItem?
    var railLayoutTimer:Timer?
    var initialPresentation=false
    override var prefersStatusBarHidden:Bool { !nativeRail }
    override var supportedInterfaceOrientations:UIInterfaceOrientationMask { .allButUpsideDown }
    override func viewDidLoad() {
        super.viewDidLoad(); overrideUserInterfaceStyle = .dark; view.backgroundColor = .black
        gameView.preferredFramesPerSecond=120; gameView.ignoresSiblingOrder=true; gameView.backgroundColor = .black; view.addSubview(gameView)
        menu.setTitle("PAUSE",for:.normal); menu.titleLabel?.font = .systemFont(ofSize:13,weight:.bold)
        menu.tintColor = .cyan; menu.accessibilityLabel="Pause and game menu"; menu.addTarget(self,action:#selector(showPause),for:.touchUpInside); view.addSubview(menu)
        railStatus.numberOfLines=0; railStatus.font = .monospacedDigitSystemFont(ofSize:9,weight:.semibold)
        railStatus.textColor = .cyan; railStatus.textAlignment = .center
        railStatus.frame=CGRect(x:0,y:0,width:52,height:176)
        railStatus.accessibilityLabel="Stage, score, high score, lives, multiplier and active powerups"
        nativePause.accessibilityLabel="Pause and game menu"; nativeLibrary.accessibilityLabel="Choose game"
        navigationItem.rightBarButtonItems=[nativePause,nativeLibrary]
        railScroll.backgroundColor = .black; railScroll.showsVerticalScrollIndicator=false
        railScroll.addSubview(railStatus)
        railTokens.axis = .vertical; railTokens.spacing=5; railScroll.addSubview(railTokens)
        navigationController?.view.addSubview(railScroll)
        railScroll.isHidden=true
        toolbarItems=[]
        navigationController?.setToolbarHidden(true,animated:false)
        scene.onStatus={ [weak self] _ in
            guard let self=self else { return }
            self.refreshRailTypography()
            self.layoutRailReadout()
            self.view.setNeedsLayout()
        }
        steering.backgroundColor = .clear
        steering.accessibilityLabel="Paddle steering area. Slide to steer; release to launch."
        steeringHint.text=nil; steeringHint.textColor = .lightGray
        steeringHint.font = .systemFont(ofSize:12); steeringHint.textAlignment = .center; steeringHint.isUserInteractionEnabled=false
        steering.addSubview(steeringHint); view.addSubview(steering)
        steering.steer={ [weak self] point in
            guard let self=self,self.gameView.bounds.width>0 else { return }
            let x=(point.x-self.gameView.frame.minX)/self.gameView.frame.width*self.scene.size.width
            self.scene.movePaddle(fraction:(x-self.scene.geometry.left)/(self.scene.geometry.right-self.scene.geometry.left))
        }
        steering.release={ [weak self] in self?.scene.launchOrContinue() }
        scene.scaleMode = .fill
        if #available(iOS 27.1, *) {
            view.addInteraction(UIHingeInteraction { [weak self] _, update in
                guard let self=self,let hinge=update.hinge else { return }
                if hinge.status != .unknown { self.hingeClosed=hinge.status == .closed }
                self.layoutRefresh?.cancel()
                let work=DispatchWorkItem { [weak self] in self?.view.setNeedsLayout(); self?.view.layoutIfNeeded() }
                self.layoutRefresh=work; DispatchQueue.main.asyncAfter(deadline:.now()+0.25,execute:work)
            })
        }
        gameView.presentScene(scene)
        NotificationCenter.default.addObserver(self,selector:#selector(backgroundPause),name:UIApplication.willResignActiveNotification,object:nil)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var edge=false
        let preference=UserDefaults.standard.string(forKey:"wireproof.bb2.display") ?? "auto"
        let pc=view.bounds.width > view.bounds.height
        if #available(iOS 27.1, *) { edge=traitCollection.verticalBarEdge != .unspecified && !pc }
        if nativeRail != edge {
            nativeRail=edge
            navigationController?.setNavigationBarHidden(!edge,animated:false)
            navigationController?.setToolbarHidden(true,animated:false)
            setNeedsStatusBarAppearanceUpdate()
        }
        var closed=pc ? false:(edge ? true:hingeClosed)
        var mode=pc ? "pc":preference
        #if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--preview-closed") { closed=true; mode="right" }
        if ProcessInfo.processInfo.arguments.contains("--preview-pc") { closed=false; mode="pc" }
        #endif
        var safe=view.safeAreaInsets
        // Hidden system bars can leave an obsolete side inset after unfolding.
        // Fullscreen landscape draws through that region; the steering strip retains bottom protection.
        if pc { safe.left=0; safe.right=0 }
        let layout=DisplayLayout.make(bounds:view.bounds,safe:safe,closed:closed,mode:mode)
        let frame=layout.frame, compact=layout.compact
        gameView.frame=layout.extendedFrame
        scene.artworkBottomInset=layout.thumb.height
        steering.frame=layout.thumb; steeringHint.frame=steering.bounds
        // The steering overlay must never intercept the UIKit pause control.
        view.bringSubviewToFront(menu)
        scene.nativeSidebar=edge && compact
        scene.configureViewport(viewSize:layout.extendedFrame.size,safeInsets:.zero,classic:!compact)
        scene.fitRoundSprites()
        menu.isHidden=edge
        railScroll.isHidden = !edge
        layoutRailReadout()
        let scale=frame.width/scene.size.width
        let panelX=scene.geometry.classic ? (scene.edition == .bb3 ? 560.0:530.0):420.0
        menu.frame=CGRect(x:frame.minX+CGFloat(panelX)*scale,y:layout.extendedFrame.maxY-max(48,32*scale)-view.safeAreaInsets.bottom,width:(scene.edition == .bb3 && scene.geometry.classic ? 80:110)*scale,height:max(44,28*scale))
        if scene.edition == .bb3 && scene.geometry.classic {
            menu.frame=CGRect(x:frame.minX+570*scale,y:layout.extendedFrame.minY+layout.extendedFrame.height*0.76,width:60*scale,height:max(44,26*scale))
        }

    }
    func refreshRailTypography() {
        let result=NSMutableAttributedString()
        let rows=[("STAGE",String(scene.stageIndex+1)),("SCORE",scene.score.formatted()),("BEST",scene.bestScore.formatted()),("LIVES",String(scene.lives)),("MULTIPLIER","×\(scene.scoreMultiplier)")]
        let paragraph=NSMutableParagraphStyle();paragraph.alignment = .center;paragraph.paragraphSpacing=6
        for (title,value) in rows {
            result.append(NSAttributedString(string:title+"\n",attributes:[.font:UIFont.systemFont(ofSize:7,weight:.medium),.foregroundColor:UIColor(white:0.65,alpha:1)]))
            result.append(NSAttributedString(string:value+"\n",attributes:[.font:UIFont.monospacedDigitSystemFont(ofSize:12,weight:.semibold),.foregroundColor:UIColor.white,.paragraphStyle:paragraph]))
        }
        if !scene.activePowerups.isEmpty {result.append(NSAttributedString(string:scene.activePowerups.joined(separator:"\n"),attributes:[.font:UIFont.systemFont(ofSize:8,weight:.medium),.foregroundColor:UIColor.systemTeal]))}
        railStatus.attributedText=result
    }
    func layoutRailReadout() {
        guard nativeRail,let host=navigationController?.view else { return }
        if railScroll.superview !== host { host.addSubview(railScroll) }
        let width=max(44,min(96,view.safeAreaInsets.right))
        // Live Activities can push the native controls down. Measure their public
        // accessibility-labelled views rather than assuming a fixed toolbar position.
        var buttonBottom:CGFloat=0
        func inspect(_ node:UIView) {
            let label=node.accessibilityLabel ?? ""
            let rect=node.convert(node.bounds,to:host)
            let railControl=node is UIControl && rect.midX>=host.bounds.maxX-width-8
            if label=="Pause and game menu" || label=="Choose game" || railControl {
                if !node.isHidden && node.alpha>0 && rect.height>0 && rect.height<host.bounds.height*0.5 {buttonBottom=max(buttonBottom,rect.maxY)}
            }
            for child in node.subviews {inspect(child)}
        }
        if let bar=navigationController?.navigationBar {inspect(bar)}
        let top=max(host.bounds.height*0.58,buttonBottom+14)
        railScroll.frame=CGRect(x:host.bounds.maxX-width+3,y:top,width:width-6,height:max(40,host.bounds.height-top-max(12,view.safeAreaInsets.bottom)))
        refreshRailTypography()
        railStatus.frame=CGRect(x:0,y:0,width:railScroll.bounds.width,height:railStatus.sizeThatFits(CGSize(width:railScroll.bounds.width,height:2000)).height+8)
        railTokens.arrangedSubviews.forEach{$0.removeFromSuperview()}
        for token in scene.multiplierTokens {
            let row=UIStackView();row.axis = .horizontal;row.alignment = .center;row.spacing=2
            let icon=UIImageView();icon.contentMode = .scaleAspectFit
            let id=scene.edition == .bb3 ? (token.value==2 ? 20:21):(token.value==2 ? 10:11)
            if let cg=OriginalArt.drop(id)?.cgImage() {icon.image=UIImage(cgImage:cg)}
            icon.widthAnchor.constraint(equalToConstant:24).isActive=true;icon.heightAnchor.constraint(equalToConstant:24).isActive=true
            let remaining=UILabel();remaining.text="×\(token.value) \(Int(ceil(token.seconds)))s";remaining.font = .monospacedDigitSystemFont(ofSize:8,weight:.bold);remaining.textColor = .cyan
            row.addArrangedSubview(icon);row.addArrangedSubview(remaining);row.accessibilityLabel="Multiplier \(token.value), \(Int(ceil(token.seconds))) seconds remaining"
            railTokens.addArrangedSubview(row)
        }
        railTokens.frame=CGRect(x:0,y:railStatus.frame.maxY,width:railScroll.bounds.width,height:CGFloat(scene.multiplierTokens.count)*29)
        railScroll.contentSize=CGSize(width:railScroll.bounds.width,height:railTokens.frame.maxY)
        host.bringSubviewToFront(railScroll)
    }
    override func viewWillDisappear(_ animated:Bool) { super.viewWillDisappear(animated); railScroll.isHidden=true;railLayoutTimer?.invalidate();railLayoutTimer=nil }
    func refreshRailTimer() {
        railLayoutTimer?.invalidate()
        railLayoutTimer=Timer.scheduledTimer(withTimeInterval:0.5,repeats:true) { [weak self] _ in
            guard let self=self,self.presentedViewController==nil else {return}
            self.layoutRailReadout()
        }
    }
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange(); view.setNeedsLayout()
    }
    override func viewWillTransition(to size:CGSize,with coordinator:UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to:size,with:coordinator)
        coordinator.animate(alongsideTransition:nil) { [weak self] _ in
            self?.view.setNeedsLayout(); self?.view.layoutIfNeeded()
        }
    }
    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated);refreshRailTimer();railScroll.isHidden = !nativeRail; guard !initialPresentation else { return }; initialPresentation=true
        let args=ProcessInfo.processInfo.arguments
        if args.contains("--smoke-test") {
            var edition=GameEdition.revolution
            if let i=args.firstIndex(of:"--edition"),i+1<args.count { edition=GameEdition(rawValue:args[i+1]) ?? .revolution }
            scene.testing=true; scene.loadEdition(edition); scene.runSmokeTest()
            #if targetEnvironment(simulator)
            if let i=args.firstIndex(of:"--preview-stage"),i+1<args.count,let stage=Int(args[i+1]) {scene.start(index:stage)}
            if args.contains("--preview-ports") { scene.previewPorts() }
            if args.contains("--preview-celebration") { scene.testing=true; scene.finished=true;scene.cleared=true;scene.showCelebration(campaignComplete:true) }
            if args.contains("--verify-pause") {
                DispatchQueue.main.asyncAfter(deadline:.now()+1) { [weak self] in
                    guard let self=self,let window=self.view.window else {return}
                    self.view.layoutIfNeeded()
                    let point=self.menu.convert(CGPoint(x:self.menu.bounds.midX,y:self.menu.bounds.midY),to:window)
                    let target=window.hitTest(point,with:nil)
                    let hittable=target === self.menu || target?.isDescendant(of:self.menu)==true
                    if hittable {self.menu.sendActions(for:.touchUpInside)}
                    DispatchQueue.main.asyncAfter(deadline:.now()+0.6) {
                        let result:[String:Any]=["hittable":hittable,"hitView":String(describing:type(of:target)),"paused":self.scene.frozen,"menuPresented":self.presentedViewController is UIAlertController]
                        if let data=try? JSONSerialization.data(withJSONObject:result,options:.prettyPrinted),let dir=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first {try? data.write(to:dir.appendingPathComponent("pause-check.json"))}
                    }
                }
            }
            if args.contains("--preview-multipliers") {scene.applyPowerup(scene.edition == .bb3 ? 20:10);scene.applyPowerup(scene.edition == .bb3 ? 21:11)}
            #endif
        } else { showLibrary() }
        #if targetEnvironment(simulator)
        if args.contains("--preview-landscape"),#available(iOS 16.0, *) {
            view.window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations:.landscapeRight))
        }
        #endif
    }
    @objc func openLibrary() { showLibrary() }
    func showLibrary() {
        scene.save(); scene.setPaused(true)
        let picker=LibraryController(page:.games), nav=UINavigationController(); nav.modalPresentationStyle = .fullScreen; nav.overrideUserInterfaceStyle = .dark; nav.navigationBar.tintColor = .systemCyan; nav.viewControllers=[picker]
        picker.choose={ [weak self,weak nav] edition in nav?.dismiss(animated:true) { self?.scene.loadEdition(edition) } }
        if scene.loaded { picker.cancel={ [weak self,weak nav] in nav?.dismiss(animated:true) { self?.scene.setPaused(false) } } }
        presentMenuController(nav)
    }
    @objc func backgroundPause() { scene.save(); scene.setPaused(true) }
    func presentMenuController(_ controller:UIViewController) {
        if let current=presentedViewController {
            if current.isBeingDismissed,let coordinator=current.transitionCoordinator {
                coordinator.animate(alongsideTransition:nil) { [weak self] _ in self?.present(controller,animated:true) }
            } else { current.dismiss(animated:true) { [weak self] in self?.present(controller,animated:true) } }
        } else { present(controller,animated:true) }
    }
    func presentSheet(_ sheet:UIAlertController) {
        if nativeRail {sheet.popoverPresentationController?.barButtonItem=nativePause}
        else {sheet.popoverPresentationController?.sourceView=menu;sheet.popoverPresentationController?.sourceRect=menu.bounds}
        presentMenuController(sheet)
    }
    @objc func showPause() {
        guard presentedViewController == nil else { return }
        guard scene.loaded else { showLibrary(); return }
        scene.setPaused(true)
        let sheet=UIAlertController(title:scene.edition == .bb3 ? "Blasterball 3": "Blasterball 2 · \(scene.edition.title)",message:"Stage \(scene.stageIndex+1) of \(scene.campaign.count)",preferredStyle:.actionSheet)
        sheet.addAction(UIAlertAction(title:"Resume",style:.cancel){ [weak self] _ in self?.scene.setPaused(false) })
        sheet.addAction(UIAlertAction(title:"Restart stage",style:.default){ [weak self] _ in guard let self=self else{return}; self.scene.start(index:self.scene.stageIndex) })
        sheet.addAction(UIAlertAction(title:"Choose stage",style:.default){ [weak self] _ in DispatchQueue.main.async { self?.selectStage() } })
        sheet.addAction(UIAlertAction(title:"Change game",style:.default){ [weak self] _ in DispatchQueue.main.async { self?.showLibrary() } })
        sheet.addAction(UIAlertAction(title:GameAudio.shared.enabled ? "Sound: On — turn off" : "Sound: Off — turn on",style:.default){ [weak self] _ in GameAudio.shared.enabled.toggle(); self?.scene.setPaused(false) })
        presentSheet(sheet)
    }
    func selectStage() {
        let sheet=UIAlertController(title:"\(scene.edition.title) stages",message:"Selecting a stage starts a fresh run.",preferredStyle:.actionSheet)
        for (i,stage) in scene.campaign.enumerated() { sheet.addAction(UIAlertAction(title:String(format:"Stage %02d · %d bricks",i+1,stage.cells.filter{$0.type != 0 || $0.art != nil}.count),style:.default){ [weak self] _ in self?.scene.start(index:i) }) }
        sheet.addAction(UIAlertAction(title:"Resume",style:.cancel){ [weak self] _ in self?.scene.setPaused(false) }); presentSheet(sheet)
    }
}

struct BoardGeometry {
    var classic:Bool
    var size:CGSize, left:CGFloat, right:CGFloat, ceiling:CGFloat, paddleY:CGFloat, unit:CGFloat
    var artworkExtension:CGFloat=0
    var center:CGFloat { (left+right)/2 }
    var gridLeft:CGFloat { center-195*unit }
    func brickRect(_ cell:Cell)->CGRect {
        if let x=cell.x,let y=cell.y,let w=cell.width,let h=cell.height {
            let u=min((right-left)/480,(ceiling-paddleY-50)/360)
            return CGRect(x:center-240*u+x*u,y:ceiling-25-(y+h)*u,width:w*u,height:h*u)
        }
        return CGRect(x:gridLeft+CGFloat(cell.column)*30*unit,y:(classic ? 435+artworkExtension:ceiling)-(CGFloat(cell.row)+1)*16*unit,width:29*unit,height:15*unit)
    }
    static func make(viewSize:CGSize,safeInsets:UIEdgeInsets,classic:Bool?=nil,nativeSidebar:Bool=false)->BoardGeometry {
        let pc=classic ?? (viewSize.width >= viewSize.height || viewSize.height/max(1,viewSize.width)<1.65)
        if pc { return BoardGeometry(classic:true,size:CGSize(width:640,height:480),left:125,right:515,ceiling:458,paddleY:35,unit:1) }
        let width:CGFloat=nativeSidebar ? 420:530
        let scale=max(0.1,viewSize.width/width)
        let size=CGSize(width:width,height:viewSize.height/scale)
        return BoardGeometry(classic:false,size:size,left:15,right:405,ceiling:size.height-35,paddleY:40,unit:min(1,max(0.25,(size.height-105)/320)))
    }

}

final class LiveBall {
    let node: SKShapeNode; var velocity: CGVector; var trailClock: CGFloat = 0
    init(node:SKShapeNode,velocity:CGVector) { self.node=node; self.velocity=velocity }
}
final class LiveBrick {
    let node: SKShapeNode, raw: Cell; var rect: CGRect; var hits: Int
    var breakable: Bool { raw.art != nil ? (raw.hits ?? 1)>0:raw.type != 8 }
    init(node:SKShapeNode,rect:CGRect,raw:Cell,hits:Int) { self.node=node; self.rect=rect; self.raw=raw; self.hits=hits }
}
struct OriginalEnemySpec:Decodable {
    struct Layer:Decodable { let art:String;let slot:Int;let shadow:Bool;let opacity:Double;let z:Int;let rotationDegrees:Double;let scale:Double }
    let name:String,type:String;let speed:Double;let score:Int;let timeStatic:Double,timeMoving:Double;let layers:[Layer]
    static let all:[OriginalEnemySpec] = {
        guard let url=Bundle.main.url(forResource:"enemy-specs",withExtension:"json",subdirectory:"BB3"),let data=try? Data(contentsOf:url) else {return []}
        return (try? JSONDecoder().decode([OriginalEnemySpec].self,from:data)) ?? []
    }()
}
final class LiveCritter {
    let node:SKSpriteNode, kind:Int; var velocity:CGVector; var age:CGFloat=0
    var third:OriginalEnemySpec?;var emerged=false
    var collisionRadius:CGFloat=12
    var scoreValue:Int {third?.score ?? 10}
    init(node:SKSpriteNode,kind:Int,velocity:CGVector,third:OriginalEnemySpec?=nil) { self.node=node;self.kind=kind;self.velocity=velocity;self.third=third }
}
struct Drop { let node:SKShapeNode; let kind:Int }

final class GameScene: SKScene {
    var onStatus:((String)->Void)?, onPause:((Bool)->Void)?
    var frozen = false, launched = false, finished = false, cleared = false, loaded = false
    var campaign:[Stage] = [], stageIndex = 0, lives = 3, score = 0
    var nativeSidebar=false
    var animationTime:TimeInterval = 0
    var animationTick = -1
    var paddle = SKShapeNode(), balls:[LiveBall] = [], bricks:[LiveBrick] = [], drops:[Drop] = []
    var hits:[String:Int] = [:], lastTime:TimeInterval = 0, paddleWidth:CGFloat = 66, ballSpeed:CGFloat = 285
    var artworkBottomInset:CGFloat=0
    var viewportSize=CGSize(width:390,height:844), viewportInsets=UIEdgeInsets.zero
    var geometry=BoardGeometry.make(viewSize:CGSize(width:390,height:844),safeInsets:.zero)
    var bigBall=false, explosiveBall=false
    var boss:BB3BossEncounter?
    var thirdTimers:[Int:CGFloat]=[:], thirdTime:CGFloat=0, laserClock:CGFloat=0, targetPaddleX:CGFloat?=nil
    var secretFound=false, hiddenReturnStage:Int?=nil
    var multiplier=1
    var multiplierTokens:[MultiplierToken]=[]
    var critters:[LiveCritter]=[]
    var portNodes:[SKSpriteNode]=[], portClock:CGFloat=0, portIndex:Int?=nil, portDidSpawn=false
    var enemyGenerationClock:CGFloat=0
    var radius:CGFloat { (bigBall ? 7:4)*geometry.unit }
    var paddleY:CGFloat { geometry.paddleY }
    var edition=GameEdition.revolution
    let prompt = SKLabelNode(fontNamed:"HelveticaNeue-Medium"), effectLabel = SKLabelNode(fontNamed:"HelveticaNeue-Bold")
    var saveKey:String { edition.saveKey }
    var testing = false
    var powerups:[Int:(String,UIColor)] {
        var values:[Int:(String,UIColor)] = [1:("×3",.systemCyan),3:("S",.systemBlue),6:("−",.systemPink),8:("+",.systemGreen),9:("1UP",.systemYellow),15:("F",.systemOrange),10:("×2",.systemYellow),11:("×3",.systemYellow)]
        if edition == .bb3 { values.merge([20:("×2",.systemYellow),21:("×3",.systemYellow),22:("BIG",.systemCyan),23:("BOMB",.systemRed),24:("FLASH",.white),25:("8 BALL",.cyan),26:("VISION",.cyan),27:("REPLICATE",.cyan),28:("INERTIA",.orange),29:("LASER",.red),30:("ZAP",.cyan),31:("BLASTER",.orange),32:("ENERGY",.yellow),33:("HOVER",.cyan),34:("TWIN",.cyan),35:("PHANTOM",.purple),36:("ATTACH",.green),37:("CATCHER",.green),38:("NIGHT",.purple)]) {_,new in new} }; return values
    }
    override func didMove(to view:SKView) { frozen=true; backgroundColor = .black }
    func sound(_ event:String) { if !testing { GameAudio.shared.play(event:event) } }
    func configureViewport(viewSize:CGSize,safeInsets:UIEdgeInsets,classic:Bool?=nil) {
        guard viewSize.width > 0,viewSize.height > 0 else { return }
        viewportSize=viewSize; viewportInsets=safeInsets
        let old=geometry
        let gameplayHeight=max(1,viewSize.height-artworkBottomInset)
        var next=BoardGeometry.make(viewSize:CGSize(width:viewSize.width,height:gameplayHeight),safeInsets:safeInsets,classic:classic,nativeSidebar:nativeSidebar)
        let extensionHeight=artworkBottomInset*next.size.height/gameplayHeight
        next.artworkExtension=extensionHeight;next.size.height += extensionHeight;next.ceiling += extensionHeight;next.paddleY += extensionHeight
        if edition == .bb3 {
            next.ceiling=next.size.height-18
            if next.classic { next.left=80; next.right=560 }
        }
        guard old.size != next.size || old.left != next.left || old.ceiling != next.ceiling || old.paddleY != next.paddleY else { return }
        geometry=next; size=next.size
        guard loaded else { return }
        let ratio=next.unit/old.unit
        func remap(_ p:CGPoint)->CGPoint {
            CGPoint(x:next.left+(p.x-old.left)/max(1,old.right-old.left)*(next.right-next.left),y:p.y/max(1,old.ceiling)*next.ceiling)
        }
        makeChrome()
        for brick in bricks {
            brick.rect=next.brickRect(brick.raw); brick.node.position=CGPoint(x:brick.rect.midX,y:brick.rect.midY)
            if let surface=brick.node.childNode(withName:"surface") as? SKSpriteNode { surface.size=brick.raw.art != nil ? brick.rect.size:CGSize(width:30*next.unit,height:15*next.unit); surface.position.x=0.5*next.unit }
        }
        paddleWidth *= ratio; ballSpeed *= ratio
        paddle.position=CGPoint(x:min(next.right-paddleWidth/2,max(next.left+paddleWidth/2,remap(paddle.position).x)),y:paddleY)
        if let surface=paddle.childNode(withName:"surface") as? SKSpriteNode, let texture=OriginalArt.paddle() { surface.size=CGSize(width:66*next.unit,height:66*next.unit*texture.size().height/texture.size().width) }
        for b in balls {
            let mapped=remap(b.node.position)
            b.node.position=launched ? CGPoint(x:min(next.right-radius,max(next.left+radius,mapped.x)),y:min(next.ceiling-radius,mapped.y)) : CGPoint(x:paddle.position.x,y:paddleY+13*next.unit)
            b.velocity.dx *= ratio; b.velocity.dy *= ratio
            b.node.childNode(withName:"surface")?.yScale=1; (b.node.childNode(withName:"surface") as? SKSpriteNode)?.size=CGSize(width:radius*2,height:radius*2)
        }
        for drop in drops { drop.node.position=remap(drop.node.position);drop.node.childNode(withName:"surface")?.yScale=1; (drop.node.childNode(withName:"surface") as? SKSpriteNode)?.size=CGSize(width:24*next.unit,height:24*next.unit) }
        for node in bricks.map({$0.node}) + balls.map({$0.node}) + drops.map({$0.node}) + [paddle] {
            if let surface=node.childNode(withName:"surface") as? SKSpriteNode,let shadow=node.childNode(withName:"shadow") as? SKSpriteNode { shadow.yScale=1;shadow.size=surface.size; shadow.position=CGPoint(x:5*next.unit,y:-7*next.unit) }
        }
        effectLabel.isHidden=nativeSidebar
        positionLabels(); lastTime=0
        updateHUD()
    }
    func positionLabels() {
        prompt.position=CGPoint(x:geometry.center,y:paddleY+65*geometry.unit)
        effectLabel.position=CGPoint(x:geometry.center,y:paddleY+35*geometry.unit)
    }
    func loadEdition(_ chosen:GameEdition) {
        save(); setPaused(true); loaded=false; removeAllChildren(); balls=[]; bricks=[]; drops=[]
        edition=chosen; OriginalArt.edition=chosen.rawValue
        GameAudio.shared.configure(edition:chosen.rawValue)
        do {
            guard let url=Bundle.main.url(forResource:chosen == .bb3 ? "campaign":chosen.rawValue,withExtension:"json",subdirectory:chosen == .bb3 ? "BB3":"Campaigns") else { throw StageLoadError.missingResource }
            campaign=try JSONDecoder().decode(Campaign.self,from:Data(contentsOf:url)).levels
            if chosen == .bb3 {
                guard !campaign.isEmpty,campaign.allSatisfy({ $0.cells.allSatisfy { $0.x != nil && $0.y != nil && $0.art != nil && OriginalArt.third($0.art!) != nil } }) else { throw StageLoadError.invalidGrid }
            } else {
            guard campaign.count == 12, campaign.allSatisfy({ s in s.cells.count == 260 && Set(s.cells.map{$0.key}).count == 260 && s.cells.allSatisfy { (0..<20).contains($0.row) && (0..<13).contains($0.column) && (0...14).contains($0.type) } }) else { throw StageLoadError.invalidGrid }
            guard OriginalArt.brick(1) != nil,OriginalArt.paddle() != nil,OriginalArt.ball() != nil,campaign.allSatisfy({ OriginalArt.backdrop($0.background) != nil }),powerups.keys.allSatisfy({ OriginalArt.drop($0) != nil }) else { throw StageLoadError.missingResource }
            }
            loaded=true
            configureViewport(viewSize:viewportSize,safeInsets:viewportInsets,classic:geometry.classic)
            if let data=UserDefaults.standard.data(forKey:saveKey),let saved=try? JSONDecoder().decode(SavedRun.self,from:data),campaign.indices.contains(saved.stage) {
                if saved.lives > 0 { start(index:saved.stage,resume:saved) } else { start(index:saved.stage) }
            } else { start(index:0) }
        } catch {
            backgroundColor = .black; prompt.text="Edition data could not be loaded"; prompt.fontSize=16; prompt.position=CGPoint(x:size.width/2,y:size.height/2); addChild(prompt); finished=true; onStatus?("Choose another game from the menu")
        }
    }
    func shape(_ rect:CGRect,_ color:UIColor,corner:CGFloat=2)->SKShapeNode {
        let n=SKShapeNode(rectOf:rect.size,cornerRadius:corner); n.position=CGPoint(x:rect.midX,y:rect.midY); n.fillColor=color; n.strokeColor=color.withAlphaComponent(0.7); n.lineWidth=0.6; return n
    }
    var roundYScale:CGFloat {
        guard viewportSize.width>0,viewportSize.height>0,size.width>0 else {return 1}
        return (viewportSize.width/size.width)/(viewportSize.height/size.height)
    }
    func fitRoundSprites() {
        for node in balls.map({$0.node}) + drops.map({$0.node}) {
            node.childNode(withName:"surface")?.yScale=roundYScale
            node.childNode(withName:"shadow")?.yScale=roundYScale
        }
        for critter in critters {critter.node.yScale=roundYScale}
        for node in childNode(withName:"readouts")?.children ?? [] where node.name=="round-token" {node.yScale=roundYScale}
    }
    func originalSurface(_ node:SKShapeNode,texture:SKTexture?,size:CGSize) {
        node.fillColor = .clear; node.strokeColor = .clear
        guard let texture=texture else { return }
        let sprite=SKSpriteNode(texture:texture); sprite.name="surface"; sprite.size=size; sprite.zPosition=0.2; node.addChild(sprite)
        let shadow=SKSpriteNode(texture:texture); shadow.name="shadow"; shadow.size=size
        shadow.position=CGPoint(x:5*geometry.unit,y:-7*geometry.unit); shadow.color = .black; shadow.colorBlendFactor=1; shadow.alpha=0.35; shadow.zPosition = -0.1; node.addChild(shadow)
    }
    func damagedSurface(_ node:SKShapeNode) {
        // Verified editor enum TwoHitHit=9, top-row source tile x=240.
        (node.childNode(withName:"surface") as? SKSpriteNode)?.texture=OriginalArt.brick(9)
    }
    func makeChrome() {
        childNode(withName:"backdrop")?.removeFromParent()
        backgroundColor = .black
        if edition == .bb3 { makeThirdChrome(); updateReadouts(); return }
        let name="BB2-background-\(campaign[stageIndex].background)"
        let root=SKNode(); root.name="backdrop"; root.zPosition = -10; addChild(root)
        func piece(_ label:String,_ source:CGRect,_ frame:CGRect) {
            guard let texture=OriginalArt.texture(name,rect:source) else { return }
            let node=SKSpriteNode(texture:texture); node.name=label; node.size=frame.size; node.position=CGPoint(x:frame.midX,y:frame.midY); root.addChild(node)
        }
        if geometry.classic {
            piece("originalPC",CGRect(x:0,y:0,width:640,height:480),CGRect(origin:.zero,size:size))
        } else {
            // Keep the original continuous frame; extend only its straight vertical runs.
            let crop=SKCropNode(); let mask=SKSpriteNode(color:.white,size:CGSize(width:390,height:size.height-22)); mask.position=CGPoint(x:210,y:(size.height-22)/2); crop.maskNode=mask; root.addChild(crop)
            if let texture=OriginalArt.texture(name,rect:CGRect(x:142,y:34,width:372,height:446)) {
                let image=SKSpriteNode(texture:texture); image.setScale(max(390/372,(size.height-22)/446)); image.position=mask.position; crop.addChild(image)
            }
            piece("leftRail",CGRect(x:110,y:22,width:15,height:458),CGRect(x:0,y:0,width:15,height:size.height-22))
            piece("rightRail",CGRect(x:515,y:22,width:15,height:458),CGRect(x:405,y:0,width:15,height:size.height-22))
            piece("top",CGRect(x:110,y:0,width:420,height:22),CGRect(x:0,y:size.height-22,width:420,height:22))
            if !nativeSidebar {
            let panel=SKSpriteNode(color:UIColor(red:0.025,green:0.08,blue:0.10,alpha:1),size:CGSize(width:110,height:size.height))
            panel.position=CGPoint(x:475,y:size.height/2); root.addChild(panel)
            }
        }
        setupPorts()
        updateReadouts()
    }
    func makeThirdChrome() {
        let root=SKNode();root.name="backdrop";root.zPosition = -10;addChild(root)
        if let texture=campaign[stageIndex].backgroundArt.flatMap({OriginalArt.third($0)}) {
            let bg=SKSpriteNode(texture:texture);bg.size=size;bg.position=CGPoint(x:size.width/2,y:size.height/2);bg.zPosition = -2;root.addChild(bg)
        }
        let left=geometry.left,right=geometry.right
        for (x,flip) in [(left-7,true),(right+7,false)] {
            if let texture=OriginalArt.thirdCrop("vista_left",CGRect(x:235,y:194,width:21,height:700)) {
                let rail=SKSpriteNode(texture:texture);rail.size=CGSize(width:14,height:size.height-18);rail.position=CGPoint(x:x,y:(size.height-18)/2);if flip {rail.xScale = -1};root.addChild(rail)
            }
        }
        if let texture=OriginalArt.third("top_bar") { let bar=SKSpriteNode(texture:texture);bar.size=CGSize(width:right-left+28,height:18);bar.position=CGPoint(x:geometry.center,y:size.height-9);root.addChild(bar) }
        if geometry.classic {
            for x in [CGFloat(0),CGFloat(560)] {
                let backing=SKSpriteNode(color:UIColor(red:0.03,green:0.30,blue:0.55,alpha:1),size:CGSize(width:80,height:size.height))
                backing.position=CGPoint(x:x+40,y:size.height/2);root.addChild(backing)
                // Only the actual instrument panel, excluding white atlas padding and the arena rail.
                if let texture=OriginalArt.thirdCrop("left_side_blue",CGRect(x:53,y:262,width:130,height:578)) {
                    let side=SKSpriteNode(texture:texture);side.size=CGSize(width:58,height:size.height*0.76);side.position=CGPoint(x:x+40,y:size.height*0.43);root.addChild(side)
                }
            }
        } else if !nativeSidebar {
            let backing=SKSpriteNode(color:UIColor(red:0.025,green:0.045,blue:0.07,alpha:1),size:CGSize(width:110,height:size.height))
            backing.position=CGPoint(x:475,y:size.height/2);root.addChild(backing)
        }
        setupPorts()
    }
    func updateReadouts() {
        childNode(withName:"readouts")?.removeFromParent()
        let root=SKNode(); root.name="readouts"; root.zPosition=20; addChild(root)
        func label(_ value:String,_ x:CGFloat,_ y:CGFloat,_ size:CGFloat=26) {
            let node=SKLabelNode(fontNamed:"DINCondensed-Bold"); node.text=value; node.fontSize=size; node.fontColor = .cyan
            node.horizontalAlignmentMode = .left; node.verticalAlignmentMode = .center; node.position=CGPoint(x:x,y:geometry.classic ? y*self.size.height/480:y); root.addChild(node)
        }
        func stat(_ title:String,_ value:String,x:CGFloat,y:CGFloat,width:CGFloat=62) {
            for (text,offset,font,color) in [(title,CGFloat(0),CGFloat(11),UIColor(white:0.85,alpha:1)),(value,CGFloat(-19),CGFloat(17),UIColor.white)] {
                let node=SKLabelNode(fontNamed:"Menlo-Bold");node.name="panel-stat";node.text=text;node.fontSize=font;node.fontColor=color
                node.horizontalAlignmentMode = .center;node.verticalAlignmentMode = .center;node.position=CGPoint(x:x,y:y+offset)
                if node.frame.width>width {node.xScale=width/node.frame.width}
                root.addChild(node)
            }
        }
        if geometry.classic && edition == .bb3 {
            stat("BEST",bestScore.formatted(),x:40,y:size.height*0.94)
            stat("SCORE",score.formatted(),x:600,y:size.height*0.94)
            stat("LEVEL",String(stageIndex+1),x:40,y:size.height*0.66)
            stat("LIVES",String(lives),x:600,y:size.height*0.66)
            stat("MULT","×\(scoreMultiplier)",x:600,y:size.height*0.48)
        } else if geometry.classic {
            for x in [CGFloat(0),CGFloat(530)] {
                let panel=SKShapeNode(rectOf:CGSize(width:106,height:size.height*0.78),cornerRadius:6)
                panel.position=CGPoint(x:x+55,y:size.height*0.61);panel.fillColor=UIColor(red:0.015,green:0.035,blue:0.06,alpha:1);panel.strokeColor=UIColor(white:1,alpha:0.12);root.addChild(panel)
            }
            stat("STAGE",String(stageIndex+1),x:55,y:size.height*0.92,width:92)
            stat("LIVES",String(lives),x:55,y:size.height*0.77,width:92)
            stat("MULT","×\(scoreMultiplier)",x:55,y:size.height*0.62,width:92)
            stat("BEST",bestScore.formatted(),x:585,y:size.height*0.92,width:92)
            stat("SCORE",score.formatted(),x:585,y:size.height*0.77,width:92)
            for (i,power) in activePowerups.enumerated() {stat("POWER",power,x:585,y:size.height*0.60-CGFloat(i)*45,width:92)}
        } else if !nativeSidebar {
            let rows=[("STAGE",String(stageIndex+1)),("SCORE",score.formatted()),("BEST",bestScore.formatted()),("LIVES",String(lives)),("MULT","×\(scoreMultiplier)")]
            for (i,row) in rows.enumerated() {stat(row.0,row.1,x:475,y:size.height-45-CGFloat(i)*65,width:90)}
        }

        if geometry.classic {
            for (i,token) in multiplierTokens.enumerated() {
                let id=edition == .bb3 ? (token.value==2 ? 20:21):(token.value==2 ? 10:11)
                let icon=SKSpriteNode(texture:OriginalArt.drop(id));icon.size=CGSize(width:26,height:26);icon.name="round-token";icon.yScale=roundYScale
                let x:CGFloat=edition == .bb3 ? 26:25
                let tokenY:CGFloat=(edition == .bb3 ? 185:235)-CGFloat(i)*26
                let y=tokenY*self.size.height/480
                icon.position=CGPoint(x:x,y:y);root.addChild(icon)
                label("\(Int(ceil(token.seconds)))s",x+18,tokenY,13)
            }
        }

    }
    func start(index:Int,resume:SavedRun?=nil,keepRun:Bool=false) {
        guard loaded, campaign.indices.contains(index) else { return }
        removeAllChildren(); removeAllActions(); stageIndex=index; bricks=[]; balls=[]; drops=[]; hits=resume?.hits ?? [:]; thirdTime=0; thirdTimers=[:];secretFound=false;hiddenReturnStage=resume?.returnStage;laserClock=0;targetPaddleX=nil;enemyGenerationClock=0
        if let resume=resume { score=max(0,resume.score); lives=min(99,max(1,resume.lives)) } else if !keepRun { score=0; lives=3 }
        launched=false; finished=false; cleared=false; lastTime=0; bigBall=false; explosiveBall=false; multiplierTokens=resume?.tokens ?? []; multiplier=multiplierTokens.isEmpty ? 1:multiplierTokens.reduce(0){$0+$1.value}; critters=[]; portNodes=[]; portIndex=nil; paddleWidth=66*geometry.unit; ballSpeed=edition == .bb3 ? thirdBaseSpeed:285*geometry.unit; setPaused(false); makeChrome()
        if !testing { GameAudio.shared.setStage(index,boss:edition == .bb3 && (campaign[index].sourceSettings?["BossIndex"] ?? "0") != "0") }; sound("start")
        for cell in campaign[index].cells where cell.art != nil || cell.type != 0 {
            let remaining=hits[cell.key] ?? (cell.hits ?? (cell.type == 7 ? 2:1))
            guard remaining > 0 || (cell.art != nil ? (cell.hits ?? 1)<=0:cell.type == 8) else { continue }
            let r=geometry.brickRect(cell)
            let n=shape(r,.clear,corner:0)
            originalSurface(n,texture:cell.art.flatMap { OriginalArt.third($0) } ?? OriginalArt.brick(cell.type),size:cell.art != nil ? r.size:CGSize(width:30*geometry.unit,height:15*geometry.unit))
            n.childNode(withName:"surface")?.position.x=0.5*geometry.unit
            if cell.art == nil && cell.type == 7 && remaining == 1 { damagedSurface(n) }
            if let rotation=cell.rotation { n.childNode(withName:"surface")?.zRotation = -CGFloat(rotation) * CGFloat.pi/2; n.childNode(withName:"shadow")?.zRotation = -CGFloat(rotation) * CGFloat.pi/2 }
            n.zPosition=1; addChild(n); bricks.append(LiveBrick(node:n,rect:r,raw:cell,hits:remaining))
        }
        paddle=shape(CGRect(x:geometry.center-paddleWidth/2,y:paddleY-5*geometry.unit,width:paddleWidth,height:10*geometry.unit),.clear,corner:0)
        if let texture=OriginalArt.paddle() {
            let originalSize=texture.size()
            originalSurface(paddle,texture:texture,size:CGSize(width:paddleWidth,height:paddleWidth*originalSize.height/originalSize.width))
        }
        paddle.zPosition=5; addChild(paddle); addBall(at:CGPoint(x:geometry.center,y:paddleY+13*geometry.unit),velocity:.zero)
        prompt.fontSize=16; prompt.fontColor = .white; prompt.position=CGPoint(x:geometry.center,y:paddleY+65*geometry.unit); prompt.zPosition=10; prompt.text=resume == nil ? "Release to launch" : "Saved stage • release to resume"; addChild(prompt)
        effectLabel.fontSize=12; effectLabel.position=CGPoint(x:geometry.center,y:paddleY+35*geometry.unit); effectLabel.fontColor = .cyan; effectLabel.zPosition=10; effectLabel.text=""; addChild(effectLabel)
        boss=edition == .bb3 ? BB3BossEncounter(settings:campaign[stageIndex].sourceSettings ?? [:],geometry:geometry,savedHealth:hits["__boss"]):nil
        if let boss=boss {addChild(boss.root)}
        checkClear(); updateHUD(); save()
    }
    func addBall(at p:CGPoint,velocity:CGVector) {
        let n=SKShapeNode(circleOfRadius:radius); n.position=p; n.zPosition=6
        originalSurface(n,texture:OriginalArt.ball(),size:CGSize(width:radius*2,height:radius*2));n.childNode(withName:"surface")?.yScale=roundYScale;n.childNode(withName:"shadow")?.yScale=roundYScale
        addChild(n); balls.append(LiveBall(node:n,velocity:velocity))
    }
    func setPaused(_ paused:Bool) { frozen=paused; onPause?(paused); if !testing { GameAudio.shared.setPaused(paused) }; if paused { save() } }
    func save() {
        guard loaded,!testing else { return }
        if let d=try? JSONEncoder().encode(SavedRun(stage:stageIndex,score:score,lives:lives,hits:hits,multiplier:multiplier,returnStage:hiddenReturnStage,tokens:multiplierTokens)) { UserDefaults.standard.set(d,forKey:saveKey) }
    }
    var bestScore:Int { max(score,UserDefaults.standard.integer(forKey:"wireproof.bb2.highscore.\(edition.rawValue)")) }
    var thirdBaseSpeed:CGFloat { CGFloat(Double(campaign[stageIndex].sourceSettings?["BallInitSpeed"] ?? "25") ?? 25)*10*geometry.unit }
    var activePowerups:[String] {
        var names:[String]=[]
        if balls.count > 1 { names.append("MULTIBALL") }
        let width=paddleWidth/max(0.01,geometry.unit), speed=ballSpeed/max(0.01,geometry.unit)
        if bigBall { names.append("BIG BALL") }; if explosiveBall { names.append("EXPLOSIVE") }
        if width > 70 { names.append("GROW") } else if width < 60 { names.append("MINI") }
        if speed < 250 { names.append("SLOW") } else if speed > 320 { names.append("FAST") }
        if edition == .bb3 {for id in thirdTimers.keys.sorted() where id>=25 {if let name=powerups[id]?.0 {names.append(name)}}}
        return names
    }
    // Native BB2 multipliers sum up to five timed tokens; empty means 1x.
    var scoreMultiplier:Int { multiplier }
    var railReadout:String {
        String(format:"STAGE\n%03d\nSCORE\n%07d\nHIGH\n%07d\nLIVES  %02d\nMULT  ×%d\nPOWER\n",stageIndex+1,score,bestScore,lives,scoreMultiplier)+(activePowerups.isEmpty ? "—":activePowerups.joined(separator:"\n"))
    }
    func updateHUD() {
        if !testing { UserDefaults.standard.set(bestScore,forKey:"wireproof.bb2.highscore.\(edition.rawValue)") }
        updateReadouts(); onStatus?(railReadout)
    }
    func movePaddle(fraction:CGFloat) {
        guard !frozen,!finished else { return }
        if edition == .bb3 && thirdTimers[28] != nil {targetPaddleX=geometry.left+fraction*(geometry.right-geometry.left);return}
        paddle.position.x=min(geometry.right-paddleWidth/2,max(geometry.left+paddleWidth/2,geometry.left+fraction*(geometry.right-geometry.left)))
        if !launched { for b in balls { b.node.position=CGPoint(x:paddle.position.x,y:paddleY+13*geometry.unit) } }
    }
    func launchOrContinue() {
        guard !frozen,loaded else { return }
        if cleared && edition == .bb3 {
            if let returnIndex=hiddenReturnStage {hiddenReturnStage=nil;start(index:returnIndex,keepRun:true);return}
            if secretFound,let hidden=campaign.indices.filter({campaign[$0].hidden == true}).randomElement() {let next=min(stageIndex+1,99);start(index:hidden,keepRun:true);hiddenReturnStage=next;save();return}
            if stageIndex+1<campaign.count && campaign[stageIndex+1].hidden != true {start(index:stageIndex+1,keepRun:true)} else {start(index:0)}
            return
        }
        if edition == .bb3 && launched {for b in balls where b.velocity.dx==0 && b.velocity.dy==0 {b.velocity=CGVector(dx:ballSpeed*0.25,dy:ballSpeed*0.9682458)};return}
        if cleared { if stageIndex+1 < campaign.count { start(index:stageIndex+1,keepRun:true) } else { start(index:0) }; return }
        guard !finished,!launched else { return }; launched=true; prompt.text=""; sound("launch")
        for b in balls { b.velocity=CGVector(dx:ballSpeed*0.25,dy:ballSpeed*0.9682458) }
    }
    func move(_ touches:Set<UITouch>) { if let t=touches.first { movePaddle(fraction:(t.location(in:self).x-geometry.left)/(geometry.right-geometry.left)) } }
    override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?) { move(touches) }
    override func touchesMoved(_ touches:Set<UITouch>,with event:UIEvent?) { move(touches) }
    override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?) { launchOrContinue() }
    override func update(_ time:TimeInterval) {
        let dt=lastTime == 0 ? 0:min(time-lastTime,0.05); lastTime=time
        guard !frozen,!finished else { return }
        animationTime += dt
        animateOriginalSprites()
        guard launched else { return }
        let steps=max(1,Int(ceil(dt*240))); for _ in 0..<steps { advance(CGFloat(dt)/CGFloat(steps)); if !launched || finished { break } }
    }
    // Atlas frames are original. Brick/drop cadence is an adaptation pending runtime timing verification.
    func animateOriginalSprites() {
        let tick=Int(animationTime/0.075)
        guard tick != animationTick else { return }; animationTick=tick
        for brick in bricks where brick.raw.art == nil {
            let type=brick.raw.type == 7 && brick.hits == 1 ? 9:brick.raw.type
            let frame=0 // Later atlas rows include damage states, not a universal idle loop.
            (brick.node.childNode(withName:"surface") as? SKSpriteNode)?.texture=OriginalArt.brick(type,frame:frame < 17 ? frame:0)
        }
        (paddle.childNode(withName:"surface") as? SKSpriteNode)?.texture=OriginalArt.paddle(frame:Int(animationTime/0.1)%8)
        for drop in drops { (drop.node.childNode(withName:"surface") as? SKSpriteNode)?.texture=OriginalArt.drop(drop.kind,frame:tick%16) }
        for node in [paddle] + drops.map({$0.node}) {
            (node.childNode(withName:"shadow") as? SKSpriteNode)?.texture=(node.childNode(withName:"surface") as? SKSpriteNode)?.texture
        }
    }
    func advance(_ dt:CGFloat) {
        guard !frozen,launched,!finished else { return }
        if !multiplierTokens.isEmpty {
            for i in multiplierTokens.indices { multiplierTokens[i].seconds -= Double(dt) }
            multiplierTokens.removeAll{$0.seconds<=0}
            let next=multiplierTokens.isEmpty ? 1:multiplierTokens.reduce(0){$0+$1.value}
            if next != multiplier || Int(animationTime*2) != Int((animationTime-Double(dt))*2) { multiplier=next;updateHUD() }
        }
        advancePorts(dt)
        if edition == .bb3 {advanceThird(dt)}
        for b in balls {
            if edition == .bb3 {applyThirdGravity(b,dt:dt)}
            let old=b.node.position; b.node.position.x += b.velocity.dx*dt; b.node.position.y += b.velocity.dy*dt
            if b.node.position.x < geometry.left+radius { b.node.position.x=geometry.left+radius; b.velocity.dx=abs(b.velocity.dx); sound("wall") }
            if b.node.position.x > geometry.right-radius { b.node.position.x=geometry.right-radius; b.velocity.dx = -abs(b.velocity.dx); sound("wall") }
            if b.node.position.y > geometry.ceiling-radius { b.node.position.y=geometry.ceiling-radius; b.velocity.dy = -abs(b.velocity.dy); sound("wall") }
            let top=paddleY+5*geometry.unit+radius
            if b.velocity.dy < 0,old.y >= top,b.node.position.y <= top,abs(b.node.position.x-paddle.position.x) < paddleWidth/2+radius {
                b.node.position.y=top; sound("paddle"); let aim=max(-0.95,min(0.95,(b.node.position.x-paddle.position.x)/(paddleWidth/2+radius)))
                b.velocity.dx=aim*ballSpeed*0.85; b.velocity.dy=sqrt(max(1,ballSpeed*ballSpeed-b.velocity.dx*b.velocity.dx))
                if edition == .bb3 && thirdTimers[36] != nil {b.velocity = .zero}
                if edition == .bb3 && thirdTimers[27] != nil && balls.count<16 {addBall(at:b.node.position,velocity:CGVector(dx:-b.velocity.dx,dy:b.velocity.dy))}
            }
            if let brick=bricks.first(where:{thirdBrickSolid($0) && contactNormal($0,at:b.node.position) != nil}) {
                let e=brick.rect.insetBy(dx:-radius,dy:-radius)
                if brick.raw.shape == "triangle",let normal=contactNormal(brick,at:b.node.position) {
                    let dot=b.velocity.dx*normal.dx+b.velocity.dy*normal.dy
                    if dot<0 {b.velocity.dx -= 2*dot*normal.dx;b.velocity.dy -= 2*dot*normal.dy}
                } else if old.y <= e.minY || old.y >= e.maxY { b.velocity.dy *= -1 } else { b.velocity.dx *= -1 }
                let pierce=edition == .bb3 && (thirdTimers[31] != nil || thirdTimers[32] != nil) && brick.breakable
                if pierce {b.velocity=CGVector(dx:(b.node.position.x-old.x)/max(dt,0.001),dy:(b.node.position.y-old.y)/max(dt,0.001))} else {b.node.position=old}
                let hard=brick.raw.special == "HARDSIDE" && old.y>brick.rect.midY
                if !hard {hit(brick)} else {sound("metal")}
                if explosiveBall { for nearby in Array(bricks) where hypot(nearby.rect.midX-brick.rect.midX,nearby.rect.midY-brick.rect.midY)<55*geometry.unit { hit(nearby) } }
            }
            if let critter=critters.first(where:{hypot($0.node.position.x-b.node.position.x,$0.node.position.y-b.node.position.y)<radius+12*geometry.unit}) {
                b.velocity.dy *= -1;critter.node.removeFromParent();critters.removeAll{$0 === critter};score += critter.scoreValue*scoreMultiplier;impact(at:critter.node.position);sound("enemy");updateHUD()
            }
            if let boss=boss {
                let result=boss.collide(b,radius:radius)
                if result.collided {hits["__boss"]=boss.health;score += result.points*scoreMultiplier;checkClear();updateHUD();save()}
            }
            b.trailClock += dt
            if b.trailClock > 0.009 { b.trailClock=0; let trail=SKShapeNode(circleOfRadius:3.2*geometry.unit); trail.position=b.node.position; trail.fillColor = .cyan; trail.strokeColor = .clear; trail.alpha=0.65; trail.zPosition=3; addChild(trail); trail.run(.sequence([.group([.fadeOut(withDuration:0.22),.scale(to:0.1,duration:0.22)]),.removeFromParent()])) }
        }
        let lost=balls.filter{$0.node.position.y < 0}; for b in lost { b.node.removeFromParent() }; balls.removeAll{$0.node.position.y < 0}
        if balls.isEmpty && !finished { loseLife() } else if !lost.isEmpty { updateHUD() }
        for d in drops { d.node.position.y -= 95*geometry.unit*dt
            if abs(d.node.position.y-paddleY)<10*geometry.unit && abs(d.node.position.x-paddle.position.x)<paddleWidth/2+10*geometry.unit { applyPowerup(d.kind); d.node.removeFromParent() }
            else if d.node.position.y < 0 { d.node.removeFromParent() }
        }; drops.removeAll{$0.node.parent == nil}
    }
    func thirdBrickSolid(_ brick:LiveBrick)->Bool {
        if edition != .bb3 {return true}
        if brick.raw.special == "PHANTOM" {return Int(thirdTime/3.5)%2==0}
        if brick.raw.special == "SECRET" {return thirdTime.truncatingRemainder(dividingBy:17)<5}
        return true
    }
    func thirdBrickDestroyed(_ brick:LiveBrick) {
        switch brick.raw.special {
        case "EXPLOSIVE","NUKE","CHAIN","PLAGUE":
            let cells:CGFloat=brick.raw.special == "NUKE" ? 10:(brick.raw.special == "CHAIN" ? 2.5:5)
            let range=cells*16*geometry.unit
            for other in Array(bricks) where other.breakable && hypot(other.rect.midX-brick.rect.midX,other.rect.midY-brick.rect.midY)<=range {hit(other)}
        case "SPEEDUP":setSpeed(thirdBaseSpeed*1.4);thirdTimers[15]=3
        case "BLASTERBALL":applyPowerup(31)
        case "EXTRABALL":applyPowerup(1)
        case "SECRET":secretFound=true;effectLabel.text="SECRET STAGE FOUND";sound("secret")
        default:break
        }
    }
    func applyThirdGravity(_ ball:LiveBall,dt:CGFloat) {
        guard ball.velocity != .zero else {ball.node.position=CGPoint(x:paddle.position.x,y:paddleY+13*geometry.unit);return}
        for brick in bricks where brick.raw.special == "GRAVITY" {
            let dx=brick.rect.midX-ball.node.position.x,dy=brick.rect.midY-ball.node.position.y,d=hypot(dx,dy)
            let range=CGFloat(Double(brick.raw.specialSettings?["GravityRadius"] ?? "10") ?? 10)*16*geometry.unit
            if d>4 && d<range {
                let sign:CGFloat=brick.raw.specialSettings?["GravityBehavior"] == "ALWAYS_REPEL" ? -1:1
                let force=CGFloat(Double(brick.raw.specialSettings?["GravityForce"] ?? "3000") ?? 3000)*geometry.unit
                ball.velocity.dx += sign*dx/d*force*dt*(1-d/range);ball.velocity.dy += sign*dy/d*force*dt*(1-d/range)
                let length=max(1,hypot(ball.velocity.dx,ball.velocity.dy));ball.velocity.dx=ball.velocity.dx/length*ballSpeed;ball.velocity.dy=ball.velocity.dy/length*ballSpeed
            }
        }
    }
    func advanceThird(_ dt:CGFloat) {
        thirdTime += dt;laserClock += dt
        var expired:[Int]=[]
        for id in thirdTimers.keys {thirdTimers[id,default:0] -= dt;if thirdTimers[id,default:0]<=0 {expired.append(id)}}
        for id in expired {
            thirdTimers.removeValue(forKey:id)
            if id==3 || id==15 {setSpeed(thirdBaseSpeed)}
            if id==22 {bigBall=false;for b in balls {b.node.childNode(withName:"surface")?.yScale=1; (b.node.childNode(withName:"surface") as? SKSpriteNode)?.size=CGSize(width:radius*2,height:radius*2)}}
            if id==23 {explosiveBall=false}
            if id==28 {targetPaddleX=nil}
        }
        if !expired.isEmpty {updateHUD()}
        if let target=targetPaddleX,thirdTimers[28] != nil {paddle.position.x += (target-paddle.position.x)*min(1,dt*5);paddle.position.x=min(geometry.right-paddleWidth/2,max(geometry.left+paddleWidth/2,paddle.position.x))}
        let hover:CGFloat=thirdTimers[33] != nil ? 35*geometry.unit:0
        paddle.position.y=paddleY+hover
        for brick in bricks where brick.raw.special == "PHANTOM" || brick.raw.special == "SECRET" {brick.node.alpha=thirdBrickSolid(brick) ? 1:0.12}
        if let boss=boss,boss.advance(dt,geometry:geometry,paddleX:paddle.position.x,paddleWidth:paddleWidth) {balls.forEach{$0.node.removeFromParent()};balls=[];boss.resetProjectiles();loseLife();return}
        if laserClock>=0.45 && (thirdTimers[29] != nil || thirdTimers[30] != nil) {
            laserClock=0
            if thirdTimers[30] != nil {for critter in critters {score += critter.scoreValue*scoreMultiplier;impact(at:critter.node.position);critter.node.removeFromParent()};critters=[];updateHUD()}
            for x in [paddle.position.x-paddleWidth*0.35,paddle.position.x+paddleWidth*0.35] {
                let targets=bricks.filter{$0.breakable && $0.rect.minX<=x && $0.rect.maxX>=x && thirdBrickSolid($0)}.sorted{$0.rect.minY<$1.rect.minY}
                let end=targets.first?.rect.minY ?? geometry.ceiling
                let path=CGMutablePath();path.move(to:CGPoint(x:x,y:paddle.position.y+8));path.addLine(to:CGPoint(x:x,y:end));let beam=SKShapeNode(path:path);beam.strokeColor = .cyan;beam.lineWidth=2*geometry.unit;beam.zPosition=8;addChild(beam);beam.run(.sequence([.fadeOut(withDuration:0.15),.removeFromParent()]))
                if let target=targets.first {hit(target)}
            }
        }
        childNode(withName:"third-effects")?.removeFromParent();let effects=SKNode();effects.name="third-effects";effects.zPosition=4;addChild(effects)
        if thirdTimers[38] != nil {let shade=SKSpriteNode(color:.black,size:size);shade.position=CGPoint(x:size.width/2,y:size.height/2);shade.alpha=0.65;effects.addChild(shade)}
        if thirdTimers[26] != nil,let b=balls.first {for i in 1...10 {let dot=SKShapeNode(circleOfRadius:1.5*geometry.unit);dot.position=CGPoint(x:b.node.position.x+b.velocity.dx*CGFloat(i)*0.06,y:b.node.position.y+b.velocity.dy*CGFloat(i)*0.06);dot.fillColor = .cyan;dot.strokeColor = .clear;effects.addChild(dot)}}
        if thirdTimers[34] != nil || thirdTimers[35] != nil {
            for offset:CGFloat in [-85,85] {let x=min(geometry.right-paddleWidth/2,max(geometry.left+paddleWidth/2,paddle.position.x+offset*geometry.unit));let ghost=SKSpriteNode(texture:OriginalArt.paddle());ghost.size=CGSize(width:paddleWidth,height:14*geometry.unit);ghost.position=CGPoint(x:x,y:paddleY);ghost.alpha=thirdTimers[35] != nil ? 0.4:1;effects.addChild(ghost)
                for b in balls where b.velocity.dy<0 && abs(b.node.position.y-paddleY)<12*geometry.unit && abs(b.node.position.x-x)<paddleWidth/2 {b.velocity.dy=abs(b.velocity.dy);b.node.position.y=paddleY+13*geometry.unit}
            }
        }
        if thirdTimers[37] != nil {let bar=SKSpriteNode(color:.cyan,size:CGSize(width:geometry.right-geometry.left,height:2));bar.position=CGPoint(x:geometry.center,y:geometry.artworkExtension+3);effects.addChild(bar);for b in balls where b.velocity.dy<0 && b.node.position.y<geometry.artworkExtension+8 {b.node.position.y=geometry.artworkExtension+8;b.velocity.dy=abs(b.velocity.dy)}}
        if hover>0 {for b in balls where b.velocity.dy<0 && abs(b.node.position.y-paddle.position.y)<10*geometry.unit && abs(b.node.position.x-paddle.position.x)<paddleWidth/2 {b.node.position.y=paddle.position.y+12*geometry.unit;b.velocity.dy=abs(b.velocity.dy)}}
    }
    func contactNormal(_ brick:LiveBrick,at point:CGPoint)->CGVector? {
        guard brick.rect.insetBy(dx:-radius,dy:-radius).contains(point) else {return nil}
        guard brick.raw.shape == "triangle",let polygon=brick.raw.polygon,let w=brick.raw.width,let h=brick.raw.height else { return CGVector(dx:0,dy:1) }
        let angle = -CGFloat(brick.raw.rotation ?? 0)*CGFloat.pi/2
        let points=polygon.map { v -> CGPoint in
            let x=(v[0]/w-0.5)*brick.rect.width,y=(0.5-v[1]/h)*brick.rect.height
            return CGPoint(x:brick.rect.midX+x*cos(angle)-y*sin(angle),y:brick.rect.midY+x*sin(angle)+y*cos(angle))
        }
        var closest=CGPoint.zero,distance=CGFloat.infinity,inside=true,sign:CGFloat=0
        for i in points.indices {
            let a=points[i],b=points[(i+1)%points.count],dx=b.x-a.x,dy=b.y-a.y
            let cross=dx*(point.y-a.y)-dy*(point.x-a.x)
            if abs(cross)>0.0001 { if sign==0 {sign=cross} else if cross*sign<0 {inside=false} }
            let t=max(0,min(1,((point.x-a.x)*dx+(point.y-a.y)*dy)/max(0.001,dx*dx+dy*dy)))
            let q=CGPoint(x:a.x+t*dx,y:a.y+t*dy),d=hypot(point.x-q.x,point.y-q.y)
            if d<distance {distance=d;closest=q}
        }
        guard inside || distance<=radius else {return nil}
        let direction:CGFloat=inside ? -1:1
        if distance<0.0001 {return CGVector(dx:0,dy:1)}
        return CGVector(dx:(point.x-closest.x)/distance*direction,dy:(point.y-closest.y)/distance*direction)
    }
    func setupPorts() {
        portNodes.forEach{$0.removeFromParent()};portNodes=[];portIndex=nil;portClock=0
        let scale=(geometry.right-geometry.left)/(edition == .bb3 ? 480:390)
        let fractions:[CGFloat]=edition == .bb3 ? [0.23,0.77]:[(202-125)/390,(436-125)/390]
        for fraction in fractions {
            let node=SKSpriteNode(texture:edition == .bb3 ? nil:OriginalArt.door(0));if edition == .bb3 {node.color = .clear}
            node.size=CGSize(width:67*scale,height:23*scale)
            node.position=CGPoint(x:geometry.left+fraction*(geometry.right-geometry.left),y:size.height-12*scale);node.zPosition=12;addChild(node);portNodes.append(node)
            if edition == .bb3 {
                let opening=SKSpriteNode(color:UIColor(white:0.015,alpha:1),size:CGSize(width:57*scale,height:15*scale));opening.name="opening";opening.zPosition = -1;node.addChild(opening)
                for (name,frame,x,flip) in [("left",2,CGFloat(-12),false),("right",0,CGFloat(12),true),("capLeft",3,CGFloat(-34),false),("capRight",3,CGFloat(34),true)] {
                    if let texture=OriginalArt.third("door_panel_\(frame)") {
                        let panel=SKSpriteNode(texture:texture);panel.name=name;panel.size=CGSize(width:50*scale,height:50*scale);panel.position.x=x*scale;panel.zPosition=name.hasPrefix("cap") ? 2:1;if flip {panel.xScale = -1};node.addChild(panel)
                    }
                }
            }
        }
    }
    func spawnCritter(_ kind:Int,port:Int) {
        guard portNodes.indices.contains(port) else {return}
        let spec=edition == .bb3 && OriginalEnemySpec.all.indices.contains(kind) ? OriginalEnemySpec.all[kind]:nil
        let texture=edition == .bb3 ? nil:OriginalArt.critter(kind,frame:0)
        guard edition == .bb3 ? spec != nil:texture != nil else {return}
        let node=SKSpriteNode(texture:texture);if edition == .bb3 {node.color = .clear};node.size=CGSize(width:32*geometry.unit,height:32*geometry.unit)
        node.yScale=roundYScale;node.position=CGPoint(x:portNodes[port].position.x,y:portNodes[port].position.y-1);node.zPosition=10;addChild(node)
        if let spec=spec {
            for layer in spec.layers {
                if let art=OriginalArt.third(layer.art) {
                    let child=SKSpriteNode(texture:art);child.name="enemy-layer-\(layer.slot)";child.size=CGSize(width:32*geometry.unit*CGFloat(layer.scale),height:32*geometry.unit*CGFloat(layer.scale))
                    child.zPosition=CGFloat(layer.z);child.alpha=CGFloat(layer.opacity);if layer.shadow {child.position=CGPoint(x:4*geometry.unit,y:-4*geometry.unit)}
                    node.addChild(child)
                }
            }
        }
        let critter=LiveCritter(node:node,kind:kind,velocity:CGVector(dx:0,dy:-20*geometry.unit),third:spec);critter.collisionRadius=12*geometry.unit;critters.append(critter)
    }
    func eligibleCritterKinds()->[Int] {
        if edition != .bb3 {return campaign[stageIndex].critterSpawns.filter{[0,1,2,4,5].contains($0)}}
        let data=campaign[stageIndex].sourceSettings?["EnemiesData"] ?? ""
        var values:[Int]=[]
        for entry in data.components(separatedBy:"#:") {
            let fields=entry.split(separator:",").map(String.init)
            if let name=fields.first,let i=OriginalEnemySpec.all.firstIndex(where:{$0.name==name}) { values += Array(repeating:i,count:min(10,max(1,fields.count>1 ? Int(fields[1]) ?? 1:1))) }
        }
        return values
    }
    func advancePorts(_ dt:CGFloat) {
        guard portNodes.count==2 else {return}
        let allowed=eligibleCritterKinds()
        let maximum=edition == .bb3 ? Int(campaign[stageIndex].sourceSettings?["EnemiesOnScreen"] ?? "3") ?? 3:campaign[stageIndex].critterSpawns.count
        if let port=portIndex {
            portClock += dt
            let frame=portClock<0.4 ? min(7,Int(portClock/0.05)):(portClock<1.4 ? 7:max(0,7-Int((portClock-1.4)/0.05)))
            if edition == .bb3 {
                let scale=(geometry.right-geometry.left)/480
                let progress=min(1,max(0,portClock<0.4 ? portClock/0.4:(portClock<1.4 ? 1:1-(portClock-1.4)/0.4)))
                portNodes[port].childNode(withName:"left")?.position.x=(-12-20*progress)*scale
                portNodes[port].childNode(withName:"right")?.position.x=(12+20*progress)*scale
            } else {portNodes[port].texture=OriginalArt.door(frame)}
            if portClock>=0.4 && !portDidSpawn {portDidSpawn=true;if let kind=allowed.randomElement(){spawnCritter(kind,port:port)}}
            if portClock>=1.8 {portIndex=nil;if edition != .bb3 {portNodes[port].texture=OriginalArt.door(0)}}
        } else if !allowed.isEmpty && critters.count<maximum {
            let shouldOpen:Bool
            if edition == .bb3 {
                enemyGenerationClock += dt
                let interval=CGFloat(Double(campaign[stageIndex].sourceSettings?["EnemiesGenerationTime"] ?? "10") ?? 10)
                shouldOpen=enemyGenerationClock>=max(1,interval)
            } else {shouldOpen = !testing && Double.random(in:0..<1)<1-pow(1-0.0005,Double(dt)*60)}
            if shouldOpen {portIndex=Int.random(in:0...1);portClock=0;portDidSpawn=false;enemyGenerationClock=0}
        }
        for critter in critters {
            critter.age += dt
            if critter.node.position.y<size.height-30*geometry.unit && !critter.emerged {
                critter.emerged=true
                let speed:CGFloat=critter.third.map{CGFloat($0.speed)*10} ?? ([0:30,1:80,2:50,4:60,5:20][critter.kind] ?? 30)
                critter.velocity=CGVector(dx:(critter.kind == 5 && edition != .bb3 ? 0:(Bool.random() ? 1:-1)*speed*0.707*geometry.unit),dy:-speed*0.707*geometry.unit)
            }
            critter.node.position.x += critter.velocity.dx*dt;critter.node.position.y += critter.velocity.dy*dt
            if critter.node.position.x<geometry.left+16*geometry.unit {critter.node.position.x=geometry.left+16*geometry.unit;critter.velocity.dx=abs(critter.velocity.dx)}
            if critter.node.position.x>geometry.right-16*geometry.unit {critter.node.position.x=geometry.right-16*geometry.unit;critter.velocity.dx = -abs(critter.velocity.dx)}
            if let spec=critter.third {
                for layer in spec.layers {critter.node.childNode(withName:"enemy-layer-\(layer.slot)")?.zRotation=CGFloat(layer.rotationDegrees)*CGFloat.pi/180*critter.age}
            } else {critter.node.texture=OriginalArt.critter(critter.kind,frame:Int(critter.age/0.05)%16)}
            if critter.node.position.y < -20 || (abs(critter.node.position.y-paddleY)<16*geometry.unit && abs(critter.node.position.x-paddle.position.x)<paddleWidth/2+12*geometry.unit) {critter.node.removeFromParent()}
        }
        critters.removeAll{$0.node.parent == nil}
    }
    func previewPorts() {
        // Simulator inspection hook: deterministic entrances, no physical-device launch path.
        #if targetEnvironment(simulator)
        testing=true;setPaused(false);launched=true;prompt.text=""
        balls.forEach{$0.velocity = .zero};setupPorts();portIndex=0;portClock=0;portDidSpawn=false
        run(.sequence([.wait(forDuration:2.2),.run { [weak self] in
            guard let self=self else {return};self.portIndex=1;self.portClock=0;self.portDidSpawn=false
        }]))
        #endif
    }
    func circleSmokeChecks()->[String:Bool] {
        if viewportSize.width<=0 || viewportSize.height<=0 {configureViewport(viewSize:CGSize(width:1024,height:768),safeInsets:.zero,classic:true)}
        let kind=edition == .bb3 ? 20:10
        spawnDrop(kind,at:CGPoint(x:geometry.center,y:paddleY+80))
        fitRoundSprites()
        var passed=false
        if let sprite=drops.last?.node.childNode(withName:"surface") as? SKSpriteNode {
            let w=sprite.size.width*viewportSize.width/size.width
            let h=sprite.size.height*viewportSize.height/size.height
            passed=abs(w-h)<0.01
            let debug="w=\(w) h=\(h) sprite=\(sprite.size) scale=\(sprite.yScale) ratio=\(roundYScale) viewport=\(viewportSize) scene=\(size)"
            if let dir=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first {try? debug.write(to:dir.appendingPathComponent("circle-debug.txt"),atomically:true,encoding:.utf8)}
        }
        drops.last?.node.removeFromParent();if !drops.isEmpty {drops.removeLast()}
        return ["powerup_round_in_screen_pixels":passed]
    }
    func celebrationSmokeChecks()->[String:Bool] {
        showCelebration(campaignComplete:true)
        let active=childNode(withName:"celebration")?.hasActions() == true
        childNode(withName:"celebration")?.removeFromParent()
        let ids=edition == .bb3 ? [20,21]:[10,11]
        return ["completion_animation_scheduled":active,"multiplier_icons_available":ids.allSatisfy{OriginalArt.drop($0) != nil}]
    }
    func portSmokeChecks()->[String:Bool] {
        var checks:[String:Bool]=[:]
        setupPorts();critters.forEach{$0.node.removeFromParent()};critters=[]
        checks["ports_have_eligible_enemies"] = !eligibleCritterKinds().isEmpty
        checks["two_port_nodes"]=portNodes.count==2
        for port in 0..<2 {
            portIndex=port;portClock=0;portDidSpawn=false
            advancePorts(0.2)
            if edition == .bb3 {checks["port_\(port)_panels_open"]=(portNodes[port].childNode(withName:"left")?.position.x ?? 0)<(-12*(geometry.right-geometry.left)/480)}
            advancePorts(0.21)
            checks["port_\(port)_spawn_after_open"]=critters.count==port+1 && abs((critters.last?.node.position.x ?? -999)-portNodes[port].position.x)<1
            checks["port_\(port)_spawn_at_top"]=(critters.last?.node.position.y ?? 0)>geometry.ceiling-5*geometry.unit
            advancePorts(1.4)
            checks["port_\(port)_closes"]=portIndex==nil
            if edition == .bb3 {checks["port_\(port)_panels_closed"]=abs((portNodes[port].childNode(withName:"left")?.position.x ?? 999)+12*(geometry.right-geometry.left)/480)<0.01}
            else {checks["port_\(port)_closed_art"]=portNodes[port].texture === OriginalArt.door(0)}
        }
        checks["enemy_art_visible"]=critters.allSatisfy{$0.third == nil ? $0.node.texture != nil: !$0.node.children.isEmpty}
        critters.forEach{$0.node.removeFromParent()};critters=[];enemyGenerationClock=0;setupPorts()
        return checks
    }
    func impact(at position:CGPoint) {
        guard !testing else { return }
        for i in 0..<6 {
            let spark=SKShapeNode(circleOfRadius:1.4*geometry.unit); spark.position=position
            spark.fillColor = .white; spark.strokeColor = .cyan; spark.glowWidth=1; spark.zPosition=8; addChild(spark)
            let angle=CGFloat(i)*CGFloat.pi/3
            spark.run(.sequence([.group([.moveBy(x:cos(angle)*18*geometry.unit,y:sin(angle)*18*geometry.unit,duration:0.18),.fadeOut(withDuration:0.18)]),.removeFromParent()]))
        }
    }
    func hit(_ b:LiveBrick) {
        guard bricks.contains(where:{$0 === b}) else {return}
        impact(at:b.node.position)
        guard b.breakable else { sound("metal"); return }
        b.hits -= 1; hits[b.raw.key]=b.hits
        if b.hits > 0 { if edition != .bb3 && b.raw.type != 10 { score += 10*scoreMultiplier;updateHUD() }; sound("metal"); if b.raw.art == nil { damagedSurface(b.node) }; save(); return }
        bricks.removeAll{$0 === b}; score += (b.raw.score ?? (b.raw.type == 14 ? 250:(b.raw.type == 10 ? 0:50)))*scoreMultiplier; sound("brick")
        b.node.run(.sequence([.group([.scale(to:1.18,duration:0.1),.fadeOut(withDuration:0.1)]),.removeFromParent()]))
        let drop=edition == .bb3 ? thirdPowerup(b.raw.powerupName):b.raw.powerup
        if powerups[drop] != nil && (testing || Double.random(in:0..<100) < (b.raw.powerupProbability ?? 100)) { spawnDrop(drop,at:b.node.position) }
        if edition == .bb3 {thirdBrickDestroyed(b)}
        checkClear(); updateHUD(); save()
    }
    func thirdPowerup(_ name:String?)->Int {
        switch name?.lowercased() {
        case "multiball","split","divide","splitball":return 1
        case "slow","slowball":return 3
        case "shrink","smallpaddle":return 6
        case "grow","largepaddle","growpaddle":return 8
        case "extralife","life","1up":return 9
        case "fast","fastball":return 15
        case "scorex2":return 20
        case "scorex3":return 21
        case "bigball":return 22
        case "explosiveball":return 23
        case "flash":return 24
        case "8ball":return 25
        case "vision":return 26
        case "replicateball":return 27
        case "inertialpaddle":return 28
        case "laser":return 29
        case "zap":return 30
        case "blasterball":return 31
        case "energyball":return 32
        case "hovering":return 33
        case "twinpaddles":return 34
        case "phantompaddle":return 35
        case "attach":return 36
        case "catcher":return 37
        case "nightball":return 38
        default:return 0
        }
    }
    func spawnDrop(_ kind:Int,at p:CGPoint) {
        guard powerups[kind] != nil else { return }
        let n=shape(CGRect(x:p.x-11,y:p.y-7,width:22,height:14),.clear,corner:0); n.zPosition=7
        originalSurface(n,texture:OriginalArt.drop(kind),size:CGSize(width:24*geometry.unit,height:24*geometry.unit));n.childNode(withName:"surface")?.yScale=roundYScale;n.childNode(withName:"shadow")?.yScale=roundYScale
        addChild(n); drops.append(Drop(node:n,kind:kind))
    }
    func applyPowerup(_ kind:Int) {
        switch kind {
        case 1:
            guard let b=balls.first else { return }
            for offset:CGFloat in [-0.5,0.5] where balls.count < 6 {
                let angle=atan2(b.velocity.dy,b.velocity.dx)+offset
                addBall(at:b.node.position,velocity:CGVector(dx:cos(angle)*ballSpeed,dy:sin(angle)*ballSpeed))
            }
        case 3: setSpeed(edition == .bb3 ? thirdBaseSpeed*0.7:215*geometry.unit);if edition == .bb3 {thirdTimers[3]=6;thirdTimers.removeValue(forKey:15)}
        case 15: setSpeed(edition == .bb3 ? thirdBaseSpeed*1.25:370*geometry.unit);if edition == .bb3 {thirdTimers[15]=6;thirdTimers.removeValue(forKey:3)}
        case 6: setWidth(44)
        case 8: setWidth(94)
        case 9: lives=min(99,lives+1)
        case 10,11,20,21:
            if multiplierTokens.count<5 { multiplierTokens.append(MultiplierToken(value:(kind==10 || kind==20) ? 2:3,seconds:20)) }
            multiplier=multiplierTokens.reduce(0){$0+$1.value}
        case 22:
            bigBall=true; if edition == .bb3 {thirdTimers[22]=5}
            for ball in balls { (ball.node.childNode(withName:"surface") as? SKSpriteNode)?.size=CGSize(width:radius*2,height:radius*2) }
        case 23: explosiveBall=true;thirdTimers[23]=8
        case 24:
            for brick in Array(bricks).filter({$0.breakable}) {hit(brick)}
        case 25:
            let origin=balls.first?.node.position ?? paddle.position
            while balls.count<8 {let angle=CGFloat(balls.count)*CGFloat.pi/4;addBall(at:origin,velocity:CGVector(dx:cos(angle)*ballSpeed,dy:max(0.3,abs(sin(angle)))*ballSpeed))}
        case 26...38:
            let durations:[Int:CGFloat]=[26:15,27:30,28:8,29:15,30:15,31:10,32:10,33:15,34:15,35:15,36:15,37:15,38:15]
            if [28,29,30,33,34,35,36].contains(kind) {for id in [28,29,30,33,34,35,36] {thirdTimers.removeValue(forKey:id)}}
            thirdTimers[kind]=durations[kind] ?? 15
        default:return
        }
        if edition == .bb3 && kind>=20 && kind != 32 {sound("power\(kind)")}
        let sounds=[1:"divide",3:"slow",6:"mini",8:"grow",9:"oneup",15:"fast"]; if let event=sounds[kind] { sound(event) }
        let names=[1:"MULTIBALL",3:"SLOW BALL",6:"MINI PADDLE",8:"GROW PADDLE",9:"EXTRA LIFE",15:"FAST BALL"]
        effectLabel.removeAllActions(); effectLabel.alpha=1; effectLabel.text=nativeSidebar ? "":names[kind]; effectLabel.run(.sequence([.wait(forDuration:2),.fadeOut(withDuration:0.3)])); updateHUD(); save()
    }
    func setWidth(_ w:CGFloat) { paddleWidth=w*geometry.unit; paddle.xScale=w/66; paddle.position.x=min(geometry.right-paddleWidth/2,max(geometry.left+paddleWidth/2,paddle.position.x)) }
    func setSpeed(_ s:CGFloat) { ballSpeed=s; for b in balls { let magnitude=hypot(b.velocity.dx,b.velocity.dy); if magnitude > 0 { b.velocity.dx=b.velocity.dx/magnitude*s; b.velocity.dy=b.velocity.dy/magnitude*s } } }
    func loseLife() {
        multiplier=1; multiplierTokens=[]; bigBall=false; explosiveBall=false;thirdTimers=[:];targetPaddleX=nil;childNode(withName:"third-effects")?.removeFromParent()
        lives -= 1; launched=false; drops.forEach{$0.node.removeFromParent()}; drops=[]; setWidth(66); ballSpeed=edition == .bb3 ? thirdBaseSpeed:285*geometry.unit; sound("loss")
        if lives<=0 {run(.sequence([.wait(forDuration:0.8),.run { [weak self] in self?.sound("gameover") }]))}
        if lives <= 0 { finished=true; prompt.text="Game over • Restart or choose a stage"; prompt.fontSize=13 }
        else { addBall(at:CGPoint(x:paddle.position.x,y:paddleY+13*geometry.unit),velocity:.zero); prompt.text="Release to launch" }
        updateHUD(); save()
    }
    func checkClear() {
        guard !cleared else {return}
        if !bricks.contains(where:{$0.breakable}) && boss?.defeated != false {
            finished=true; cleared=true
            let complete=edition == .bb3 ? (stageIndex==99 && hiddenReturnStage==nil):stageIndex==campaign.count-1
            prompt.fontSize=14;prompt.text=complete ? "Campaign complete! • release to replay":"Stage clear! • release for next stage"
            showCelebration(campaignComplete:complete)
            drops.forEach{$0.node.removeFromParent()}; drops=[]
        }
    }
    // Original ball art supplies the glowing particles; choreography is a mobile adaptation.
    func showCelebration(campaignComplete:Bool) {
        childNode(withName:"celebration")?.removeFromParent()
        let root=SKNode();root.name="celebration";root.zPosition=40;addChild(root)
        let count=campaignComplete ? 12:4
        for i in 0..<count {
            root.run(.sequence([.wait(forDuration:Double(i)*0.45),.run { [weak self,weak root] in
                guard let self=self,let root=root else {return}
                let x=self.geometry.left+(self.geometry.right-self.geometry.left)*CGFloat.random(in:0.15...0.85)
                let target=CGPoint(x:x,y:self.paddleY+(self.geometry.ceiling-self.paddleY)*CGFloat.random(in:0.4...0.85))
                let rocket=SKSpriteNode(texture:OriginalArt.ball());rocket.size=CGSize(width:7,height:7);rocket.position=CGPoint(x:self.geometry.center,y:self.paddleY);root.addChild(rocket)
                self.sound("firework_launch")
                rocket.run(.sequence([.move(to:target,duration:0.45),.run { [weak self,weak root] in
                    guard let self=self,let root=root else {return};self.sound("firework_explode")
                    let color=UIColor(hue:CGFloat.random(in:0...1),saturation:0.8,brightness:1,alpha:1)
                    for j in 0..<32 {
                        let spark=SKSpriteNode(texture:OriginalArt.ball());spark.size=CGSize(width:5,height:5);spark.color=color;spark.colorBlendFactor=0.8;spark.blendMode = .add;spark.position=target;root.addChild(spark)
                        let angle=CGFloat(j)*CGFloat.pi/16, radius=CGFloat.random(in:35...90)*self.geometry.unit
                        spark.run(.sequence([.group([.moveBy(x:cos(angle)*radius,y:sin(angle)*radius-25*self.geometry.unit,duration:1.2),.fadeOut(withDuration:1.2),.scale(to:0.2,duration:1.2)]),.removeFromParent()]))
                    }
                },.removeFromParent()]))
            }]))
        }
        root.run(.sequence([.wait(forDuration:Double(count)*0.45+2),.removeFromParent()]))
    }
    func runSmokeTest() {
        if edition == .bb3 { runThirdSmokeTest(); return }
        testing=true
        var checks:[String:Bool]=["edition_loaded":loaded]
        guard loaded else { writeSmoke(checks); return }
        let original=SavedRun(stage:stageIndex,score:score,lives:lives,hits:hits,multiplier:multiplier,returnStage:hiddenReturnStage,tokens:multiplierTokens), originalViewport=viewportSize, originalInsets=viewportInsets
        let originalClassic=geometry.classic, originalArtworkInset=artworkBottomInset
        artworkBottomInset=0
        let firstCount=campaign[0].cells.filter{$0.type != 0}.count
        start(index:0);checks.merge(portSmokeChecks()){_,new in new};checks.merge(celebrationSmokeChecks()){_,new in new};checks.merge(circleSmokeChecks()){_,new in new}; checks["stage1_original_brick_count"]=bricks.count == firstCount
        var twoHitFound=false
        for index in campaign.indices {
            start(index:index)
            if let b=bricks.first(where:{$0.raw.type == 7}) {
                twoHitFound=true; hit(b); checks["two_hit_survives_first"]=bricks.contains{$0 === b} && b.hits == 1
                hit(b); checks["two_hit_removed_second"] = !bricks.contains{$0 === b}; break
            }
        }
        checks["two_hit_fixture_present"]=twoHitFound
        start(index:0); launchOrContinue(); applyPowerup(1); checks["multiball"]=balls.count == 3
        applyPowerup(8); checks["grow"]=abs(paddleWidth-94*geometry.unit)<0.01
        applyPowerup(6); checks["mini"]=abs(paddleWidth-44*geometry.unit)<0.01
        applyPowerup(3); checks["slow"]=abs(hypot(balls[0].velocity.dx,balls[0].velocity.dy)-215*geometry.unit)<0.01
        applyPowerup(15); checks["fast"]=abs(hypot(balls[0].velocity.dx,balls[0].velocity.dy)-370*geometry.unit)<0.01
        checks["rail_reports_active_powers"]=activePowerups.contains("MULTIBALL") && activePowerups.contains("MINI") && activePowerups.contains("FAST")
        checks["rail_reports_high_and_multiplier"]=railReadout.contains("HIGH") && railReadout.contains("×1")
        applyPowerup(9); checks["extra_life"]=lives == 4
        applyPowerup(10);applyPowerup(11);checks["multipliers_add"]=scoreMultiplier==5
        for _ in 0..<4 {applyPowerup(10)};checks["multiplier_cap"]=multiplierTokens.count==5
        multiplierTokens=multiplierTokens.map{MultiplierToken(value:$0.value,seconds:0.001)};advance(0.002);checks["multiplier_expiry"]=scoreMultiplier==1
        checks["two_original_ports"]=portNodes.count==2 && OriginalArt.door(7) != nil
        spawnCritter(0,port:0);spawnCritter(1,port:1)
        checks["critters_emerge_at_ports"]=critters.count==2 && zip(critters,portNodes).allSatisfy{abs($0.node.position.x-$1.position.x)<0.01 && $0.node.position.y>geometry.ceiling}
        advancePorts(0.1);checks["critters_enter_downward"]=critters.allSatisfy{$0.node.position.y<size.height-2}
        critters.forEach{$0.node.removeFromParent()};critters=[]
        let position=balls[0].node.position; setPaused(true); advance(0.02); checks["pause"]=balls[0].node.position == position; setPaused(false)
        balls[0].node.position=CGPoint(x:geometry.center,y:-20); advance(0); checks["one_multiball_loss_no_life"]=lives == 4 && balls.count == 2
        balls.forEach{$0.node.position.y = -20}; advance(0); checks["last_ball_costs_one_life"]=lives == 3 && balls.count == 1 && !launched
        var hardFound=false
        for i in campaign.indices {
            start(index:i)
            if let hard=bricks.first(where:{!$0.breakable}) {
                hardFound=true; let count=bricks.count; hit(hard); checks["hard_survives"]=bricks.count == count
                for b in bricks.filter({$0.breakable}) { while b.hits > 0 { hit(b) } }; checks["hard_excluded_clear"]=cleared; break
            }
        }
        checks["hard_fixture_present"]=hardFound
        start(index:0); for b in bricks.filter({$0.breakable}) { while b.hits > 0 { hit(b) } }; launchOrContinue(); checks["progression"]=stageIndex == 1 && !finished
        start(index:0)
        if let target=bricks.first(where:{$0.breakable}) {
            while target.hits > 0 { hit(target) }; let snapshot=SavedRun(stage:stageIndex,score:score,lives:lives,hits:hits,multiplier:multiplier,returnStage:hiddenReturnStage,tokens:multiplierTokens)
            start(index:0,resume:snapshot); checks["resume_destroyed_brick"] = !bricks.contains{$0.raw.key == target.raw.key}
        }
        start(index:0); checks["restart_resets"]=bricks.count == firstCount && lives == 3 && score == 0
        launchOrContinue(); let moving=balls[0]
        moving.node.position=CGPoint(x:geometry.left+radius+0.1,y:paddleY+30*geometry.unit); moving.velocity=CGVector(dx:-100,dy:100); advance(0.01)
        // SpriteKit stores node transforms at floating-point precision; verify the reflected direction and wall contact within 0.01 logical pixels.
        checks["wall_bounces_inward"]=moving.velocity.dx > 0 && abs(moving.node.position.x-(geometry.left+radius)) <= 0.01
        moving.node.position=CGPoint(x:paddle.position.x,y:paddleY+10*geometry.unit); moving.velocity=CGVector(dx:0,dy:-285*geometry.unit); advance(0.01)
        checks["paddle_bounces_up"]=moving.velocity.dy > 0
        if let block=bricks.filter({$0.breakable && $0.hits == 1 && $0.raw.powerup == 0}).sorted(by:{$0.raw.row > $1.raw.row}).first {
            moving.node.position=CGPoint(x:block.rect.midX,y:block.rect.minY-radius-0.5*geometry.unit); moving.velocity=CGVector(dx:0,dy:285*geometry.unit); advance(0.004)
            checks["ball_collision_breaks_brick"] = !bricks.contains{$0 === block} && moving.velocity.dy < 0
        }
        spawnDrop(8,at:CGPoint(x:paddle.position.x,y:paddleY+geometry.unit)); advance(0)
        checks["falling_drop_collected"]=abs(paddleWidth-94*geometry.unit)<0.01 && drops.isEmpty
        lives=1; balls.forEach{$0.node.position.y = -20}; advance(0); checks["game_over"]=lives == 0 && finished && !cleared
        if let t=OriginalArt.brick(7) { checks["original_brick_dimensions"]=t.size() == CGSize(width:30,height:15) }
        if let t=OriginalArt.backdrop(campaign[0].background) { checks["original_arena_crop"]=t.size() == CGSize(width:420,height:480) }
        for (key,texture) in [("paddle_mask",OriginalArt.paddle()),("ball_mask",OriginalArt.ball()),("drop_mask",OriginalArt.drop(1))] {
            if let texture=texture,let pixels=OriginalArt.rgba(texture.cgImage()) { let alphas=stride(from:3,to:pixels.count,by:4).map{pixels[$0]}; checks[key]=alphas.contains(0) && alphas.contains(255) }
        }
        start(index:0); launchOrContinue(); applyPowerup(1)
        let savedHits=hits, savedLives=lives, savedCount=bricks.count, savedBalls=balls.count
        let viewports:[(String,CGSize,UIEdgeInsets)]=[
            ("tall",CGSize(width:393,height:852),UIEdgeInsets(top:59,left:0,bottom:34,right:0)),
            ("duo",CGSize(width:879,height:1280),UIEdgeInsets(top:24,left:0,bottom:20,right:0)),
            ("landscape",CGSize(width:852,height:393),UIEdgeInsets(top:0,left:59,bottom:21,right:59))]
        for (name,viewport,insets) in viewports {
            configureViewport(viewSize:viewport,safeInsets:insets)
            checks["\(name)_grid_in_bounds"]=campaign[stageIndex].cells.allSatisfy {
                let rect=geometry.brickRect($0)
                return rect.minX >= geometry.left-0.01 && rect.maxX <= geometry.right+0.01 && rect.maxY <= geometry.ceiling+0.01 && rect.minY > paddleY+20*geometry.unit
            }
            checks["\(name)_paddle_and_balls_in_bounds"]=paddle.position.x-paddleWidth/2 >= geometry.left-0.01 && paddle.position.x+paddleWidth/2 <= geometry.right+0.01 && balls.allSatisfy{$0.node.position.x >= geometry.left+radius-0.01 && $0.node.position.x <= geometry.right-radius+0.01}
            checks["\(name)_run_preserved"]=hits == savedHits && lives == savedLives && bricks.count == savedCount && balls.count == savedBalls
            checks["\(name)_fills_window"]=geometry.classic ? size == CGSize(width:640,height:480) : size.width == (nativeSidebar ? 420:530)
        }
        checks["pc_original_backdrop"]=childNode(withName:"backdrop")?.childNode(withName:"originalPC") != nil
        checks["pc_arena_coordinates"]=geometry.left == 125 && geometry.right == 515 && geometry.ceiling == 458
        checks["pc_side_readouts"]=(childNode(withName:"readouts")?.children.count ?? 0) >= 5
        let asymmetric=BoardGeometry.make(viewSize:CGSize(width:879,height:1280),safeInsets:UIEdgeInsets(top:0,left:0,bottom:20,right:120),classic:false)
        checks["compact_right_panel_reserved"]=asymmetric.right == 405 && asymmetric.size.width == 530
        checks["animation_atlases_complete"]=(0..<17).allSatisfy{OriginalArt.brick(1,frame:$0) != nil} && (0..<8).allSatisfy{OriginalArt.paddle(frame:$0) != nil} && powerups.keys.allSatisfy{ id in (0..<16).allSatisfy{OriginalArt.drop(id,frame:$0) != nil} }
        checks["compact_arena_centered"]=abs(asymmetric.center-210)<0.01
        let bounds=CGRect(x:0,y:0,width:1280,height:900)
        let open=DisplayLayout.make(bounds:bounds,safe:.zero,closed:false)
        let closed=DisplayLayout.make(bounds:bounds,safe:.zero,closed:true)
        let cover=DisplayLayout.make(bounds:CGRect(x:0,y:0,width:393,height:852),safe:.zero,closed:true)
        checks["open_pc_fills_width"]=open.frame.width == bounds.width && open.frame.minY == bounds.minY && !open.compact
        checks["thumb_strip_below_playfield"]=open.thumb.minY == open.frame.maxY && open.thumb.maxY == bounds.maxY && open.thumb.height >= 64
        let nativeGeometry=BoardGeometry.make(viewSize:CGSize(width:720,height:1200),safeInsets:.zero,classic:false,nativeSidebar:true)
        checks["native_rail_no_duplicate_sidebar"]=nativeGeometry.size.width == 420 && nativeGeometry.right == 405
        checks["closed_uses_entire_available_window"] = !closed.compact && closed.frame.width == bounds.width && closed.frame.minX == bounds.minX
        checks["native_cover_not_split_twice"]=cover.compact && cover.frame.width == 393
        let rotatedCover=DisplayLayout.make(bounds:CGRect(x:0,y:0,width:852,height:393),safe:.zero,closed:true)
        checks["rotated_cover_not_split_twice"] = !rotatedCover.compact && rotatedCover.frame.width == 852
        let compactLandscape=BoardGeometry.make(viewSize:rotatedCover.frame.size,safeInsets:.zero,classic:false)
        checks["rotated_cover_grid_above_paddle"]=campaign.flatMap{$0.cells}.allSatisfy { compactLandscape.brickRect($0).minY > compactLandscape.paddleY+20*compactLandscape.unit }
        checks["separate_edition_saves"]=Set(GameEdition.allCases.map{$0.saveKey}).count == 4 && GameEdition.revolution.saveKey == "wireproof.blasterball.v02.run"
        checks["edition_texture_namespace"]=OriginalArt.edition == edition.rawValue
        artworkBottomInset=originalArtworkInset
        configureViewport(viewSize:originalViewport,safeInsets:originalInsets,classic:originalClassic); start(index:original.stage,resume:original)
        writeSmoke(checks); testing=false
    }
    func runThirdSmokeTest() {
        testing=true
        guard loaded else { writeSmoke(["bb3_loaded":false]); return }
        let original=SavedRun(stage:stageIndex,score:score,lives:lives,hits:hits,multiplier:multiplier,returnStage:hiddenReturnStage,tokens:multiplierTokens)
        var checks:[String:Bool]=["bb3_loaded":loaded,"bb3_distinct_save":saveKey != GameEdition.revolution.saveKey,"bb3_original_art":campaign.allSatisfy { $0.cells.allSatisfy { $0.art.flatMap { OriginalArt.third($0) } != nil } }]
        checks.merge(BB3BossEncounter.validation()){_,new in new}
        start(index:0)
        checks.merge(portSmokeChecks()){_,new in new};checks.merge(celebrationSmokeChecks()){_,new in new};checks.merge(circleSmokeChecks()){_,new in new}
        checks["full_template_inventory"]=campaign.count==110 && campaign.filter{$0.hidden==true}.count==10
        for i in campaign.indices { start(index:i); checks["stage_\(i)_bricks"]=bricks.count == campaign[i].cells.count; checks["stage_\(i)_bounds"]=bricks.allSatisfy { $0.rect.minX >= geometry.left-0.01 && $0.rect.maxX <= geometry.right+0.01 && $0.rect.minY>paddleY } }
        start(index:0)
        if let triangle=bricks.first(where:{$0.raw.shape == "triangle"}) {
            let r=triangle.rect
            let points=[CGPoint(x:r.minX+radius*2,y:r.minY+radius*2),CGPoint(x:r.maxX-radius*2,y:r.maxY-radius*2),CGPoint(x:r.minX+radius*2,y:r.maxY-radius*2),CGPoint(x:r.maxX-radius*2,y:r.minY+radius*2)]
            checks["triangle_empty_half"]=points.contains{contactNormal(triangle,at:$0)==nil}
            checks["triangle_solid_half"]=points.contains{contactNormal(triangle,at:$0) != nil}
        }
        let count=bricks.count
        if let brick=bricks.first(where:{$0.breakable}) { while brick.hits>0 { hit(brick) } }
        checks["bb3_hit_removes_brick"]=bricks.count == count-1 && score>0
        launchOrContinue(); checks["bb3_launch"]=launched && !balls.isEmpty
        let savedView=viewportSize,savedInsets=viewportInsets,savedClassic=geometry.classic
        configureViewport(viewSize:CGSize(width:1024,height:768),safeInsets:.zero,classic:true);updateReadouts()
        let stats=childNode(withName:"readouts")?.children.filter{$0.name=="panel-stat"} ?? []
        checks["bb3_panel_text_within_columns"]=stats.count==10 && stats.allSatisfy {let f=$0.calculateAccumulatedFrame();return (f.minX>=5 && f.maxX<=75) || (f.minX>=565 && f.maxX<=635)}
        configureViewport(viewSize:savedView,safeInsets:savedInsets,classic:savedClassic)
        checks["bb3_ceiling_matches_top_bar"]=abs(geometry.ceiling-(size.height-18))<0.01
        if let ball=balls.first {
            ball.node.position=CGPoint(x:geometry.left+radius+2,y:geometry.ceiling-radius-1);ball.velocity=CGVector(dx:0,dy:100)
            advance(0.02)
            checks["bb3_ball_reaches_visible_top"]=abs(ball.node.position.y-(geometry.ceiling-radius))<0.1 && ball.velocity.dy<0
        }
        applyPowerup(8); checks["bb3_grow"]=paddleWidth>66*geometry.unit
        setPaused(true);let point=balls.first?.node.position;advance(0.02);checks["bb3_pause"]=point==balls.first?.node.position;setPaused(false)
        for id in [3,15,22,23,26,27,28,29,30,31,32,33,34,35,36,37,38] {
            start(index:0);launchOrContinue();applyPowerup(id)
            checks["power_\(id)_active"]=thirdTimers[id] != nil
            if let remaining=thirdTimers[id] {thirdTimers[id]=min(remaining,0.001);advanceThird(0.002);checks["power_\(id)_expires"]=thirdTimers[id]==nil}
        }
        start(index:0);launchOrContinue();applyPowerup(25);checks["eight_ball"]=balls.count==8
        if let index=campaign.firstIndex(where:{($0.sourceSettings?["BossIndex"] ?? "0") != "0"}) {
            start(index:index);checkClear();checks["boss_blocks_clear"]=boss != nil && !cleared
        }
        if let index=campaign.firstIndex(where:{$0.cells.contains{$0.special == "GRAVITY"}}) {
            start(index:index);launchOrContinue()
            if let gravity=bricks.first(where:{$0.raw.special == "GRAVITY"}),let ball=balls.first {
                ball.node.position=CGPoint(x:gravity.rect.midX+50*geometry.unit,y:gravity.rect.midY);ball.velocity=CGVector(dx:0,dy:ballSpeed)
                applyThirdGravity(ball,dt:0.02);checks["gravity_deflects"]=abs(ball.velocity.dx)>0.01
            }
        }
        start(index:0);secretFound=true;cleared=true;launchOrContinue();checks["secret_routes_hidden"]=campaign[stageIndex].hidden==true && hiddenReturnStage==1
        let secretSave=SavedRun(stage:stageIndex,score:score,lives:lives,hits:hits,multiplier:multiplier,returnStage:hiddenReturnStage,tokens:multiplierTokens)
        start(index:secretSave.stage,resume:secretSave);checks["secret_return_saved"]=hiddenReturnStage==1
        cleared=true;launchOrContinue();checks["secret_returns_campaign"]=stageIndex==1 && hiddenReturnStage==nil
        start(index:original.stage,resume:original);writeSmoke(checks);testing=false
    }
    func writeSmoke(_ checks:[String:Bool]) {
        let result:[String:Any]=["passed":checks.values.allSatisfy{$0},"edition":edition.rawValue,"checks":checks,"scope":"Deterministic engine, original asset masks and full-window geometry; physical-device behavior and full original parity remain unverified"]
        if let dir=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first,let data=try? JSONSerialization.data(withJSONObject:result,options:[.prettyPrinted,.sortedKeys]) {
            try? data.write(to:dir.appendingPathComponent("smoke-test.json"),options:.atomic)
            try? data.write(to:dir.appendingPathComponent("smoke-test-\(edition.rawValue).json"),options:.atomic)
        }
    }
}
