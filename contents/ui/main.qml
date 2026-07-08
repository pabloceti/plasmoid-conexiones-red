import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.plasmoid 2.0

PlasmoidItem {
    id: root

    property bool loading: false
    property string errorMessage: ""
    property string lastUpdated: ""
    property string backendScript: String(Qt.resolvedUrl("../scripts/network_table.py")).replace("file://", "")
    property int refreshToken: 0
    property string backendCommand: "python3 " + shellQuote(backendScript) + " --nonce " + refreshToken
    property string sortColumn: "ipDestino"
    property bool sortAscending: true

    ListModel {
        id: connectionsModel
    }

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'"
    }

    function compareValues(left, right) {
        if (left === right) {
            return 0
        }

        if (left === undefined || left === null) {
            return 1
        }

        if (right === undefined || right === null) {
            return -1
        }

        var leftText = String(left).toLowerCase()
        var rightText = String(right).toLowerCase()
        if (leftText < rightText) {
            return -1
        }
        if (leftText > rightText) {
            return 1
        }
        return 0
    }

    function sortItems(items) {
        items.sort(function(left, right) {
            var comparison = 0

            if (sortColumn === "puerto") {
                comparison = compareValues(Number(left.puertoDestino), Number(right.puertoDestino))
            } else if (sortColumn === "estado") {
                comparison = compareValues(left.estado, right.estado)
            } else if (sortColumn === "proceso") {
                comparison = compareValues(left.proceso, right.proceso)
            } else if (sortColumn === "empresa") {
                comparison = compareValues(left.empresa, right.empresa)
            } else if (sortColumn === "paisOrigen") {
                comparison = compareValues(left.paisOrigen, right.paisOrigen)
            } else if (sortColumn === "paisDestino") {
                comparison = compareValues(left.paisDestino, right.paisDestino)
            } else {
                comparison = compareValues(left.ipDestino, right.ipDestino)
            }

            return sortAscending ? comparison : -comparison
        })

        return items
    }

    function toggleSort(columnName) {
        if (sortColumn === columnName) {
            sortAscending = !sortAscending
        } else {
            sortColumn = columnName
            sortAscending = true
        }

        refreshConnections()
    }

    function refreshConnections() {
        loading = true
        errorMessage = ""
        refreshToken += 1
        execSource.connectedSources = [backendCommand]
    }

    function updateModel(payload) {
        connectionsModel.clear()

        const items = payload && payload.connections ? payload.connections : []
        const sortedItems = sortItems(items.slice())

        for (let i = 0; i < sortedItems.length; ++i) {
            const item = sortedItems[i]
            connectionsModel.append({
                ipOrigen: item.ip_origen || "",
                ipDestino: item.ip_destino || "",
                puertoOrigen: item.puerto_origen !== undefined ? item.puerto_origen : "",
                puertoDestino: item.puerto !== undefined ? item.puerto : "",
                empresa: item.empresa || "",
                paisOrigen: item.pais_origen || "",
                paisDestino: item.pais_destino || item.pais || "",
                proceso: item.proceso || "",
                procesoComando: item.proceso_comando || "",
                pid: item.pid !== undefined ? item.pid : "",
                estado: item.estado || ""
            })
        }

        lastUpdated = payload && payload.generated_at ? payload.generated_at : ""
    }

    compactRepresentation: Item {
        implicitWidth: 28
        implicitHeight: 28

        PlasmaCore.IconItem {
            anchors.centerIn: parent
            width: 22
            height: 22
            source: "network-workgroup"
        }
    }

    fullRepresentation: Item {
        id: panel
        implicitWidth: 980
        implicitHeight: 560

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                PlasmaComponents3.Label {
                    text: "Conexiones de red"
                    font.pixelSize: 18
                    font.bold: true
                    Layout.fillWidth: true
                }

                PlasmaComponents3.Label {
                    text: loading ? "Actualizando..." : (lastUpdated.length ? lastUpdated : "")
                    opacity: 0.75
                    horizontalAlignment: Text.AlignRight
                }

                PlasmaComponents3.Button {
                    text: "Refrescar"
                    icon.name: "view-refresh"
                    onClicked: root.refreshConnections()
                }
            }

            PlasmaComponents3.Label {
                text: errorMessage
                visible: errorMessage.length > 0
                color: PlasmaCore.Theme.negativeTextColor
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            PlasmaComponents3.Label {
                text: "Total de conexiones: " + connectionsModel.count
                opacity: 0.85
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: PlasmaCore.Theme.backgroundColor
                border.color: PlasmaCore.Theme.textColor
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        color: PlasmaCore.Theme.alternateBackgroundColor
                        radius: 6

                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            columns: 7
                            rowSpacing: 0
                            columnSpacing: 10

                            PlasmaComponents3.Button {
                                text: sortColumn === "ipOrigen" ? "IP origen " + (sortAscending ? "▲" : "▼") : "IP origen"
                                onClicked: root.toggleSort("ipOrigen")
                            }
                            PlasmaComponents3.Button {
                                text: sortColumn === "ipDestino" ? "IP destino " + (sortAscending ? "▲" : "▼") : "IP destino"
                                onClicked: root.toggleSort("ipDestino")
                            }
                            PlasmaComponents3.Button {
                                text: sortColumn === "puerto" ? "Puerto " + (sortAscending ? "▲" : "▼") : "Puerto"
                                onClicked: root.toggleSort("puerto")
                            }
                            PlasmaComponents3.Button {
                                text: sortColumn === "empresa" ? "Empresa " + (sortAscending ? "▲" : "▼") : "Empresa"
                                onClicked: root.toggleSort("empresa")
                            }
                            PlasmaComponents3.Button {
                                text: sortColumn === "paisOrigen" ? "País origen " + (sortAscending ? "▲" : "▼") : "País origen"
                                onClicked: root.toggleSort("paisOrigen")
                            }
                            PlasmaComponents3.Button {
                                text: sortColumn === "paisDestino" ? "País destino " + (sortAscending ? "▲" : "▼") : "País destino"
                                onClicked: root.toggleSort("paisDestino")
                            }
                            PlasmaComponents3.Button {
                                text: sortColumn === "proceso" ? "Proceso " + (sortAscending ? "▲" : "▼") : "Proceso"
                                onClicked: root.toggleSort("proceso")
                            }
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ListView {
                            id: listView
                            width: parent.width
                            height: parent.height
                            model: connectionsModel
                            spacing: 2
                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 42
                                radius: 6
                                color: index % 2 === 0 ? PlasmaCore.Theme.backgroundColor : PlasmaCore.Theme.alternateBackgroundColor

                                GridLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    columns: 7
                                    rowSpacing: 0
                                    columnSpacing: 10

                                    PlasmaComponents3.Label { text: ipOrigen; elide: Text.ElideRight; wrapMode: Text.NoWrap }
                                    PlasmaComponents3.Label { text: ipDestino; elide: Text.ElideRight; wrapMode: Text.NoWrap }
                                    PlasmaComponents3.Label { text: String(puertoDestino); elide: Text.ElideRight }
                                    PlasmaComponents3.Label { text: empresa; elide: Text.ElideRight; wrapMode: Text.NoWrap }
                                    PlasmaComponents3.Label { text: paisOrigen; elide: Text.ElideRight; wrapMode: Text.NoWrap }
                                    PlasmaComponents3.Label { text: paisDestino; elide: Text.ElideRight; wrapMode: Text.NoWrap }
                                    PlasmaComponents3.Label { text: proceso; elide: Text.ElideRight; wrapMode: Text.NoWrap }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    PlasmaCore.DataSource {
        id: execSource
        engine: "executable"

        onNewData: function(sourceName, data) {
            loading = false

            let raw = ""
            if (typeof data === "string") {
                raw = data
            } else if (data && data.stdout !== undefined) {
                raw = data.stdout
            } else if (data && data["stdout"] !== undefined) {
                raw = data["stdout"]
            } else if (data && data.data !== undefined) {
                raw = data.data
            }

            if (!raw || raw.trim().length === 0) {
                errorMessage = "No se recibieron datos del agente."
                execSource.disconnectSource(sourceName)
                return
            }

            try {
                const payload = JSON.parse(raw)
                updateModel(payload)
                errorMessage = ""
            } catch (error) {
                errorMessage = "No se pudo interpretar la respuesta: " + error
            }

            execSource.disconnectSource(sourceName)
        }
    }

    Component.onCompleted: refreshConnections()
}
