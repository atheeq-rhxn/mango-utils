pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

Scope {
  id: selectionState

  property real globalSelX: 0
  property real globalSelY: 0
  property real globalSelW: 0
  property real globalSelH: 0
  property real startX: 0
  property real startY: 0

  property bool isSelecting: false
  property bool isMoving: false
  property bool isResizing: false
  property int activeHandle: -1
  property real moveStartSelX: 0
  property real moveStartSelY: 0
  property real moveStartMouseX: 0
  property real moveStartMouseY: 0
  property real resizeAnchorX: 0
  property real resizeAnchorY: 0
  property bool isActivelyEditing: false

  readonly property int minSelectionSize: 4

  function clearSelection() {
    globalSelW = 0
    globalSelH = 0
    isActivelyEditing = false
  }

  function cancelEditing() {
    isSelecting = false
    isMoving = false
    isResizing = false
    isActivelyEditing = false
    activeHandle = -1
  }

  function clampSelectionToScreen(screen) {
    if (!screen || globalSelW <= 0) return
    const sf = screen.devicePixelRatio || 1.0
    const sMinX = screen.x
    const sMinY = screen.y
    const sMaxX = sMinX + (screen.width * sf)
    const sMaxY = sMinY + (screen.height * sf)

    if (globalSelX < sMinX) {
      globalSelW = Math.max(0, globalSelW - (sMinX - globalSelX))
      globalSelX = sMinX
    }
    if (globalSelX + globalSelW > sMaxX) {
      globalSelW = Math.max(0, sMaxX - globalSelX)
    }
    if (globalSelY < sMinY) {
      globalSelH = Math.max(0, globalSelH - (sMinY - globalSelY))
      globalSelY = sMinY
    }
    if (globalSelY + globalSelH > sMaxY) {
      globalSelH = Math.max(0, sMaxY - globalSelY)
    }
    if (globalSelW <= minSelectionSize || globalSelH <= minSelectionSize) {
      clearSelection()
    }
  }
}
