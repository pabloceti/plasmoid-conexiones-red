import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.plasmoid

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
    property bool autoRefreshEnabled: Plasmoid.configuration.autoRefreshEnabled === undefined ? true : Boolean(Plasmoid.configuration.autoRefreshEnabled)
    property int refreshIntervalSeconds: {
        const configured = Number(Plasmoid.configuration.refreshIntervalSeconds)
        if (!isNaN(configured) && configured >= 5) {
            return configured
        }
        return 20
    }
    property int colIpOrigenWidth: 140
    property int colIpDestinoWidth: 170
    property int colPuertoWidth: 80
    property int colEmpresaWidth: 140
    property int colPaisOrigenWidth: 100
    property int colPaisDestinoWidth: 100
    property int colProcesoWidth: 140

    ListModel {
        id: connectionsModel
    }

    Timer {
        id: autoRefreshTimer
        interval: root.refreshIntervalSeconds * 1000
        repeat: true
        running: root.autoRefreshEnabled
        triggeredOnStart: false

        onTriggered: {
            if (!root.loading) {
                root.refreshConnections()
            }
        }
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
            var comparison = compareValues(getSortValue(left), getSortValue(right))

            return sortAscending ? comparison : -comparison
        })

        return items
    }

    function readField(item, camelKey, snakeKey) {
        if (item[camelKey] !== undefined) {
            return item[camelKey]
        }
        if (snakeKey !== "" && item[snakeKey] !== undefined) {
            return item[snakeKey]
        }
        return ""
    }

    function getSortValue(item) {
        if (sortColumn === "puerto") {
            const portValue = readField(item, "puertoDestino", "puerto")
            return Number(portValue)
        }
        if (sortColumn === "ipOrigen") {
            return readField(item, "ipOrigen", "ip_origen")
        }
        if (sortColumn === "ipDestino") {
            return readField(item, "ipDestino", "ip_destino")
        }
        if (sortColumn === "empresa") {
            return readField(item, "empresa", "empresa")
        }
        if (sortColumn === "paisOrigen") {
            return readField(item, "paisOrigen", "pais_origen")
        }
        if (sortColumn === "paisDestino") {
            const country = readField(item, "paisDestino", "pais_destino")
            if (country !== "") {
                return country
            }
            return readField(item, "pais", "pais")
        }
        if (sortColumn === "proceso") {
            return readField(item, "proceso", "proceso")
        }
        return readField(item, "ipDestino", "ip_destino")
    }

    function sortCurrentModel() {
        const items = []
        for (let i = 0; i < connectionsModel.count; ++i) {
            const row = connectionsModel.get(i)
            items.push({
                ipOrigen: row.ipOrigen !== undefined && row.ipOrigen !== null ? row.ipOrigen : "",
                ipDestino: row.ipDestino !== undefined && row.ipDestino !== null ? row.ipDestino : "",
                puertoOrigen: row.puertoOrigen !== undefined && row.puertoOrigen !== null ? row.puertoOrigen : "",
                puertoDestino: row.puertoDestino !== undefined && row.puertoDestino !== null ? row.puertoDestino : "",
                empresa: row.empresa !== undefined && row.empresa !== null ? row.empresa : "",
                paisOrigen: row.paisOrigen !== undefined && row.paisOrigen !== null ? row.paisOrigen : "",
                paisDestino: row.paisDestino !== undefined && row.paisDestino !== null ? row.paisDestino : "",
                proceso: row.proceso !== undefined && row.proceso !== null ? row.proceso : "",
                procesoComando: row.procesoComando !== undefined && row.procesoComando !== null ? row.procesoComando : "",
                pid: row.pid !== undefined && row.pid !== null ? Number(row.pid) : -1,
                estado: row.estado !== undefined && row.estado !== null ? row.estado : ""
            })
        }

        const sortedItems = sortItems(items)
        connectionsModel.clear()
        for (let j = 0; j < sortedItems.length; ++j) {
            connectionsModel.append(sortedItems[j])
        }
    }

    function toggleSort(columnName) {
        if (sortColumn === columnName) {
            sortAscending = !sortAscending
        } else {
            sortColumn = columnName
            sortAscending = true
        }

        sortCurrentModel()
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
                puertoOrigen: item.puerto_origen !== undefined && item.puerto_origen !== null ? item.puerto_origen : "",
                puertoDestino: item.puerto !== undefined && item.puerto !== null ? item.puerto : "",
                empresa: item.empresa || "",
                paisOrigen: item.pais_origen || "",
                paisDestino: item.pais_destino || item.pais || "",
                proceso: item.proceso || "",
                procesoComando: item.proceso_comando || "",
                pid: item.pid !== undefined && item.pid !== null ? Number(item.pid) : -1,
                estado: item.estado || ""
            })
        }

        lastUpdated = payload && payload.generated_at ? payload.generated_at : ""
    }

    compactRepresentation: Item {
        implicitWidth: 28
        implicitHeight: 28

        Kirigami.Icon {
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
                color: Kirigami.Theme.negativeTextColor
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
                color: Kirigami.Theme.backgroundColor
                border.color: Kirigami.Theme.textColor
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        color: Kirigami.Theme.alternateBackgroundColor
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
                                Layout.preferredWidth: root.colIpOrigenWidth
                            }
                            PlasmaComponents3.Button {
                                text: sortColumn === "ipDestino" ? "IP destino " + (sortAscending ? "▲" : "▼") : "IP destino"
                                onClicked: root.toggleSort("ipDestino")
                                Layout.preferredWidth: root.colIpDestinoWidth
                            }
                            PlasmaComponents3.Button {
                                text: sortColumn === "puerto" ? "Puerto " + (sortAscending ? "▲" : "▼") : "Puerto"
                                onClicked: root.toggleSort("puerto")
                                Layout.preferredWidth: root.colPuertoWidth
                            }
                            PlasmaComponents3.Button {
                                text: sortColumn === "empresa" ? "Empresa " + (sortAscending ? "▲" : "▼") : "Empresa"
                                onClicked: root.toggleSort("empresa")
                                Layout.preferredWidth: root.colEmpresaWidth
                            }
                            PlasmaComponents3.Button {
                                text: sortColumn === "paisOrigen" ? "País origen " + (sortAscending ? "▲" : "▼") : "País origen"
                                onClicked: root.toggleSort("paisOrigen")
                                Layout.preferredWidth: root.colPaisOrigenWidth
                            }
                            PlasmaComponents3.Button {
                                text: sortColumn === "paisDestino" ? "País destino " + (sortAscending ? "▲" : "▼") : "País destino"
                                onClicked: root.toggleSort("paisDestino")
                                Layout.preferredWidth: root.colPaisDestinoWidth
                            }
                            PlasmaComponents3.Button {
                                text: sortColumn === "proceso" ? "Proceso " + (sortAscending ? "▲" : "▼") : "Proceso"
                                onClicked: root.toggleSort("proceso")
                                Layout.preferredWidth: root.colProcesoWidth
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
                                color: index % 2 === 0 ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                                GridLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    columns: 7
                                    rowSpacing: 0
                                    columnSpacing: 10

                                    PlasmaComponents3.Label {
                                        text: ipOrigen
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        Layout.preferredWidth: root.colIpOrigenWidth
                                    }
                                    PlasmaComponents3.Label {
                                        text: ipDestino
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        Layout.preferredWidth: root.colIpDestinoWidth
                                    }
                                    PlasmaComponents3.Label {
                                        text: String(puertoDestino)
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.preferredWidth: root.colPuertoWidth
                                    }
                                    PlasmaComponents3.Label {
                                        text: empresa
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        Layout.preferredWidth: root.colEmpresaWidth
                                    }
                                    PlasmaComponents3.Label {
                                        text: paisOrigen
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        Layout.preferredWidth: root.colPaisOrigenWidth
                                    }
                                    PlasmaComponents3.Label {
                                        text: paisDestino
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        Layout.preferredWidth: root.colPaisDestinoWidth
                                    }
                                    PlasmaComponents3.Label {
                                        text: proceso
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        Layout.preferredWidth: root.colProcesoWidth
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    P5Support.DataSource {
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
