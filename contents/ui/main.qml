import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    property string fontFamily:        Plasmoid.configuration.fontFamily        || "Noto Sans"
    property int    fontSize:          Plasmoid.configuration.fontSize           || 14
    property bool   boldText:          Plasmoid.configuration.boldText           || false
    property bool   italicText:        Plasmoid.configuration.italicText         || false
    property int    bgStyle:           Plasmoid.configuration.bgStyle            || 1
    property int    bgOpacity:         Plasmoid.configuration.bgOpacity          || 50
    property bool   showTitle:         Plasmoid.configuration.showTitle          !== false

    property string jsonbinApiKey:     Plasmoid.configuration.jsonbinApiKey      || ""
    property string jsonbinBinId:      Plasmoid.configuration.jsonbinBinId       || ""
    property int    syncInterval:      Plasmoid.configuration.syncInterval       || 30

    property string colorTitle:        Plasmoid.configuration.colorTitle         || "#ffffff"
    property string colorTask:         Plasmoid.configuration.colorTask          || "#ffffff"
    property string colorTaskDone:     Plasmoid.configuration.colorTaskDone      || "#888888"
    property string colorPlaceholder:  Plasmoid.configuration.colorPlaceholder   || "#88ffffff"
    property string colorEmpty:        Plasmoid.configuration.colorEmpty         || "#66ffffff"
    property string colorDivider:      Plasmoid.configuration.colorDivider       || "#33ffffff"
    property string colorCheckBorder:  Plasmoid.configuration.colorCheckBorder   || "#aaffffff"
    property string colorCheckFill:    Plasmoid.configuration.colorCheckFill     || "#ffffff"
    property string colorCheckIcon:    Plasmoid.configuration.colorCheckIcon     || "#222222"
    property string colorInputBorder:  Plasmoid.configuration.colorInputBorder   || "#44ffffff"
    property string colorInputBg:      Plasmoid.configuration.colorInputBg       || "#18ffffff"
    property string colorBtnAdd:       Plasmoid.configuration.colorBtnAdd        || "#22ffffff"
    property string colorBtnAddBorder: Plasmoid.configuration.colorBtnAddBorder  || "#44ffffff"
    property string colorBtnAddIcon:   Plasmoid.configuration.colorBtnAddIcon    || "#ffffff"
    property string colorActionIcons:  Plasmoid.configuration.colorActionIcons   || "#aaffffff"
    property string colorHoverBg:      Plasmoid.configuration.colorHoverBg       || "#11ffffff"

    property bool   syncing:    false
    property string syncStatus: ""
    property string lastSynced: ""

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    ListModel { id: taskModel }

    Timer {
        interval: root.syncInterval * 1000; repeat: true
        running: root.jsonbinApiKey !== "" && root.jsonbinBinId !== ""
        onTriggered: root.pullFromCloud()
    }

    function serializeTasks() {
        var arr = []
        for (var i = 0; i < taskModel.count; i++)
            arr.push({ text: taskModel.get(i).text, done: taskModel.get(i).done })
        return arr
    }

    function saveTasks() {
        var arr = serializeTasks()
        Plasmoid.configuration.tasksJson = JSON.stringify(arr)
        if (root.jsonbinApiKey !== "" && root.jsonbinBinId !== "")
            pushToCloud(arr)
    }

    function pushToCloud(arr) {
        root.syncing = true
        var xhr = new XMLHttpRequest()
        xhr.open("PUT", "https://api.jsonbin.io/v3/b/" + root.jsonbinBinId, true)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.setRequestHeader("X-Master-Key", root.jsonbinApiKey)
        xhr.setRequestHeader("X-Bin-Versioning", "false")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            root.syncing = false
            if (xhr.status === 200) {
                root.syncStatus = "ok"
                var d = new Date()
                root.lastSynced = String(d.getHours()).padStart(2,"0") + ":" + String(d.getMinutes()).padStart(2,"0")
            } else {
                root.syncStatus = "error"
                console.warn("JSONBin push error:", xhr.status, xhr.responseText)
            }
        }
        xhr.send(JSON.stringify({ tasks: arr }))
    }

    function pullFromCloud() {
        if (root.jsonbinApiKey === "" || root.jsonbinBinId === "") return
        root.syncing = true
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "https://api.jsonbin.io/v3/b/" + root.jsonbinBinId + "/latest", true)
        xhr.setRequestHeader("X-Master-Key", root.jsonbinApiKey)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            root.syncing = false
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText)
                    var arr = data.record.tasks || []
                    if (JSON.stringify(arr) === JSON.stringify(serializeTasks())) {
                        root.syncStatus = "ok"; return
                    }
                    taskModel.clear()
                    for (var i = 0; i < arr.length; i++)
                        taskModel.append({ text: arr[i].text, done: arr[i].done === true })
                    Plasmoid.configuration.tasksJson = JSON.stringify(arr)
                    root.syncStatus = "ok"
                    var d = new Date()
                    root.lastSynced = String(d.getHours()).padStart(2,"0") + ":" + String(d.getMinutes()).padStart(2,"0")
                } catch(e) { root.syncStatus = "error" }
            } else {
                root.syncStatus = "error"
                console.warn("JSONBin pull error:", xhr.status)
            }
        }
        xhr.send()
    }

    function loadTasks() {
        var json = Plasmoid.configuration.tasksJson || "[]"
        try {
            var arr = JSON.parse(json)
            taskModel.clear()
            for (var i = 0; i < arr.length; i++)
                taskModel.append({ text: arr[i].text, done: arr[i].done === true })
        } catch(e) { taskModel.clear() }
        if (root.jsonbinApiKey !== "" && root.jsonbinBinId !== "") pullFromCloud()
    }

    Component.onCompleted: root.loadTasks()
    Connections {
        target: Plasmoid.configuration
        function onJsonbinBinIdChanged()  { root.loadTasks() }
        function onJsonbinApiKeyChanged() { root.loadTasks() }
    }

    fullRepresentation: Item {
        id: mainItem
        implicitWidth:  300
        implicitHeight: Math.max(100, taskColumn.implicitHeight + 28)

        property real bgAlpha: root.bgStyle === 2 ? 0 : (root.bgOpacity / 100)

        // ── Background ────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            radius: root.bgStyle === 2 ? 0 : 14
            color: {
                if (root.bgStyle === 0) return Qt.rgba(0.12, 0.12, 0.14, mainItem.bgAlpha)
                if (root.bgStyle === 1) return Qt.rgba(1, 1, 1, mainItem.bgAlpha * 0.18)
                return "transparent"
            }
            border.width: root.bgStyle === 2 ? 0 : 1
            border.color: root.bgStyle === 2 ? "transparent"
                        : Qt.rgba(1, 1, 1, Math.min(mainItem.bgAlpha + 0.05, 0.35))
            Behavior on color { ColorAnimation { duration: 200 } }
            Rectangle {
                visible: root.bgStyle === 1 && mainItem.bgAlpha > 0.05
                anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 1; leftMargin: 1; rightMargin: 1 }
                height: parent.height * 0.45; radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1,1,1, mainItem.bgAlpha * 0.12) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }

        ColumnLayout {
            id: taskColumn
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
            spacing: 6

            // ── Título ─────────────────────────────────────────
            RowLayout {
                Layout.topMargin: 4; spacing: 6
                visible: root.showTitle

                Kirigami.Icon {
                    source: "checkmark"; width: root.fontSize+4; height: root.fontSize+4
                    isMask: true; color: root.colorTitle
                }
                Text {
                    text: "To-Do"; color: root.colorTitle
                    font.family: root.fontFamily; font.pixelSize: root.fontSize + 2
                    font.bold: true; font.letterSpacing: 1
                    style: root.bgStyle === 2 ? Text.Outline : Text.Normal
                    styleColor: Qt.rgba(0,0,0,0.6)
                }

                Item { Layout.fillWidth: true }

                // Botão sync
                Rectangle {
                    width: 28; height: 28; radius: 7
                    visible: root.jsonbinApiKey !== "" && root.jsonbinBinId !== ""
                    HoverHandler { id: syncBtnHover }
                    color: root.syncing ? Qt.rgba(1,1,1,0.18) : syncBtnHover.hovered ? Qt.rgba(1,1,1,0.15) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Kirigami.Icon {
                        id: syncIcon
                        anchors.centerIn: parent
                        source: root.syncStatus === "error" ? "dialog-error" : "view-refresh"
                        width: 16; height: 16
                        isMask: true
                        color: root.syncing          ? root.colorTitle
                             : root.syncStatus === "ok"    ? "#4ade80"
                             : root.syncStatus === "error" ? "#f87171"
                             : root.colorTitle
                        Behavior on color { ColorAnimation { duration: 200 } }
                        RotationAnimator {
                            target: syncIcon; from: 0; to: 360
                            duration: 900; loops: Animation.Infinite
                            running: root.syncing
                        }
                    }

                    ToolTip.visible: syncBtnHover.hovered
                    ToolTip.delay: 400
                    ToolTip.text: root.syncing          ? "Sincronizando..."
                                : root.syncStatus === "ok"    ? "Sincronizado às " + root.lastSynced + "\nClique para atualizar"
                                : root.syncStatus === "error" ? "Erro — clique para tentar novamente"
                                : "Clique para sincronizar"

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        enabled: !root.syncing
                        onClicked: root.pullFromCloud()
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: root.colorDivider; visible: root.showTitle }

            // ── Input ──────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true; spacing: 6
                Layout.topMargin: root.showTitle ? 0 : 4

                TextField {
                    id: inputField
                    Layout.fillWidth: true
                    placeholderText: "Nova tarefa..."
                    leftPadding: 10; rightPadding: 10; topPadding: 7; bottomPadding: 7
                    background: Rectangle {
                        radius: 8; color: root.colorInputBg
                        border.color: inputField.activeFocus ? root.colorTitle : root.colorInputBorder
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                    color: root.colorTask
                    font.family: root.fontFamily; font.pixelSize: root.fontSize
                    font.bold: root.boldText; font.italic: root.italicText
                    placeholderTextColor: root.colorPlaceholder
                    selectionColor: Qt.rgba(1,1,1,0.3)
                    Keys.onReturnPressed: {
                        var t = text.trim(); if (!t) return
                        taskModel.append({ text: t, done: false }); text = ""
                        root.saveTasks()
                    }
                }

                Rectangle {
                    width: 34; height: 34; radius: 8
                    color: addMouse.pressed ? Qt.rgba(1,1,1,0.35) : addMouse.containsMouse ? Qt.rgba(1,1,1,0.22) : root.colorBtnAdd
                    border.color: root.colorBtnAddBorder; border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Kirigami.Icon {
                        anchors.centerIn: parent; source: "list-add"
                        width: 18; height: 18; isMask: true; color: root.colorBtnAddIcon
                    }
                    MouseArea {
                        id: addMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var t = inputField.text.trim(); if (!t) return
                            taskModel.append({ text: t, done: false }); inputField.text = ""
                            root.saveTasks()
                        }
                    }
                }
            }

            // ── Lista ──────────────────────────────────────────
            Repeater {
                model: taskModel
                delegate: Item {
                    id: taskDelegate
                    property int  taskIndex: index
                    property bool editing:   false

                    Layout.fillWidth: true
                    implicitHeight: editing ? editRow.implicitHeight + 10
                                           : taskRow.implicitHeight + 10

                    HoverHandler { id: rowHover }
                    Rectangle {
                        anchors.fill: parent; radius: 7
                        color: rowHover.hovered ? root.colorHoverBg : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    // ── Modo normal ────────────────────────────
                    RowLayout {
                        id: taskRow
                        visible: !taskDelegate.editing
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 6; rightMargin: 6 }
                        spacing: 8

                        // Checkbox
                        Rectangle {
                            width: 20; height: 20; radius: 5
                            color: model.done ? root.colorCheckFill : "transparent"
                            border.color: root.colorCheckBorder; border.width: 1.5
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Kirigami.Icon {
                                anchors.centerIn: parent; source: "checkmark"
                                width: 13; height: 13; isMask: true
                                color: root.colorCheckIcon
                                visible: model.done
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    taskModel.setProperty(taskDelegate.taskIndex, "done", !taskModel.get(taskDelegate.taskIndex).done)
                                    root.saveTasks()
                                }
                            }
                        }

                        // Texto — duplo clique para editar
                        Text {
                            Layout.fillWidth: true
                            text: model.text
                            color: model.done ? root.colorTaskDone : root.colorTask
                            font.family: root.fontFamily; font.pixelSize: root.fontSize
                            font.bold: root.boldText; font.italic: root.italicText
                            font.strikeout: model.done
                            wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight
                            style: root.bgStyle === 2 ? Text.Outline : Text.Normal
                            styleColor: Qt.rgba(0,0,0,0.5)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked:       { taskModel.setProperty(taskDelegate.taskIndex, "done", !taskModel.get(taskDelegate.taskIndex).done); root.saveTasks() }
                                onDoubleClicked: { taskDelegate.editing = true }
                            }
                        }

                        // Botões de ação — cada um declarado individualmente
                        // para evitar conflito de 'index' com Repeater interno
                        Row {
                            spacing: 2
                            opacity: rowHover.hovered ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            // Editar
                            Rectangle {
                                width: 24; height: 24; radius: 6
                                HoverHandler { id: hEdit }
                                color: hEdit.hovered ? Qt.rgba(1,1,1,0.18) : "transparent"
                                Behavior on color { ColorAnimation { duration: 80 } }
                                Kirigami.Icon {
                                    anchors.centerIn: parent; source: "document-edit"
                                    width: 14; height: 14; isMask: true; color: root.colorActionIcons
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: { taskDelegate.editing = true }
                                }
                            }

                            // Mover cima
                            Rectangle {
                                width: 24; height: 24; radius: 6
                                HoverHandler { id: hUp }
                                color: hUp.hovered ? Qt.rgba(1,1,1,0.18) : "transparent"
                                Behavior on color { ColorAnimation { duration: 80 } }
                                Kirigami.Icon {
                                    anchors.centerIn: parent; source: "arrow-up"
                                    width: 14; height: 14; isMask: true; color: root.colorActionIcons
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var i = taskDelegate.taskIndex
                                        if (i > 0) { taskModel.move(i, i-1, 1); root.saveTasks() }
                                    }
                                }
                            }

                            // Mover baixo
                            Rectangle {
                                width: 24; height: 24; radius: 6
                                HoverHandler { id: hDown }
                                color: hDown.hovered ? Qt.rgba(1,1,1,0.18) : "transparent"
                                Behavior on color { ColorAnimation { duration: 80 } }
                                Kirigami.Icon {
                                    anchors.centerIn: parent; source: "arrow-down"
                                    width: 14; height: 14; isMask: true; color: root.colorActionIcons
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var i = taskDelegate.taskIndex
                                        if (i < taskModel.count-1) { taskModel.move(i, i+1, 1); root.saveTasks() }
                                    }
                                }
                            }

                            // Deletar
                            Rectangle {
                                width: 24; height: 24; radius: 6
                                HoverHandler { id: hDel }
                                color: hDel.hovered ? Qt.rgba(1,0.2,0.2,0.45) : "transparent"
                                Behavior on color { ColorAnimation { duration: 80 } }
                                Kirigami.Icon {
                                    anchors.centerIn: parent; source: "edit-delete"
                                    width: 14; height: 14; isMask: true
                                    color: hDel.hovered ? "#ff7070" : root.colorActionIcons
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        taskModel.remove(taskDelegate.taskIndex)
                                        root.saveTasks()
                                    }
                                }
                            }
                        }
                    }

                    // ── Modo edição inline ─────────────────────
                    RowLayout {
                        id: editRow
                        visible: taskDelegate.editing
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 6; rightMargin: 6 }
                        spacing: 6

                        TextField {
                            id: editField
                            Layout.fillWidth: true
                            text: model.text
                            leftPadding: 8; rightPadding: 8; topPadding: 6; bottomPadding: 6
                            background: Rectangle {
                                radius: 7; color: root.colorInputBg
                                border.color: editField.activeFocus ? root.colorTitle : root.colorInputBorder
                                border.width: 1
                            }
                            color: root.colorTask
                            font.family: root.fontFamily; font.pixelSize: root.fontSize
                            selectionColor: Qt.rgba(1,1,1,0.3)
                            onVisibleChanged: if (visible) { forceActiveFocus(); selectAll() }
                            Keys.onReturnPressed: confirmEdit()
                            Keys.onEscapePressed: taskDelegate.editing = false
                            function confirmEdit() {
                                var t = text.trim()
                                if (t !== "") taskModel.setProperty(taskDelegate.taskIndex, "text", t)
                                taskDelegate.editing = false
                                root.saveTasks()
                            }
                        }

                        // Confirmar edição
                        Rectangle {
                            width: 28; height: 28; radius: 7
                            HoverHandler { id: okHover }
                            color: okHover.hovered ? Qt.rgba(0.2,0.8,0.4,0.4) : Qt.rgba(1,1,1,0.12)
                            border.color: root.colorInputBorder; border.width: 1
                            Kirigami.Icon {
                                anchors.centerIn: parent; source: "checkmark"
                                width: 14; height: 14; isMask: true
                                color: okHover.hovered ? "#4ade80" : root.colorActionIcons
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: editField.confirmEdit()
                            }
                        }

                        // Cancelar edição
                        Rectangle {
                            width: 28; height: 28; radius: 7
                            HoverHandler { id: cancelHover }
                            color: cancelHover.hovered ? Qt.rgba(1,0.2,0.2,0.35) : Qt.rgba(1,1,1,0.12)
                            border.color: root.colorInputBorder; border.width: 1
                            Kirigami.Icon {
                                anchors.centerIn: parent; source: "dialog-cancel"
                                width: 14; height: 14; isMask: true
                                color: cancelHover.hovered ? "#f87171" : root.colorActionIcons
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: taskDelegate.editing = false
                            }
                        }
                    }
                }
            }

            // Empty state
            Text {
                Layout.fillWidth: true; Layout.topMargin: 12; Layout.bottomMargin: 8
                text: "Nenhuma tarefa ainda 🎉"
                color: root.colorEmpty
                font.family: root.fontFamily; font.pixelSize: root.fontSize - 1; font.italic: true
                horizontalAlignment: Text.AlignHCenter
                visible: taskModel.count === 0
            }
        }
    }
}
