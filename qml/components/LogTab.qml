/*
    This file is part of etherwall.
    etherwall is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    etherwall is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with etherwall. If not, see <http://www.gnu.org/licenses/>.
*/
/** @file AccountsTab.qml
 * @author Ales Katona <almindor@gmail.com>
 * @date 2015
 *
 * Log tab
 */

import QtQuick 2.12
import QtQuick.Controls 2.15

Loader {
    id: logTab

    Column {
        id: col
        anchors.margins: 0.2 * dpi
        anchors.fill: parent
        spacing: 0.1 * dpi

        Row {
            id: logControlRow
            spacing: 0.1 * dpi

            Button {
                id: logClipButton
                text: "Save to clipboard"
                onClicked: {
                    log.saveToClipboard()
                }
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Log level: ")
            }

            ComboBox {
                id: logLevelCombo
                currentIndex: log.logLevel
                textRole: "text"

                onActivated: log.logLevel = index

                model: ListModel {
                    id: llItems
                    ListElement { text: "Debug"; value: 0 }
                    ListElement { text: "Info"; value: 1 }
                    ListElement { text: "Warning"; value: 2 }
                    ListElement { text: "Error"; value: 3 }
                }
            }
        }

        GroupBox {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 0.1 * dpi
            height: parent.height - logControlRow.height

            ScrollView {
                anchors.fill: parent

                ListView {
                    anchors.fill: parent
                    model: log

                    delegate: Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        text: date + "\t" + severity + "\t" + msg
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }
                }
            }
        }
    }
}
