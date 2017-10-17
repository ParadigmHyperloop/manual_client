//
//  ViewController.swift
//  manual_client
//
//  Created by Eddie Hurtig on 7/5/17.
//  Copyright © 2017 Eddie Hurtig. All rights reserved.
//

import Cocoa
import SwiftSocket

class ViewController: NSViewController {
  @IBOutlet var mainView: NSView!

  @IBOutlet weak var addressField: NSTextField!
  @IBOutlet weak var portField: NSTextField!
  @IBOutlet weak var connectionLoading: NSProgressIndicator!
  @IBOutlet weak var connectButton: NSButton!
  
  @IBOutlet weak var liveMode: NSButton!
  @IBOutlet weak var cycleInterval: NSTextField!
  @IBOutlet weak var cycleIntervalInfinite: NSButton!
  @IBOutlet weak var cycleCount: NSTextField!
  @IBOutlet weak var cycleCountInfinite: NSButton!
  
  @IBOutlet weak var mainProgressBar: NSProgressIndicator!
  
  @IBOutlet weak var mpyeA: NSSlider!
  @IBOutlet weak var mpyeB: NSSlider!
  @IBOutlet weak var mpyeC: NSSlider!
  @IBOutlet weak var mpyeD: NSSlider!

  @IBOutlet weak var mpyeALabel: NSTextField!
  @IBOutlet weak var mpyeBLabel: NSTextField!
  @IBOutlet weak var mpyeCLabel: NSTextField!
  @IBOutlet weak var mpyeDLabel: NSTextField!
  
  @IBOutlet weak var skateA: NSButton!
  @IBOutlet weak var skateB: NSButton!
  @IBOutlet weak var skateC: NSButton!
  @IBOutlet weak var skateD: NSButton!

  @IBOutlet weak var hpFill: NSButton!
  @IBOutlet weak var ventValve: NSButton!
  
  @IBOutlet weak var packA: NSButton!
  @IBOutlet weak var packB: NSButton!

  @IBOutlet weak var brakeAEngage: NSButton!
  @IBOutlet weak var brakeAClosed: NSButton!
  @IBOutlet weak var brakeAReleased: NSButton!
  
  @IBOutlet weak var brakeBEngage: NSButton!
  @IBOutlet weak var brakeBClosed: NSButton!
  @IBOutlet weak var brakeBReleased: NSButton!
  
  let default_window_name = "Paradigm Hyperloop Pod Testing Tool"
  
