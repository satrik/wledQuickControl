// Author: Sascha Petrik

import Cocoa
import LaunchAtLogin
import Foundation

class MainViewController: NSViewController, NetServiceBrowserDelegate, NSTextFieldDelegate {
  
  @objc dynamic var launchAtLogin = LaunchAtLogin.kvo
  
  @IBOutlet var mainView: NSView!
  @IBOutlet weak var customViewDefault: NSView!
  @IBOutlet weak var customViewSettings1: NSView!
  @IBOutlet weak var customViewSettings2: NSView!
  @IBOutlet weak var brightnessSlider: NSSlider!
  @IBOutlet weak var brightnessSliderLabel: NSTextField!
  @IBOutlet weak var settingsButton: NSButtonCell!
  @IBOutlet weak var settingsNextButton: NSButton!
  @IBOutlet weak var textfieldWledHost: NSTextField!
  @IBOutlet weak var foundDevicesScrollView: NSScrollView!
  @IBOutlet weak var dropDownMenu: NSPopUpButton!
  @IBOutlet weak var addDeviceButton: NSButton!
  
  let defaults = UserDefaults.standard
  let appDelegate: AppDelegate? = NSApplication.shared.delegate as? AppDelegate
  
  var wledDeviceCurrent = ""
  
  var wledDevicesFound = [String]()
  var wledDevicesStored = [String]()
  
  let runLoop = RunLoop.current
  let distantFuture = Date.distantFuture
  
