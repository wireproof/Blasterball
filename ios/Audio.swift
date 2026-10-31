import AVFoundation
import Foundation

/// Original game recordings. Timing, mixing and session policy are the mobile adaptation.
final class GameAudio {
    static let shared = GameAudio()
    // BB2 native surface dispatcher event 2 uses bbreak; critter-hit event 0 uses critter.
    // BB3 overrides these aliases with its own original event samples below.
    private let baseEvents = ["start":"stagestart", "launch":"phit", "paddle":"phit", "brick":"bhit", "metal":"bbreak", "wall":"bbreak", "enemy":"critter", "loss":"loss", "gameover":"gameover", "divide":"break", "slow":"slow", "mini":"shrink", "grow":"grow", "oneup":"1up", "fast":"fast"]
    private var events:[String:String] {
        var result=baseEvents
        result["firework_launch"]="firework_launch";result["firework_explode"]="firework_explode"
        if edition=="bb3" {
            result["respawn"]="respawn"
            for id in [20,21,22,23,24,25,26,27,28,29,30,31,33,34,35,36,37,38] {result["power\(id)"]="power\(id)"}
            for event in ["wall","enemy","secret"] {result[event]=event}
        }
        return result
    }
    private var edition = "revolution"
    private var track = 1
    private var effects:[String:[AVAudioPlayer]] = [:]
    private var music:AVAudioPlayer?
    private var lastPlay:[String:TimeInterval] = [:]
    private var paused = true
    private var interrupted = false
    private let testing = ProcessInfo.processInfo.arguments.contains("--smoke-test")
    var enabled:Bool {
        get { UserDefaults.standard.object(forKey:"blasterball.audio.enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue,forKey:"blasterball.audio.enabled"); updatePlayback() }
    }
    private init() {
        NotificationCenter.default.addObserver(self,selector:#selector(interruption(_:)),name:AVAudioSession.interruptionNotification,object:nil)
    }
    func configure(edition:String) {
        guard ["revolution","remix","holidays","bb3"].contains(edition) else { return }
        music?.stop(); effects.values.flatMap{$0}.forEach{$0.stop()}; effects.removeAll(); lastPlay.removeAll()
        self.edition=edition
        track=1
        if let url=url("music1","m4a"), let player=try? AVAudioPlayer(contentsOf:url) {
            player.numberOfLoops = -1; player.volume=0.25; player.prepareToPlay(); music=player
        } else { music=nil }
        for (event,file) in events {
            if let url=url(file,"wav") {
                effects[event]=(0..<2).compactMap { _ in
                    guard let player=try? AVAudioPlayer(contentsOf:url) else { return nil }
                    player.volume=((event == "loss" || event == "respawn") && edition == "bb3") ? 0.5:0.65; player.prepareToPlay(); return player
                }
            }
        }
        updatePlayback()
        if ProcessInfo.processInfo.arguments.contains("--audio-check") { writeValidation() }
    }
    func setStage(_ index:Int,boss:Bool=false) {
        let desired=edition == "bb3" ? (boss ? 0:index%3+1):(index%2+1)
        guard desired != track else { return }
        track=desired; music?.stop()
        if let url=url("music\(track)","m4a"),let player=try? AVAudioPlayer(contentsOf:url) {
            player.numberOfLoops = -1; player.volume=0.25; player.prepareToPlay(); music=player
        } else { music=nil }
        updatePlayback()
    }
    private func url(_ name:String,_ ext:String)->URL? {
        Bundle.main.url(forResource:name,withExtension:ext,subdirectory:"Audio/\(edition)")
    }
    func setPaused(_ value:Bool) { paused=value; updatePlayback() }
    private func updatePlayback() {
        guard enabled,!paused,!interrupted,!testing else {
            music?.pause(); effects.values.flatMap{$0}.forEach{$0.stop()}; return
        }
        do {
            // Playback makes the in-game Sound toggle authoritative, including with the silent switch on.
            try AVAudioSession.sharedInstance().setCategory(.playback,mode:.default,options:.mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            if music?.isPlaying == false { music?.play() }
        } catch { /* Keep gameplay usable if an audio route is unavailable. */ }
    }
    func play(event:String) {
        guard enabled,!paused,!interrupted,!testing,let pool=effects[event],!pool.isEmpty else { return }
        let now=ProcessInfo.processInfo.systemUptime
        guard now-(lastPlay[event] ?? 0) >= 0.04 else { return }
        lastPlay[event]=now
        let player=pool.first(where:{!$0.isPlaying}) ?? pool[0]
        player.currentTime=0; player.play()
    }
    @objc private func interruption(_ note:Notification) {
        guard Thread.isMainThread else { DispatchQueue.main.async { self.interruption(note) }; return }
        guard let raw=note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,let type=AVAudioSession.InterruptionType(rawValue:raw) else { return }
        interrupted = type == .began
        updatePlayback()
    }
    private func writeValidation() {
        let decoded=events.keys.sorted().filter{effects[$0]?.count == 2}
        let expected=edition == "bb3" ? Array(0...3):Array(1...2)
        let tracks=expected.filter { index in
            guard let url=url("music\(index)","m4a"),let player=try? AVAudioPlayer(contentsOf:url) else { return false }; return player.duration > 0 && player.prepareToPlay()
        }
        let result:[String:Any]=["edition":edition,"musicTracksDecoded":tracks,"eventsDecoded":decoded,"musicDecoded":music != nil,"musicDuration":music?.duration ?? 0,"passed":decoded.count == events.count && music != nil && tracks.count == expected.count,"scope":"AVAudioPlayer decode/preparation; physical speaker output is not verified"]
        if let dir=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first,let data=try? JSONSerialization.data(withJSONObject:result,options:[.prettyPrinted,.sortedKeys]) { try? data.write(to:dir.appendingPathComponent("audio-check-\(edition).json")) }
    }
}
