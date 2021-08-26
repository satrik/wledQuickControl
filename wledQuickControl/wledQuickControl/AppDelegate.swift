// Author: Sascha Petrik

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  var mainView = MainViewController()
  var eventMonitor: EventMonitor?
  let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
  let popover = NSPopover()
  let menuIconOn = NSImage(named:"wled_on")
  let menuIconOff = NSImage(named:"wled_off")
  
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    
    if let button = statusItem.button {
      
      button.image = menuIconOn
      button.action = #selector(AppDelegate.togglePopover(_:))
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
      
    }
    
    popover.contentViewController = MainViewController.createController()
    
    eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
      
      if let strongSelf = self, strongSelf.popover.isShown {
        
        strongSelf.closePopover(sender: event)
        
      }
      
    }
    
  }
  
  
  @objc func togglePopover(_ sender: Any?) {
    
    let event = NSApp.currentEvent!
    
    if event.type == NSEvent.EventType.rightMouseUp {
      
      if popover.isShown {
        
        closePopover(sender: sender)
        
      } else {
        
        showPopover(sender: sender)
        self.popover.contentViewController?.view.window?.becomeKey()
        
      }
      
    } else {
      
      if let button = self.statusItem.button {
        
        if(mainView.isKeyPresentInUserDefaults(key: "wledIp")){
          
          if (button.image == menuIconOn){
            
            button.image = menuIconOff
            mainView.postValues(sendOnOff: true, on: false, sendBri: false, bri: 0)
            
          } else {
            
            button.image = menuIconOn
            mainView.postValues(sendOnOff: true, on: true, sendBri: false, bri: 0)
            
          }
          
        } else {
          
          button.layer?.backgroundColor = CGColor(red: 0.75, green: 0, blue: 0 , alpha: 0.75)
          
          DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800)) {
            
            button.layer?.backgroundColor = CGColor(red: 0, green: 0, blue: 0 , alpha: 0)
            
          }
          
        }
        
      }
      
    }
    
  }
  
  
  func showPopover(sender: Any?) {
    
    if let button = statusItem.button {
      
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
      eventMonitor?.start()
      
    }
    
  }
  
  
  func closePopover(sender: Any?) {
    
    popover.performClose(sender)
    eventMonitor?.stop()
    
  }
  
  
}
