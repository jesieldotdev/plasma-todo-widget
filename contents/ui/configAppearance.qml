import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQC

Item {
    id: root
    implicitWidth: 450
    implicitHeight: 600

    property alias cfg_fontFamily:        fontCombo.currentText
    property alias cfg_fontSize:          fontSizeBox.value
    property alias cfg_boldText:          boldCheck.checked
    property alias cfg_italicText:        italicCheck.checked
    property alias cfg_showTitle:         showTitleCheck.checked
    property int   cfg_bgStyle:           1
    property alias cfg_bgOpacity:         opacitySlider.value

    property alias cfg_jsonbinApiKey:     apiKeyField.text
    property alias cfg_jsonbinBinId:      binIdField.text
    property alias cfg_syncInterval:      syncIntervalBox.value

    property alias cfg_colorTitle:        colorTitle.color
    property alias cfg_colorTask:         colorTask.color
    property alias cfg_colorTaskDone:     colorTaskDone.color
    property alias cfg_colorPlaceholder:  colorPlaceholder.color
    property alias cfg_colorEmpty:        colorEmpty.color
    property alias cfg_colorDivider:      colorDivider.color
    property alias cfg_colorCheckBorder:  colorCheckBorder.color
    property alias cfg_colorCheckFill:    colorCheckFill.color
    property alias cfg_colorCheckIcon:    colorCheckIcon.color
    property alias cfg_colorInputBorder:  colorInputBorder.color
    property alias cfg_colorInputBg:      colorInputBg.color
    property alias cfg_colorBtnAdd:       colorBtnAdd.color
    property alias cfg_colorBtnAddBorder: colorBtnAddBorder.color
    property alias cfg_colorBtnAddIcon:   colorBtnAddIcon.color
    property alias cfg_colorActionIcons:  colorActionIcons.color
    property alias cfg_colorHoverBg:      colorHoverBg.color

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

        Kirigami.FormLayout {
            id: form
            width: root.width - 20

            // ── Sincronização JSONBin ──────────────────────────
            Kirigami.Separator { Kirigami.FormData.label: "Sincronização (JSONBin.io)"; Kirigami.FormData.isSection: true }

            Label {
                Layout.maximumWidth: 340
                wrapMode: Text.WordWrap
                font.pixelSize: 11
                opacity: 0.8
                text: "Crie uma conta grátis em jsonbin.io, crie um Bin e cole as credenciais abaixo. Todos os widgets com o mesmo Bin ID ficam sincronizados em tempo real."
            }

            // Link rápido
            Label {
                text: "<a href='https://jsonbin.io'>Abrir jsonbin.io ↗</a>"
                font.pixelSize: 11
                onLinkActivated: Qt.openUrlExternally(link)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.openUrlExternally("https://jsonbin.io") }
            }

            // API Key
            RowLayout {
                Kirigami.FormData.label: "API Key:"
                spacing: 6
                TextField {
                    id: apiKeyField
                    implicitWidth: 260
                    placeholderText: "$2a$10$..."
                    echoMode: showKey.checked ? TextInput.Normal : TextInput.Password
                    font.pixelSize: 11
                    font.family: "monospace"
                }
                CheckBox {
                    id: showKey
                    text: "mostrar"
                    font.pixelSize: 11
                }
            }

            // Bin ID
            TextField {
                id: binIdField
                Kirigami.FormData.label: "Bin ID:"
                implicitWidth: 200
                placeholderText: "64a3f2..."
                font.pixelSize: 11
                font.family: "monospace"
            }

            // Intervalo de sync
            RowLayout {
                Kirigami.FormData.label: "Sync a cada:"
                spacing: 6
                SpinBox {
                    id: syncIntervalBox
                    from: 10; to: 300; value: 30; stepSize: 10
                }
                Label { text: "segundos"; font.pixelSize: 11; opacity: 0.7 }
            }

            // Status
            Label {
                visible: apiKeyField.text !== "" && binIdField.text !== ""
                text: "✓ Sync ativo — widget sincronizará automaticamente."
                font.pixelSize: 11
                color: Kirigami.Theme.positiveTextColor
            }
            Label {
                visible: apiKeyField.text === "" || binIdField.text === ""
                text: "⚠ Sem sync — tarefas salvas só localmente."
                font.pixelSize: 11
                opacity: 0.6
            }

            // Como configurar
            Kirigami.Separator { Kirigami.FormData.label: "Como configurar"; Kirigami.FormData.isSection: true }
            Label {
                Layout.maximumWidth: 340
                wrapMode: Text.WordWrap
                font.pixelSize: 11
                opacity: 0.75
                text: "1. Acesse jsonbin.io e crie uma conta\n" +
                      "2. Vá em API Keys → gere uma Master Key\n" +
                      "3. Clique em 'New Bin' e crie um bin vazio: {}\n" +
                      "4. Copie o Bin ID da URL (ex: 64a3f2c...)\n" +
                      "5. Cole a Master Key e o Bin ID acima\n" +
                      "6. Repita nos outros monitores com os mesmos valores"
            }

            // ── Layout ─────────────────────────────────────────
            Kirigami.Separator { Kirigami.FormData.label: "Layout"; Kirigami.FormData.isSection: true }

            CheckBox {
                id: showTitleCheck
                Kirigami.FormData.label: "Título:"
                text: "Mostrar título 'To-Do'"
                checked: true
            }

            // ── Fundo ──────────────────────────────────────────
            Kirigami.Separator { Kirigami.FormData.label: "Fundo"; Kirigami.FormData.isSection: true }

            ColumnLayout {
                Kirigami.FormData.label: "Estilo:"; spacing: 8
                Repeater {
                    model: [
                        { label: "⬛  Opaco",            val: 0 },
                        { label: "🪟  Glass",             val: 1 },
                        { label: "👁  100% Transparente", val: 2 }
                    ]
                    delegate: RadioButton {
                        text: modelData.label
                        checked: root.cfg_bgStyle === modelData.val
                        onClicked: root.cfg_bgStyle = modelData.val
                    }
                }
            }

            RowLayout {
                Kirigami.FormData.label: "Intensidade:"
                visible: root.cfg_bgStyle !== 2; spacing: 8
                Slider { id: opacitySlider; from: 5; to: 100; stepSize: 1; value: 50; implicitWidth: 160 }
                Text { text: opacitySlider.value + "%"; color: Kirigami.Theme.textColor; font.pixelSize: 12; font.bold: true; verticalAlignment: Text.AlignVCenter }
            }

            // ── Fonte ──────────────────────────────────────────
            Kirigami.Separator { Kirigami.FormData.label: "Fonte"; Kirigami.FormData.isSection: true }

            ComboBox {
                id: fontCombo; Kirigami.FormData.label: "Família:"
                model: Qt.fontFamilies()
                currentIndex: { var i = model.indexOf(root.cfg_fontFamily); return i >= 0 ? i : model.indexOf("Noto Sans") }
                onCurrentTextChanged: root.cfg_fontFamily = currentText
            }
            SpinBox { id: fontSizeBox; Kirigami.FormData.label: "Tamanho:"; from: 8; to: 48; value: 14 }
            CheckBox { id: boldCheck;   Kirigami.FormData.label: "Negrito:";  text: "Ativar" }
            CheckBox { id: italicCheck; Kirigami.FormData.label: "Itálico:";  text: "Ativar" }

            // ── Cores ──────────────────────────────────────────
            Kirigami.Separator { Kirigami.FormData.label: "Cores — Texto"; Kirigami.FormData.isSection: true }
            KQC.ColorButton { id: colorTitle;       Kirigami.FormData.label: "Título:";           color: "#ffffff";   showAlphaChannel: true }
            KQC.ColorButton { id: colorTask;        Kirigami.FormData.label: "Tarefa normal:";    color: "#ffffff";   showAlphaChannel: true }
            KQC.ColorButton { id: colorTaskDone;    Kirigami.FormData.label: "Tarefa concluída:"; color: "#888888";   showAlphaChannel: true }
            KQC.ColorButton { id: colorPlaceholder; Kirigami.FormData.label: "Placeholder:";      color: "#88ffffff"; showAlphaChannel: true }
            KQC.ColorButton { id: colorEmpty;       Kirigami.FormData.label: "Texto vazio:";      color: "#66ffffff"; showAlphaChannel: true }

            Kirigami.Separator { Kirigami.FormData.label: "Cores — Checkbox"; Kirigami.FormData.isSection: true }
            KQC.ColorButton { id: colorCheckBorder; Kirigami.FormData.label: "Borda:";          color: "#aaffffff"; showAlphaChannel: true }
            KQC.ColorButton { id: colorCheckFill;   Kirigami.FormData.label: "Preenchimento:";  color: "#ffffff";   showAlphaChannel: true }
            KQC.ColorButton { id: colorCheckIcon;   Kirigami.FormData.label: "Ícone ✓:";        color: "#222222";   showAlphaChannel: true }

            Kirigami.Separator { Kirigami.FormData.label: "Cores — Input"; Kirigami.FormData.isSection: true }
            KQC.ColorButton { id: colorInputBg;     Kirigami.FormData.label: "Fundo:"; color: "#18ffffff"; showAlphaChannel: true }
            KQC.ColorButton { id: colorInputBorder; Kirigami.FormData.label: "Borda:"; color: "#44ffffff"; showAlphaChannel: true }

            Kirigami.Separator { Kirigami.FormData.label: "Cores — Botão +"; Kirigami.FormData.isSection: true }
            KQC.ColorButton { id: colorBtnAdd;       Kirigami.FormData.label: "Fundo:"; color: "#22ffffff"; showAlphaChannel: true }
            KQC.ColorButton { id: colorBtnAddBorder; Kirigami.FormData.label: "Borda:"; color: "#44ffffff"; showAlphaChannel: true }
            KQC.ColorButton { id: colorBtnAddIcon;   Kirigami.FormData.label: "Ícone:"; color: "#ffffff";   showAlphaChannel: true }

            Kirigami.Separator { Kirigami.FormData.label: "Cores — Outros"; Kirigami.FormData.isSection: true }
            KQC.ColorButton { id: colorDivider;     Kirigami.FormData.label: "Linha divisória:"; color: "#33ffffff"; showAlphaChannel: true }
            KQC.ColorButton { id: colorHoverBg;     Kirigami.FormData.label: "Hover tarefa:";    color: "#11ffffff"; showAlphaChannel: true }
            KQC.ColorButton { id: colorActionIcons; Kirigami.FormData.label: "Ícones de ação:";  color: "#aaffffff"; showAlphaChannel: true }

            // ── Presets ────────────────────────────────────────
            Kirigami.Separator { Kirigami.FormData.label: "Presets rápidos"; Kirigami.FormData.isSection: true }

            Flow {
                spacing: 8; Layout.fillWidth: true
                Repeater {
                    model: [
                        { name: "🤍 Branco",  title:"#ffffff", task:"#ffffff", done:"#888888", ph:"#88ffffff", empty:"#55ffffff", div:"#33ffffff", cborder:"#aaffffff", cfill:"#ffffff", cicon:"#222222", ibg:"#18ffffff", iborder:"#44ffffff", btn:"#22ffffff", btnb:"#44ffffff", btni:"#ffffff", hover:"#11ffffff", icons:"#aaffffff" },
                        { name: "🖤 Smoke",   title:"#000000", task:"#111111", done:"#777777", ph:"#88000000", empty:"#66000000", div:"#33000000", cborder:"#aa000000", cfill:"#333333", cicon:"#ffffff",  ibg:"#18000000", iborder:"#44000000", btn:"#22000000", btnb:"#44000000", btni:"#000000", hover:"#11000000", icons:"#aa000000" },
                        { name: "💙 Neon",    title:"#00cfff", task:"#cceeff", done:"#446677", ph:"#8800cfff", empty:"#6600cfff", div:"#3300cfff", cborder:"#aa00cfff", cfill:"#00cfff", cicon:"#003344", ibg:"#1800cfff", iborder:"#4400cfff", btn:"#2200cfff", btnb:"#4400cfff", btni:"#00cfff", hover:"#1100cfff", icons:"#aa00cfff" },
                        { name: "🌸 Rosa",    title:"#ffb3d1", task:"#ffe0ec", done:"#886677", ph:"#88ffb3d1", empty:"#66ffb3d1", div:"#33ffb3d1", cborder:"#aaffb3d1", cfill:"#ffb3d1", cicon:"#663344", ibg:"#18ffb3d1", iborder:"#44ffb3d1", btn:"#22ffb3d1", btnb:"#44ffb3d1", btni:"#ffb3d1", hover:"#11ffb3d1", icons:"#aaffb3d1" },
                        { name: "🌙 Roxo",    title:"#c084fc", task:"#e9d5ff", done:"#7c3aed", ph:"#88c084fc", empty:"#66c084fc", div:"#33c084fc", cborder:"#aac084fc", cfill:"#c084fc", cicon:"#1e003a", ibg:"#18c084fc", iborder:"#44c084fc", btn:"#22c084fc", btnb:"#44c084fc", btni:"#c084fc", hover:"#11c084fc", icons:"#aac084fc" },
                        { name: "🍊 Laranja", title:"#fb923c", task:"#fed7aa", done:"#7c3a00", ph:"#88fb923c", empty:"#66fb923c", div:"#33fb923c", cborder:"#aafb923c", cfill:"#fb923c", cicon:"#3a1500", ibg:"#18fb923c", iborder:"#44fb923c", btn:"#22fb923c", btnb:"#44fb923c", btni:"#fb923c", hover:"#11fb923c", icons:"#aafb923c" },
                        { name: "🌿 Verde",   title:"#4ade80", task:"#bbf7d0", done:"#166534", ph:"#884ade80", empty:"#664ade80", div:"#334ade80", cborder:"#aa4ade80", cfill:"#4ade80", cicon:"#052e16", ibg:"#184ade80", iborder:"#444ade80", btn:"#224ade80", btnb:"#444ade80", btni:"#4ade80", hover:"#114ade80", icons:"#aa4ade80" },
                    ]
                    delegate: Button {
                        text: modelData.name
                        onClicked: {
                            // FIX 4: presets só mudam cores, nunca a fonte
                            colorTitle.color        = modelData.title
                            colorTask.color         = modelData.task
                            colorTaskDone.color     = modelData.done
                            colorPlaceholder.color  = modelData.ph
                            colorEmpty.color        = modelData.empty
                            colorDivider.color      = modelData.div
                            colorCheckBorder.color  = modelData.cborder
                            colorCheckFill.color    = modelData.cfill
                            colorCheckIcon.color    = modelData.cicon
                            colorInputBg.color      = modelData.ibg
                            colorInputBorder.color  = modelData.iborder
                            colorBtnAdd.color       = modelData.btn
                            colorBtnAddBorder.color = modelData.btnb
                            colorBtnAddIcon.color   = modelData.btni
                            colorHoverBg.color      = modelData.hover
                            colorActionIcons.color  = modelData.icons
                            // fontFamily e fontSize são preservados intencionalmente
                        }
                    }
                }
            }

            Item { height: 20 }
        }
    }
}
