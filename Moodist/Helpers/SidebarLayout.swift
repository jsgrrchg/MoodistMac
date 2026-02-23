//
//  SidebarLayout.swift
//  MoodistMac
//
//  Sidebar width clamping utilities.
//

import CoreGraphics

enum SidebarLayout {
    static func maxSidebarWidth(
        totalWidth: CGFloat,
        minSidebarWidth: CGFloat,
        maxSidebarLimit: CGFloat,
        minContentWidth: CGFloat
    ) -> CGFloat {
        let widthLimitedByContent = max(minSidebarWidth, totalWidth - minContentWidth)
        return min(maxSidebarLimit, widthLimitedByContent)
    }

    static func clampedSidebarWidth(
        desiredWidth: CGFloat,
        totalWidth: CGFloat,
        minSidebarWidth: CGFloat,
        maxSidebarLimit: CGFloat,
        minContentWidth: CGFloat
    ) -> CGFloat {
        let maxAllowed = maxSidebarWidth(
            totalWidth: totalWidth,
            minSidebarWidth: minSidebarWidth,
            maxSidebarLimit: maxSidebarLimit,
            minContentWidth: minContentWidth
        )
        return min(maxAllowed, max(minSidebarWidth, desiredWidth))
    }

    static func adjustedSidebarWidth(
        currentWidth: CGFloat,
        desiredWidth: CGFloat,
        totalWidth: CGFloat,
        isResizing: Bool,
        minSidebarWidth: CGFloat,
        maxSidebarLimit: CGFloat,
        minContentWidth: CGFloat
    ) -> CGFloat {
        if isResizing {
            return clampedSidebarWidth(
                desiredWidth: currentWidth,
                totalWidth: totalWidth,
                minSidebarWidth: minSidebarWidth,
                maxSidebarLimit: maxSidebarLimit,
                minContentWidth: minContentWidth
            )
        }

        return clampedSidebarWidth(
            desiredWidth: desiredWidth,
            totalWidth: totalWidth,
            minSidebarWidth: minSidebarWidth,
            maxSidebarLimit: maxSidebarLimit,
            minContentWidth: minContentWidth
        )
    }
}
