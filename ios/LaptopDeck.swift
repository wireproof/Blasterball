import UIKit
final class LaptopDeck:UIView {
    var controlRange:CGRect = .zero {didSet {setNeedsDisplay()}}
    var fraction:CGFloat=0.5 {didSet {setNeedsDisplay()}}
    override init(frame:CGRect) {super.init(frame:frame);isUserInteractionEnabled=false;isOpaque=true}
    required init?(coder:NSCoder) {fatalError()}
    override func draw(_ rect:CGRect) {
        guard let c=UIGraphicsGetCurrentContext() else{return}
        let w=bounds.width,h=bounds.height
        UIColor(red:0.01,green:0.04,blue:0.08,alpha:1).setFill();c.fill(bounds)
        c.setStrokeColor(UIColor.cyan.withAlphaComponent(0.12).cgColor);c.setLineWidth(1)
        for i in 0...20 {let x=CGFloat(i)*w/20;c.move(to:CGPoint(x:w/2+(x-w/2)*0.3,y:0));c.addLine(to:CGPoint(x:x,y:h));c.strokePath()}
        for i in 1...9 {let y=CGFloat(i*i)*h/81;c.move(to:CGPoint(x:0,y:y));c.addLine(to:CGPoint(x:w,y:y));c.strokePath()}
        let pad=CGRect(x:controlRange.minX,y:h*0.24,width:controlRange.width,height:h*0.52)
        let outline=UIBezierPath(roundedRect:pad,cornerRadius:24)
        UIColor(red:0.02,green:0.10,blue:0.15,alpha:0.95).setFill();outline.fill()
        UIColor.cyan.withAlphaComponent(0.5).setStroke();outline.lineWidth=1.5;outline.stroke()
        func label(_ text:String,_ y:CGFloat,_ size:CGFloat,_ color:UIColor) {
            let style=NSMutableParagraphStyle();style.alignment = .center
            (text as NSString).draw(in:CGRect(x:12,y:y,width:w-24,height:40),withAttributes:[.font:UIFont.monospacedSystemFont(ofSize:size,weight:.semibold),.foregroundColor:color,.paragraphStyle:style])
        }
        label("B L A S T E R B A L L",h*0.08,min(21,w/27),.white)
        label("PADDLE CONTROL",h*0.29,12,.cyan)
        let track=CGRect(x:pad.minX,y:pad.midY,width:max(1,pad.width),height:2)
        UIColor.cyan.withAlphaComponent(0.25).setFill();c.fill(track)
        let x=track.minX+min(1,max(0,fraction))*track.width
        let puck=UIBezierPath(roundedRect:CGRect(x:x-24,y:track.midY-7,width:48,height:14),cornerRadius:7)
        c.setShadow(offset:.zero,blur:18,color:UIColor.cyan.cgColor);UIColor.cyan.setFill();puck.fill();c.setShadow(offset:.zero,blur:0,color:nil)
        label("SLIDE INSIDE THE DECK • RELEASE TO LAUNCH",h*0.82,min(12,w/35),.lightGray)
    }
}
