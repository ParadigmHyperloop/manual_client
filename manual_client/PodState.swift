//
//  PodState.swift
//  manual_client
//
//  Created by Eddie Hurtig on 7/5/17.
//  Copyright © 2017 Eddie Hurtig. All rights reserved.
//

import Foundation

struct PodState {
  var skateA: UInt8
  var skateB: UInt8
  var skateC: UInt8
  var skateD: UInt8
  
  var mpyeA: UInt8
  var mpyeB: UInt8
  var mpyeC: UInt8
  var mpyeD: UInt8
  
  var brakeA: UInt8
  var brakeB: UInt8
  
  var hpFill: UInt8
  var vent: UInt8
  
  var packA: UInt8
  var packB: UInt8
  
  func toBytes() -> Data {
    var d = Data()
    
    d.append(skateA)
    d.append(skateB)
    d.append(skateC)
    d.append(skateD)
    
    d.append(mpyeA)
    d.append(mpyeB)
    d.append(mpyeC)
    d.append(mpyeD)
    
    d.append(brakeA)
    d.append(brakeB)
    
    d.append(hpFill)
    d.append(vent)
    d.append(packA)
    d.append(packB)
    
    return d
  }
}