  var podClient: TCPClient!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setSetpointControls(enabled: false)
    // Do any additional setup after loading the view.
  }

  override func viewDidAppear() {
    self.view.window!.title = default_window_name
  }

  override var representedObject: Any? {
    didSet {
    // Update the view, if already loaded.
    }
  }

  func isLive() -> Bool {
    return liveMode.integerValue != 0
  }

  @IBAction func updateLive(_ sender: Any) {
    if isLive() {
      setTimingControls(enabled: false)
    } else {
      setTimingControls(enabled: true)
    }
  }

  @IBAction func performConnection(_ sender: Any) {
    if (podClient == nil) {
      let address = addressField.stringValue
      let port = portField.intValue
      let client = TCPClient(address: address, port: port)
      switch client.connect(timeout: 1) {
      case .success:
        podClient = client
        connectButton.title = "Disconnect"
        addressField.isEnabled = false
        portField.isEnabled = false
        print("Connected!")
        self.view.window!.title = "Connected to \(address):\(port)"
        self.setSetpointControls(enabled: true)
        return
      case .failure(let error):
        print(error)
        connectButton.title = "Failed!"
        DispatchQueue.global(qos: .background).async {
          sleep(1);
          DispatchQueue.main.async {
            if self.connectButton.title == "Failed!" {
              self.connectButton.title = "Connect"
            }
          }
        }
      }
    } else {
      podClient.close()
      podClient = nil
      self.view.window!.title = default_window_name

      connectButton.title = "Connect"
      addressField.isEnabled = true
      portField.isEnabled = true
    }
    self.setSetpointControls(enabled: false)
  }

  @IBAction func startCycle(_ sender: Any) {
    if !isConnected() {
      return
    }
    
    if cycleInterval.intValue < 200 {
      let alert = NSAlert.init()
      alert.messageText = "Your settings are unsafe."
      alert.informativeText = "Please ensure your interval is > 200ms"
      alert.addButton(withTitle: "Fuck Off Ed")
      alert.addButton(withTitle: "Cancel")
      
      let resp = alert.runModal()
      if resp == NSAlertFirstButtonReturn {
        return
      }
      
      let confirm = NSAlert.init()
      confirm.messageText = "This will damage solenoid valves!"
      confirm.informativeText = "Please Click Cancel Now"
      confirm.addButton(withTitle: "Continue Anyways")
      confirm.addButton(withTitle: "Cancel")
      let confirm_resp = confirm.runModal()
      
      if confirm_resp == NSAlertFirstButtonReturn {
        return
      }
    }
    setSetpointControls(enabled: false)
    mainProgressBar.doubleValue = 0.0
    mainProgressBar.isHidden = false
    
    let count = self.cycleCount.intValue
    mainProgressBar.isIndeterminate = false
    mainProgressBar.maxValue = Double(count * 2)
    DispatchQueue.global(qos: .userInitiated).async {
      for _ in 0..<count {
        self.sendUpdate(self.buildPodState())
        usleep(UInt32(self.cycleInterval.intValue * 1000))
        self.mainProgressBar.increment(by: 1.0)
        self.sendUpdate(self.buildSafeState())
        usleep(UInt32(self.cycleInterval.intValue * 1000))
        self.mainProgressBar.increment(by: 1.0)
        print("Progress: ", self.mainProgressBar.doubleValue, "/", self.mainProgressBar.maxValue)
        DispatchQueue.main.async {
          self.mainProgressBar.display()
        }
      }
      
      // Bounce back to the main thread to update the UI
      DispatchQueue.main.async {
        self.mainProgressBar.display()

        self.setSetpointControls(enabled: true)
        self.mainProgressBar.isHidden = true
      }
    }
  }

  @IBAction func selectBrakeA(_ sender: Any) {
    sendCurrentIfLive()
  }

  @IBAction func selectBrakeB(_ sender: Any) {
    sendCurrentIfLive()
  }
  
  @IBAction func setValveState(_ sender: Any) {
    sendCurrentIfLive()
  }
  
  @IBAction func setValveStateInverse(_ sender: Any) {
    sendCurrentIfLive()
  }
  
  @IBAction func updateMPYE(_ sender: NSSlider!) {
    switch (sender) {
      case mpyeA:
        mpyeALabel.stringValue = sender.stringValue
      case mpyeB:
        mpyeBLabel.stringValue = sender.stringValue
      case mpyeC:
        mpyeCLabel.stringValue = sender.stringValue
      case mpyeD:
        mpyeDLabel.stringValue = sender.stringValue
      default:
        print("Unknown sender: ", sender)
    }
    sendCurrentIfLive()
  }
  
  func isConnected() -> Bool {
    return podClient != nil
  }
  
  func buildSafeState() -> PodState {
    let ps = PodState(
      skateA: 0,
      skateB: 0,
      skateC: 0,
      skateD: 0,
      
      mpyeA: 128,
      mpyeB: 128,
      mpyeC: 128,
      mpyeD: 128,
      
      brakeA: 0,
      brakeB: 0,
      
      hpFill: 0,
      vent: 1,
      packA: 1,
      packB: 1
    )
    
    return ps
  }
  
  func buildPodState() -> PodState {
    let ps = PodState(
      skateA: UInt8(skateA.intValue),
      skateB: UInt8(skateB.intValue),
      skateC: UInt8(skateC.intValue),
      skateD: UInt8(skateD.intValue),
      
      mpyeA: UInt8(mpyeA.doubleValue * 1.275 + 128),
      mpyeB: UInt8(mpyeB.doubleValue * 1.275 + 128),
      mpyeC: UInt8(mpyeC.doubleValue * 1.275 + 128),
      mpyeD: UInt8(mpyeD.doubleValue * 1.275 + 128),
      
      brakeA: UInt8(brakeAEngage.integerValue * 1 + brakeAReleased.integerValue * 2),
      brakeB: UInt8(brakeBEngage.integerValue * 1 + brakeBReleased.integerValue * 2),
      
      hpFill: UInt8(hpFill.intValue),
      vent: UInt8(ventValve.intValue),
      packA: UInt8(packA.intValue),
      packB: UInt8(packB.intValue)
    )
    
    return ps
  }
  
  func sendCurrentIfLive() {
    if isLive() {
      sendUpdate(buildPodState())
    }
  }

  func sendUpdate(_ state: PodState) {
    if podClient != nil {
      print("Sending Update: ", state)
      let data = state.toBytes()
      print("Update is ", data.count, " bytes long")

      podClient.send(data: data)
    }
  }
  
  
  func setTimingControls(enabled: Bool) {
    cycleInterval.isEnabled = enabled
    cycleIntervalInfinite.isEnabled = enabled
    cycleCount.isEnabled = enabled
    cycleCountInfinite.isEnabled = enabled
  }

  func setSetpointControls(enabled: Bool) {
    mpyeA.isEnabled = enabled
    mpyeB.isEnabled = enabled
    mpyeC.isEnabled = enabled
    mpyeD.isEnabled = enabled
    mpyeALabel.isEnabled = enabled
    mpyeBLabel.isEnabled = enabled
    mpyeCLabel.isEnabled = enabled
    mpyeDLabel.isEnabled = enabled
    skateA.isEnabled = enabled
    skateB.isEnabled = enabled
    skateC.isEnabled = enabled
    skateD.isEnabled = enabled
    hpFill.isEnabled = enabled
    ventValve.isEnabled = enabled
    brakeAEngage.isEnabled = enabled
    brakeAClosed.isEnabled = enabled
    brakeAReleased.isEnabled = enabled
    brakeBEngage.isEnabled = enabled
    brakeBClosed.isEnabled = enabled
    brakeBReleased.isEnabled = enabled
    packA.isEnabled = enabled
    packB.isEnabled = enabled
  }
}