  var browser = NetServiceBrowser()
  var shouldKeepRunning = false
  
  
  override func viewDidLoad() {
    
    super.viewDidLoad()
    
    mainView.frame.size.width = 320
    brightnessSlider.isContinuous = true
    textfieldWledHost.delegate = self
    foundDevicesScrollView.wantsLayer = true
    foundDevicesScrollView.contentView.wantsLayer = true
    foundDevicesScrollView.layer?.cornerRadius = 7
    foundDevicesScrollView.contentView.layer?.cornerRadius = 7
    
  }
  
  
  override func viewDidAppear() {
    
    super.viewDidAppear()
    
    initViews()
    updateStates()
    updateItemsInViews()
    
  }
  
  
  func initViews() {
    
    
    if(isKeyPresentInUserDefaults(key: "wledDevicesStored")){
      
      wledDevicesStored = defaults.value(forKey: "wledDevicesStored") as! Array
      
    }
    
    if(isKeyPresentInUserDefaults(key: "wledDeviceCurrent")){
      
      wledDeviceCurrent = defaults.value(forKey: "wledDeviceCurrent") as! String
      
    } else {
      
      defaults.set("", forKey: "wledDeviceCurrent")

    }
    
    brightnessSlider.isEnabled = wledDevicesStored.count > 0 ? true : false
    
    
    customViewDefault.frame.origin.x = 0
    customViewSettings1.frame.origin.x = -350
    customViewSettings2.frame.origin.x = -700
    settingsButton.controlView?.frame.origin.x = 0
    settingsButton.controlView?.toolTip = "Show config"
    settingsButton.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)?.withSymbolConfiguration(NSImage.SymbolConfiguration.init(pointSize: 0, weight: .regular, scale: .large))
    settingsNextButton.frame.origin.x = -350
    settingsNextButton.image = NSImage(systemSymbolName: "chevron.backward", accessibilityDescription: nil)?.withSymbolConfiguration(NSImage.SymbolConfiguration.init(pointSize: 0, weight: .regular, scale: .large))
    
  }
  
  
  func isKeyPresentInUserDefaults(key: String) -> Bool {
    
    return UserDefaults.standard.object(forKey: key) != nil
    
  }
  
  
  func moveView(position: CGFloat) {
    
    var posView1:CGFloat = 0
    var posView2:CGFloat = -350
    var posView3:CGFloat = -700
    
    NSAnimationContext.runAnimationGroup({ context in
      
      context.duration = 1
      
      if(position == 0){
        
        settingsButton.controlView?.animator().frame.origin.x = 0
        settingsButton.controlView?.toolTip = "Show config"
        settingsNextButton.animator().frame.origin.x = -350
        
      } else if(position == 1) {
        
        posView1 = 350
        posView2 = 0
        posView3 = -350
        settingsButton.controlView?.animator().frame.origin.x = 270
        settingsButton.controlView?.toolTip = "Go back"
        settingsNextButton.animator().frame.origin.x = 0
        
      } else if(position == 2){
        
        posView1 = 700
        posView2 = 350
        posView3 = 0
        settingsButton.controlView?.animator().frame.origin.x = 350
        settingsButton.controlView?.toolTip = "Go back"
        settingsNextButton.animator().frame.origin.x = 270
        
      }
      
      customViewDefault.animator().frame.origin.x = posView1
      customViewSettings1.animator().frame.origin.x = posView2
      customViewSettings2.animator().frame.origin.x = posView3
      
    }){}
    
  }
  
  
  func postValues(sendOnOff: Bool, on: Bool, sendBri: Bool, bri: Int) {
    
    if(defaults.value(forKey: "wledDeviceCurrent") as! String != ""){
      
      wledDeviceCurrent = defaults.value(forKey: "wledDeviceCurrent") as! String
      
      let url = URL(string: "http://\(wledDeviceCurrent)/json/state")!
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
    
    if(defaults.value(forKey: "wledDeviceCurrent") as! String != "") {
      
      if let url = URL(string: "http://\(wledDeviceCurrent)/json/state") {
        
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
      
    } else {
      brightnessSliderLabel.stringValue = "---"
      brightnessSlider.integerValue = 0
    }
    
    
  }
  
  
  func updateItemsInViews() {
    
    dropDownMenu.removeAllItems()
    
    foundDevicesScrollView.documentView?.subviews.removeAll()
    let height = CGFloat(wledDevicesStored.count) * 20 < 47 ? 47 : CGFloat(wledDevicesStored.count) * 20
    foundDevicesScrollView.documentView?.frame.size.height = height
    wledDevicesStored.sort()
    
    let setY = (foundDevicesScrollView.documentView?.frame.size.height)! - 20
    
    for i in 0 ..< wledDevicesStored.count {
      
      dropDownMenu.addItem(withTitle: wledDevicesStored[i])
      
      let checkbox = NSButton.init(checkboxWithTitle: wledDevicesStored[i], target: self, action: #selector(checkBoxDidChange(_:)))
      
      checkbox.setButtonType(.switch)
      checkbox.frame = CGRect(x: 5, y: setY - (20 * CGFloat(i)), width: checkbox.bounds.width, height: 20)
      checkbox.state = .on
      
      foundDevicesScrollView.documentView?.addSubview(checkbox)
      
    }
    
    if let documentView = foundDevicesScrollView.documentView {
      
      documentView.scroll(NSPoint(x: 0, y: documentView.bounds.size.height))
      
    }
    
  }
  
  
  @IBAction func clickOpenWled(_ sender: Any) {
    
    if(defaults.value(forKey: "wledDeviceCurrent") as! String != "") {
      
      wledDeviceCurrent = defaults.value(forKey: "wledDeviceCurrent") as! String
      
      let url = "http://\(wledDeviceCurrent)"
      NSWorkspace.shared.open(URL(string: url)!)
      
    }
    
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
  
  
  @IBAction func dropDownChanged(_ sender: NSMenuItem) {
    
    wledDeviceCurrent = sender.title
    defaults.set(wledDeviceCurrent, forKey: "wledDeviceCurrent")
    updateStates()
    
  }
  
  
  @IBAction func clickSettingsButton(_ sender: Any) {
    
    let pos = customViewDefault.frame.origin.x
    let moveTo = CGFloat(pos == 0 ? 1 : 0)
    let btnImage = (pos == 0 ? NSImage(systemSymbolName: "chevron.forward", accessibilityDescription: nil) : NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil))
    settingsButton.image = btnImage?.withSymbolConfiguration(NSImage.SymbolConfiguration.init(pointSize: 0, weight: .regular, scale: .large))
    moveView(position: moveTo)
    
  }
  
  
  @IBAction func clickSettingsNextButton(_ sender: NSButton) {
    
    let pos = customViewDefault.frame.origin.x
    let moveTo = CGFloat(pos == 350 ? 2 : 1)
    let btnImage = (pos == 350 ? NSImage(systemSymbolName: "chevron.forward", accessibilityDescription: nil) : NSImage(systemSymbolName: "chevron.backward", accessibilityDescription: nil))
    
    settingsNextButton.image = btnImage?.withSymbolConfiguration(NSImage.SymbolConfiguration.init(pointSize: 0, weight: .regular, scale: .large))
    moveView(position: moveTo)
    textfieldWledHost.isEnabled = false
    textfieldWledHost.isEnabled = true
    
    if(sender.title == "Add Manually") {
      
      textfieldWledHost.becomeFirstResponder()
      
    }
    
  }
  
  
  @IBAction func clickSearchButton(_ sender: Any) {
    
    startSearchingWledDevices()
    
    while shouldKeepRunning && runLoop.run(mode:.default, before: distantFuture) {
      
      // stop search after 3 seconds - just to escape the search if there is no device found
      DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(3000)) {
        
        if(self.shouldKeepRunning) {
          
          self.shouldKeepRunning = false
          self.browser.stop()
          
        }
        
      }
      
    }
    
  }
  
  
  func startSearchingWledDevices() {
    
    shouldKeepRunning = true
    browser.delegate = self
    browser.searchForServices(ofType: "_wled._tcp.", inDomain: "local.")
    
  }
  
  
  func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
    
    wledDevicesFound.append(service.name + "." + service.domain.dropLast())
    
    if (!moreComing) {
      
      foundDevicesScrollView.documentView?.subviews.removeAll()
      
      var mergedArrays = Array(Set(wledDevicesFound + wledDevicesStored))
      mergedArrays.sort()
      let completeCount = mergedArrays.count
      
      foundDevicesScrollView.documentView?.subviews.removeAll()
      
      let height = CGFloat(completeCount) * 20 < 47 ? 47 : CGFloat(completeCount) * 20
      foundDevicesScrollView.documentView?.frame.size.height = height
      
      let setY = (foundDevicesScrollView.documentView?.frame.size.height)! - 20
      
      for i in 0 ..< mergedArrays.count {
        
        
        let checkbox = NSButton.init(checkboxWithTitle: mergedArrays[i], target: self, action: #selector(checkBoxDidChange(_:)))
        
        checkbox.setButtonType(.switch)
        checkbox.frame = CGRect(x: 5, y: setY - (20 * CGFloat(i)), width: checkbox.bounds.width, height: 20)
        
        if(wledDevicesStored.contains(mergedArrays[i])) {
          
          checkbox.state = .on
        
        }
        
        foundDevicesScrollView.documentView?.addSubview(checkbox)
        
      }
      
      if let documentView = foundDevicesScrollView.documentView {
        
        documentView.scroll(NSPoint(x: 0, y: documentView.bounds.size.height))
        
      }
      
      shouldKeepRunning = false
      browser.stop()
      
    }
    
  }
  
  
  @IBAction func checkBoxDidChange(_ sender: NSButton) {
    
    if(sender.state == .on) {
      
      if(wledDevicesStored.count == 0) {
        
        wledDevicesStored.append(sender.title)
        wledDeviceCurrent = sender.title
        defaults.set(wledDeviceCurrent, forKey: "wledDeviceCurrent")
        
      }
      
    } else {
      
      wledDevicesStored = wledDevicesStored.filter { $0 != sender.title }
      
      if(wledDevicesStored.count == 0) {
        
        wledDeviceCurrent = ""
        defaults.set(wledDeviceCurrent, forKey: "wledDeviceCurrent")
  
      }
      
    }
    
    dropDownMenu.removeAllItems()
    
    for device in wledDevicesStored {
      
      dropDownMenu.addItem(withTitle: device)
      
    }
    
    brightnessSlider.isEnabled = wledDevicesStored.count > 0 ? true : false
    defaults.set(wledDevicesStored, forKey: "wledDevicesStored")
    
    if(sender.state == .on) {
      
      dropDownMenu.selectItem(withTitle: sender.title)
      
    } else {
      
      dropDownMenu.select(nil)
      
    }
    
    updateStates()

  }
  
  
  @IBAction func clickOpenGithubRepo(_ sender: Any) {
    
    let url = "https://github.com/satrik/wledQuickControl"
    NSWorkspace.shared.open(URL(string: url)!)
    
  }
  
  
  func controlTextDidChange(_ obj: Notification) {
    
    let textField = obj.object as! NSTextField
    addDeviceButton.isEnabled = textField.stringValue.count > 0 ? true : false
    
  }
  
  
  @IBAction func clickAddDeviceButton(_ sender: Any) {
    
    if(!wledDevicesStored.contains(textfieldWledHost.stringValue)){
      
      wledDevicesStored.append(textfieldWledHost.stringValue.replacingOccurrences(of: "http://", with: ""))
      defaults.set(wledDevicesStored, forKey: "wledDevicesStored")
      updateItemsInViews()
      textfieldWledHost.stringValue = ""
      textfieldWledHost.isEnabled = false
      textfieldWledHost.isEnabled = true
      moveView(position: 1)
      
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
