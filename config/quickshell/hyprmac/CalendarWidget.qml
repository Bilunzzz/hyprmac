import QtQuick
import Quickshell

// Widget kalender bulan ini (seperti widget Calendar di Notification Center macOS)
Glass {
    id: root

    readonly property var today: clock.date
    readonly property var days: ["S", "S", "R", "K", "J", "S", "M"] // Senin..Minggu
    // Sel kalender: tanggal 1 diletakkan di kolom harinya (minggu mulai Senin)
    readonly property var cells: {
        const first = new Date(today.getFullYear(), today.getMonth(), 1);
        const offset = (first.getDay() + 6) % 7;
        const count = new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate();
        const out = [];
        for (let i = 0; i < offset; i++)
            out.push(0);
        for (let d = 1; d <= count; d++)
            out.push(d);
        return out;
    }

    height: content.implicitHeight + 24
    radius: 20
    tint: Qt.rgba(1, 1, 1, 0.05)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        id: content

        x: 14
        y: 12
        width: parent.width - 28
        spacing: 6

        Row {
            width: parent.width

            Column {
                width: parent.width * 0.42

                Text {
                    text: root.today.toLocaleDateString(Qt.locale("id_ID"), "dddd").toUpperCase()
                    color: "#ff453a"
                    font.family: "Adwaita Sans"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Text {
                    text: root.today.getDate()
                    color: "white"
                    font.family: "Adwaita Sans"
                    font.pixelSize: 44
                    font.weight: Font.Light
                }

                Text {
                    text: Qt.formatDateTime(root.today, "HH.mm")
                    color: Qt.rgba(1, 1, 1, 0.6)
                    font.family: "Adwaita Sans"
                    font.pixelSize: 13
                }
            }

            Column {
                width: parent.width * 0.58
                spacing: 2

                Text {
                    text: root.today.toLocaleDateString(Qt.locale("id_ID"), "MMMM yyyy").toUpperCase()
                    color: "#ff453a"
                    font.family: "Adwaita Sans"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                Grid {
                    columns: 7

                    Repeater {
                        model: root.days

                        Text {
                            required property string modelData

                            width: 26
                            height: 16
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: Qt.rgba(1, 1, 1, 0.5)
                            font.family: "Adwaita Sans"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }

                    Repeater {
                        model: root.cells

                        Item {
                            id: cell

                            required property int modelData

                            width: 26
                            height: 18

                            Rectangle {
                                visible: cell.modelData === root.today.getDate()
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                radius: 9
                                color: "#ff453a"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: cell.modelData > 0 ? cell.modelData : ""
                                color: "white"
                                font.family: "Adwaita Sans"
                                font.pixelSize: 10
                                font.weight: cell.modelData === root.today.getDate() ? Font.Bold : Font.Normal
                            }
                        }
                    }
                }
            }
        }
    }
}
