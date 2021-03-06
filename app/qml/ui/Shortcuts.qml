import QtQuick 2.6

import App 1.0

Item {
    objectName: "shortcuts"

    property var window
    property Project project: projectManager.project
    property int projectType: project ? project.type : 0
    readonly property bool isImageProjectType: projectType === Project.ImageType || projectType === Project.LayeredImageType
    property Item canvasContainer
    property ImageCanvas canvas
    readonly property bool canvasHasActiveFocus: canvas ? canvas.activeFocus : false

    Shortcut {
        sequence: settings.quitShortcut
        onActivated: Qt.quit()
    }

    Shortcut {
        objectName: "newShortcut"
        sequence: settings.newShortcut
        onActivated: doIfChangesDiscarded(function() { newProjectPopup.open() }, true)
        enabled: canvasHasActiveFocus
    }

    Shortcut {
        objectName: "openShortcut"
        sequence: settings.openShortcut
        onActivated: doIfChangesDiscarded(function() { openProjectDialog.open() }, true)
        // There could be no project open, so the canvas won't exist and hence its container will have focus.
        enabled: canvasHasActiveFocus || canvasContainer.activeFocus
    }

    Shortcut {
        objectName: "saveShortcut"
        sequence: settings.saveShortcut
        onActivated: saveOrSaveAs()
        enabled: canvasHasActiveFocus && project && project.canSave
    }

    Shortcut {
        objectName: "saveAsShortcut"
        sequence: settings.saveAsShortcut
        onActivated: saveAsDialog.open()
        enabled: canvasHasActiveFocus && project
    }

    Shortcut {
        objectName: "exportShortcut"
        sequence: settings.exportShortcut
        onActivated: exportDialog.open()
        enabled: project && project.loaded && projectType === Project.LayeredImageType
    }

    Shortcut {
        objectName: "closeShortcut"
        sequence: settings.closeShortcut
        onActivated: doIfChangesDiscarded(function() { project.close() })
        enabled: canvasHasActiveFocus
    }

    Shortcut {
        objectName: "revertShortcut"
        sequence: settings.revertShortcut
        onActivated: project.revert()
        enabled: canvasHasActiveFocus
    }

    Shortcut {
        objectName: "undoShortcut"
        sequence: settings.undoShortcut
        onActivated: {
            // A selection should be cleared when Ctrl + Z is pressed, as this is
            // what mspaint does. However, it doesn't make sense for a selection
            // to have its own undo command (as it's cleared after the first undo
            // on selection moves).
            // It's also not even possible to use the undo framework to implement
            // support for mspaint's undo behaviour, because in order for the commands
            // to be mergeable, a macro needs to be used, and when a macro is being composed,
            // it's not even *possible* to undo/redo.
            // So, we let ImageCanvas intercept the undo shortcut
            // to handle this special case ourselves. This has the advantage of
            // being faster by not using an event filter..
            // .. and I couldn't manage to override shortcuts using an event filter.
            if (!canvas.overrideShortcut(sequence))
                project.undoStack.undo()
        }
        enabled: canvasHasActiveFocus && project && project.undoStack.canUndo
    }

    Shortcut {
        objectName: "redoShortcut"
        sequence: settings.redoShortcut
        onActivated: project.undoStack.redo()
        enabled: canvasHasActiveFocus && project && project.undoStack.canRedo
    }

    Shortcut {
        objectName: "copyShortcut"
        sequence: StandardKey.Copy
        onActivated: canvas.copySelection()
        enabled: isImageProjectType && canvasHasActiveFocus && canvas.hasSelection
    }

    Shortcut {
        objectName: "pasteShortcut"
        sequence: StandardKey.Paste
        onActivated: canvas.paste()
        enabled: isImageProjectType && canvasHasActiveFocus
    }

    Shortcut {
        id: primaryDeleteShortcut
        objectName: "deleteShortcut"
        sequence: StandardKey.Delete
        onActivated: canvas.deleteSelection()
        enabled: isImageProjectType && canvasHasActiveFocus && canvas.hasSelection
    }

    // StandardKey.Delete doesn't work on a MacBook Pro keyboard;
    // Qt uses Fn+Delete instead, and "Backspace" is the only thing that seems to work,
    // so we need two shortcuts. See: https://bugreports.qt.io/browse/QTBUG-67430
    Shortcut {
        objectName: "deleteViaBackspaceShortcut"
        sequence: "Backspace"
        onActivated: canvas.deleteSelection()
        enabled: primaryDeleteShortcut.enabled
    }

    Shortcut {
        objectName: "selectAllShortcut"
        sequence: StandardKey.SelectAll
        onActivated: canvas.selectAll()
        enabled: isImageProjectType && canvasHasActiveFocus
    }

    Shortcut {
        objectName: "flipHorizontallyShortcut"
        sequence: settings.flipHorizontallyShortcut
        onActivated: canvas.flipSelection(Qt.Horizontal)
        enabled: isImageProjectType && canvasHasActiveFocus && canvas.hasSelection
    }

    Shortcut {
        objectName: "flipVerticallyShortcut"
        sequence: settings.flipVerticallyShortcut
        onActivated: canvas.flipSelection(Qt.Vertical)
        enabled: isImageProjectType && canvasHasActiveFocus && canvas.hasSelection
    }

    Shortcut {
        objectName: "resizeCanvasShortcut"
        sequence: settings.resizeCanvasShortcut
        onActivated: canvasSizePopup.open()
        enabled: canvasHasActiveFocus && canvas.hasSelection
    }

    Shortcut {
        objectName: "resizeImageShortcut"
        sequence: settings.resizeImageShortcut
        onActivated: imageSizePopup.open()
        enabled: isImageProjectType && canvasHasActiveFocus && canvas.hasSelection
    }

    Shortcut {
        objectName: "moveContentsShortcut"
        sequence: settings.moveContentsShortcut
        onActivated: moveContentsDialog.open()
        enabled: projectType === Project.LayeredImageType && canvasHasActiveFocus
    }

    Shortcut {
        objectName: "gridVisibleShortcut"
        sequence: settings.gridVisibleShortcut
        onActivated: settings.gridVisible = !settings.gridVisible
    }

    Shortcut {
        objectName: "rulersVisibleShortcut"
        sequence: settings.rulersVisibleShortcut
        onActivated: settings.rulersVisible = !settings.rulersVisible
    }

    Shortcut {
        objectName: "guidesVisibleShortcut"
        sequence: settings.guidesVisibleShortcut
        onActivated: settings.guidesVisible = !settings.guidesVisible
    }

    Shortcut {
        objectName: "splitScreenShortcut"
        sequence: settings.splitScreenShortcut
        onActivated: canvas.splitScreen = !canvas.splitScreen
        enabled: canvasHasActiveFocus
    }

    Shortcut {
        objectName: "splitterLockedShortcut"
        sequence: settings.splitterLockedShortcut
        onActivated: canvas.splitter.enabled = !canvas.splitter.enabled
        enabled: canvasHasActiveFocus
    }

    Shortcut {
        objectName: "centreShortcut"
        sequence: settings.centreShortcut
        onActivated: canvas.centreView()
        enabled: canvasHasActiveFocus
    }

    Shortcut {
        objectName: "zoomInShortcut"
        sequence: settings.zoomInShortcut
        onActivated: canvas.zoomIn()
        enabled: canvasHasActiveFocus
    }

    Shortcut {
        objectName: "zoomOutShortcut"
        sequence: settings.zoomOutShortcut
        onActivated: canvas.zoomOut()
        enabled: canvasHasActiveFocus
    }

    Shortcut {
        objectName: "animationPlaybackShortcut"
        sequence: settings.animationPlaybackShortcut
        onActivated: project.usingAnimation = !project.usingAnimation
        enabled:  isImageProjectType && canvasHasActiveFocus
    }

    Shortcut {
        objectName: "optionsShortcut"
        sequence: settings.optionsShortcut
        onActivated: optionsDialog.open()
        enabled: canvasHasActiveFocus
    }

    Shortcut {
        objectName: "penToolShortcut"
        sequence: settings.penToolShortcut
        onActivated: canvas.tool = ImageCanvas.PenTool
    }

    Shortcut {
        objectName: "eyeDropperToolShortcut"
        sequence: settings.eyeDropperToolShortcut
        onActivated: canvas.tool = ImageCanvas.EyeDropperTool
    }

    Shortcut {
        objectName: "fillToolShortcut"
        sequence: settings.fillToolShortcut
        onActivated: canvas.tool = canvas.lastFillToolUsed
    }

    Shortcut {
        objectName: "cycleFillToolsShortcut"
        sequence: "Shift+" + settings.fillToolShortcut
        onActivated: canvas.tool = (canvas.lastFillToolUsed === ImageCanvas.FillTool
            ? ImageCanvas.TexturedFillTool : ImageCanvas.FillTool)
    }

    Shortcut {
        objectName: "eraserToolShortcut"
        sequence: settings.eraserToolShortcut
        onActivated: canvas.tool = ImageCanvas.EraserTool
    }

    Shortcut {
        objectName: "selectionToolShortcut"
        sequence: settings.selectionToolShortcut
        onActivated: canvas.tool = ImageCanvas.SelectionTool
    }

    Shortcut {
        objectName: "toolModeShortcut"
        sequence: settings.toolModeShortcut
        enabled: projectType === Project.TilesetType
        onActivated: canvas.mode = (canvas.mode === TileCanvas.TileMode ? TileCanvas.PixelMode : TileCanvas.TileMode)
    }

    Shortcut {
        objectName: "decreaseToolSizeShortcut"
        sequence: settings.decreaseToolSizeShortcut
        onActivated: --canvas.toolSize
    }

    Shortcut {
        objectName: "increaseToolSizeShortcut"
        sequence: settings.increaseToolSizeShortcut
        onActivated: ++canvas.toolSize
    }

    Shortcut {
        objectName: "swatchLeftShortcut"
        sequence: settings.swatchLeftShortcut
        enabled: projectType === Project.TilesetType
        onActivated: canvas.swatchLeft()
    }

    Shortcut {
        objectName: "swatchRightShortcut"
        sequence: settings.swatchRightShortcut
        enabled: projectType === Project.TilesetType
        onActivated: canvas.swatchRight()
    }

    Shortcut {
        objectName: "swatchUpShortcut"
        sequence: settings.swatchUpShortcut
        enabled: projectType === Project.TilesetType
        onActivated: canvas.swatchUp()
    }

    Shortcut {
        objectName: "swatchDownShortcut"
        sequence: settings.swatchDownShortcut
        enabled: projectType === Project.TilesetType
        onActivated: canvas.swatchDown()
    }
}
