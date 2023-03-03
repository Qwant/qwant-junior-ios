// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

#if canImport(WidgetKit)
import SwiftUI

// View for Quick Action Widget Buttons (Small & Medium)
// +-------------------------------------------------------+
// | +--------+                                            |
// | | ZSTACK |                                            |
// | +--------+                                            |
// | +--------------------------------------------------+  |
// | |+-------+                                         |  |
// | ||VSTACK |                                         |  |
// | |+-------+                                         |  |
// | | +---------------------------------------------+  |  |
// | | |+-------+                                    |  |  |
// | | ||HSTACK | +--------+-----+ +--------------+  |  |  |
// | | |+-------+ | VSTACK |     | |+----------+  |  |  |  |
// | | |          +--------+     | || lOGO FOR |  |  |  |  |
// | | |          | +----------+ | ||  WIDGET  |  |  |  |  |
// | | |          | | LABEL OF | | ||  ACTION  |  |  |  |  |
// | | |          | | SELECTED | | |+----------+  |  |  |  |
// | | |          | |  ACTION  | | |              |  |  |  |
// | | |          | +----------+ | |              |  |  |  |
// | | |          |              | |              |  |  |  |
// | | |          +--------------+ +--------------+  |  |  |
// | | |                                             |  |  |
// | | |                                             |  |  |
// | | +---------------------------------------------+  |  |
// | |                                                  |  |
// | | +--------------------------------------------+   |  |
// | | | +--------------------------+ +-----------+ |   |  |
// | | | | HSTACK (if small widget) | | +-------+ | |   |  |
// | | | +--------------------------+ | |FXICON | | |   |  |
// | | |                              | +-------+ | |   |  |
// | | |                              |           | |   |  |
// | | |                              |           | |   |  |
// | | |                              +-----------+ |   |  |
// | | |                                            |   |  |
// | | +--------------------------------------------+   |  |
// | |                                                  |  |
// | |                                                  |  |
// | |                                                  |  |
// | +--------------------------------------------------+  |
// |                                                       |
// +-------------------------------------------------------+

struct ImageButtonWithLabel: View {
    var isSmall: Bool
    var link: QuickLink
    var isBackgroundLight: Bool
    
    var colorValue: Color {
        if isBackgroundLight {
            return .black
        } else {
            return .white
        }
    }

    var paddingValue: CGFloat {
        if isSmall {
            return 10.0
        } else {
            return 8.0
        }
    }

    var body: some View {
        Link(destination: isSmall ? link.smallWidgetUrl : link.mediumWidgetUrl) {
            ZStack(alignment: .leading) {
                if !isSmall {
                    ContainerRelativeShape()
                        .fill(LinearGradient(gradient: Gradient(colors: link.backgroundColors), startPoint: .bottomLeading, endPoint: .topTrailing))
                }

                VStack(alignment: .center, spacing: 50.0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            if isSmall {
                                Text(link.label)
                                    .foregroundColor(colorValue)
                                    .font(.headline)
                                    .minimumScaleFactor(0.75)
                                    .layoutPriority(1000)
                            } else {
                                Text(link.label)
                                    .foregroundColor(colorValue)
                                    .font(.footnote)
                                    .minimumScaleFactor(0.75)
                                    .layoutPriority(1000)
                            }
                        }
                        Spacer()
                        if link == .search && isSmall {
                            Image("search-button")
                                .foregroundColor(colorValue)
                                .scaledToFit()
                                .frame(height: 24.0)
                        } else {
                            Image(link.imageName)
                                .scaledToFit()
                                .frame(height: 24.0)
                        }
                    }
                    if isSmall {
                        HStack(alignment: .bottom) {
                            Spacer()
                            Image("faviconFox")
                                .scaledToFit()
                                .frame(height: 24.0)
                        }
                    }
                }
                .foregroundColor(Color("widgetLabelColors"))
                .padding([.horizontal, .vertical], paddingValue)
            }
        }
    }
}
#endif
