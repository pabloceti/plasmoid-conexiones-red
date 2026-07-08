import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_autoRefreshEnabled: autoRefreshEnabled.checked
    property alias cfg_refreshIntervalSeconds: refreshIntervalSeconds.value

    QQC2.CheckBox {
        id: autoRefreshEnabled
        Kirigami.FormData.label: i18n("Actualizacion automatica")
        text: i18n("Activada")
    }

    QQC2.SpinBox {
        id: refreshIntervalSeconds
        Kirigami.FormData.label: i18n("Intervalo (segundos)")
        from: 5
        to: 3600
        stepSize: 5
        editable: true
    }
}
