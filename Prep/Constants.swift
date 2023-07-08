import Foundation
import SwiftUI

let UUIDSeparator = "_"
let BarcodesSeparator = "¦"
let NilDouble: Double = -1
let NilInt: Int = -1
let NilString: String = ""

let NumberOfTimeSlotsInADay = 120

let IdealItemFormHeight: CGFloat = 650
let IdealItemFormWidth: CGFloat = 400

let IdealCameraHeight: CGFloat = 800
let IdealCameraWidth: CGFloat = 800

let CellPopoverAnchor: PopoverAttachmentAnchor = .point(.init(x: 0.1, y: 0.5))

let DefaultDensity = FoodDensity(
    weightAmount: 200,
    weightUnit: .g,
    volumeAmount: 1,
    volumeUnit: .cupMetric
)

let DefaultAmountValue = FormValue(100, .weight(.g))
let DefaultServingValue = FormValue(100, .weight(.g))

