// Author: Sascha Petrik

import Cocoa
import LaunchAtLogin

class MainViewController: NSViewController {
  
  @objc dynamic var launchAtLogin = LaunchAtLogin.kvo
  
  @IBOutlet var mainView: NSView!
  @IBOutlet weak var customViewDefault: NSView!
  @IBOutlet weak var customViewSettings: NSView!
  @IBOutlet weak var brightnessSlider: NSSlider!
  @IBOutlet weak var brightnessSliderLabel: NSTextField!
  @IBOutlet weak var settingsButton: NSButtonCell!
  @IBOutlet weak var textfieldWledHost: NSTextField!
  @IBOutlet weak var saveButton: NSButton!
  
  let defaults = UserDefaults.standard
  let appDelegate: AppDelegate? = NSApplication.shared.delegate as? AppDelegate
  
  var wledIp = ""
  
  override func viewDidLoad() {
    
    super.viewDidLoad()

    mainView.frame.size.width = 320
    brightnessSlider.isContinuous = true

  }
  
  
  override func viewDidAppear() {
    
    super.viewDidAppear()
    
    initViews()
    updateStates()
    
  }
  
  
  func initViews() {
    
    if(isKeyPresentInUserDefaults(key: "wledIp")){
      
      wledIp = defaults.value(forKey: "wledIp") as! String
      
    }
    
    if(wledIp != ""){
      
      textfieldWledHost.stringValue = wledIp
      brightnessSlider.isEnabled = true
      
    } else {
      
      brightnessSlider.isEnabled = false
      
    }
    
    customViewDefault.frame.origin.x = 0
    customViewSettings.frame.origin.x = -350
    settingsButton.controlView?.frame.origin.x = 0
    settingsButton.controlView?.toolTip = "Show config"
    settingsButton.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)?.withSymbolConfiguration(NSImage.SymbolConfiguration.init(pointSize: 0, weight: .regular, scale: .large))
    
  }
  
  
  func isKeyPresentInUserDefaults(key: String) -> Bool {
    
    return UserDefaults.standard.object(forKey: key) != nil
    
  }
  
  
  func moveView(position: CGFloat) {
    
    NSAnimationContext.runAnimationGroup({ context in
      
      context.duration = 1
      
      customViewDefault.animator().frame.origin.x = position
      customViewSettings.animator().frame.origin.x = position - 350
      settingsButton.controlView?.animator().frame.origin.x = position == 0 ? 0 : 270
      settingsButton.controlView?.toolTip = position == 0 ? "Show config" : "Go back"
      
    }){}
    
  }
  
  
  func postValues(sendOnOff: Bool, on: Bool, sendBri: Bool, bri: Int) {
    
    if(isKeyPresentInUserDefaults(key: "wledIp")){
      
      wledIp = defaults.value(forKey: "wledIp") as! String
      
      let url = URL(string: "http://\(wledIp)/json/state")!
      var jsonData: Any = []
      
      if(sendOnOff) {
        
        jsonData = ["on": on]
        
      } else if(sendBri) {
        
        jsonData = ["bri": round(Double(bri) * 2.55)]
        
      }
      
      let bodyData = try? JSONSerialization.data(withJSONObject: jsonData)
      
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.httpBody = bodyData
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.addValue("application/json", forHTTPHeaderField: "Accept")
      
      URLSession.shared.dataTask(with: request) { _,_,_ in  }.resume()
      
    }
    
  }
  
  
  func updateStates() {
    
    struct currentStates: Decodable {
      
      let on: Bool
      let bri: Int
      
    }
    
    if(isKeyPresentInUserDefaults(key: "wledIp")){
      
      if let url = URL(string: "http://\(wledIp)/json/state") {
        
        URLSession.shared.dataTask(with: url) { data,_,_ in
          
          if let data = data {
            
            do {
              
              let res = try JSONDecoder().decode(currentStates.self, from: data)
              
              DispatchQueue.main.async {
                
                self.appDelegate?.statusItem.button?.image = res.on ? self.appDelegate?.menuIconOn : self.appDelegate?.menuIconOff
                let mappedBri = Int(round(Double(res.bri) / 2.55))
                self.brightnessSliderLabel.stringValue = "\(mappedBri)%"
                self.brightnessSlider.integerValue = mappedBri
                
              }
              
            } catch _ {
              // no error handling currently -> maybe in a later version...
            }
            
          }
          
        }.resume()
        
      }
      
    }
    
  }
  
  
  
  @IBAction func clickOpenWled(_ sender: Any) {
    
    if(isKeyPresentInUserDefaults(key: "wledIp")){

      wledIp = defaults.value(forKey: "wledIp") as! String

      let url = "http://\(wledIp)"
      NSWorkspace.shared.open(URL(string: url)!)
      
    }
    
  }

  
  @IBAction func clickOpenGithubRepo(_ sender: Any) {
    
    let url = "https://github.com/satrik/wledQuickControl"
    NSWorkspace.shared.open(URL(string: url)!)
    
  }
  
  
  @IBAction func clickSettingsBtn(_ sender: Any) {
    
    let pos = customViewDefault.frame.origin.x
    let moveTo = CGFloat(pos == 0 ? 350 : 0)
    let btnImage = (pos == 0 ? NSImage(systemSymbolName: "chevron.forward", accessibilityDescription: nil) : NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil))
    settingsButton.image = btnImage?.withSymbolConfiguration(NSImage.SymbolConfiguration.init(pointSize: 0, weight: .regular, scale: .large))
    moveView(position: moveTo)
    textfieldWledHost.isEnabled = false
    textfieldWledHost.isEnabled = true
    
  }
  
  
  @IBAction func changeBrightnessSlider(_ sender: Any) {
    
    let event = NSApp.currentEvent!
    
    let val = brightnessSlider.integerValue
    
    switch event.type {
    
    case .leftMouseDragged, .rightMouseDragged:
      brightnessSliderLabel.stringValue = "\(val)%"
    case .leftMouseUp, .rightMouseUp:
      brightnessSliderLabel.stringValue = "\(val)%"
      postValues(sendOnOff: false, on: false, sendBri: true, bri: val)
    default:
      break
      
    }
    
  }
  
  
  @IBAction func clickedSaveButton(_ sender: Any) {
    
    defaults.set(textfieldWledHost.stringValue, forKey: "wledIp")
    
    saveButton.title = ""
    saveButton.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: nil)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800)) {
     
      self.saveButton.image = nil
      self.saveButton.title = "Save"
      self.moveView(position: 0)
      
      DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400)) {
      
        self.initViews()
      
      }
    
    }
  
  }
  
  
  @IBAction func clickedQuitButton(_ sender: Any) {
  
    NSApplication.shared.terminate(nil)
  
  }

}


extension MainViewController {
  
  static func createController() -> MainViewController {
  
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    let identifier = "MainViewController"
    
    guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? MainViewController else {
      
      fatalError("Why cant i find MainViewController? - Check Main.storyboard")
      
    }
    
    return viewcontroller
    
  }
  
}
