import QtQuick 2.12
import QtQuick.Controls 2.15
import QtQuick.Controls.Styles 1.4

Item {
    id: contentOwner
    anchors.fill: parent

    signal done
    signal contractReady(string encoded, bool constant, int callIndex, var userData, bool next)
    signal contractError
    signal refresh
    property bool functionIsConstant : false
    property int functionCallIndex : -1
    property int contractIndex : -1
    property var functionUserData : null

    function open(conIndex) {
        contractIndex = conIndex
        functionField.refresh(functionField.currentIndex)
    }

    function encodeCall(contractIndex, funcName, args) {
        var result = contractModel.encodeCall(contractIndex, functionField.currentText, argsView.params);

        if (!result['encoded']) {
            return; // error
        }

        encodedText.text = result['encoded']
        errorText.text = ''
        errorText.visible = false
        encodedText.visible = true
        functionIsConstant = result['constant']
        functionCallIndex = result['callIndex']
        functionUserData = result['userData']

        contractReady(encodedText.text, functionIsConstant, functionCallIndex, functionUserData, false)
    }

    BusyIndicator {
        anchors.centerIn: parent
        z: 10
        running: ipc.starting || ipc.busy || ipc.syncing
    }

    Column {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: 0.1 * dpi
        spacing: 0.2 * dpi

        Row {
            Label {
                width: 1 * dpi
                text: qsTr("Contract: ")
            }

            TextField {
                id: nameField
                width: mainColumn.width - 1 * dpi
                text: contractModel.getName(contractIndex)
                readOnly: true
            }
        }

        Row {
            Label {
                width: 1 * dpi
                text: qsTr("Function: ")
            }

            ComboBox {
                id: functionField
                width: mainColumn.width - 1 * dpi
                model: contractModel.getFunctions(contractIndex)

                function refresh(index) {
                    index = index || functionField.currentIndex
                    if ( index < 0 || contractIndex < 0 || functionField.currentText.length < 1) {
                        console.error("IGNORING");
                        return;
                    }

                    argsView.model = contractModel.getArguments(contractIndex, functionField.currentText)
                    argsView.params = []
                    encodeCall(contractIndex, functionField.currentText, argsView.params);
                    contentOwner.refresh()
                }

                onActivated: refresh(index)
            }
        }

        Row {
            Label {
                width: 1 * dpi
                text: qsTr("Call data: ")
            }

            TextField {
                id: encodedText
                width: mainColumn.width - 1 * dpi
                readOnly: true
            }

            TextField {
                id: errorText
                width: mainColumn.width - 1 * dpi
                readOnly: true
                visible: false

//                style: TextFieldStyle {
//                    textColor: "black"
//                    background: Rectangle {
//                        radius: 2
//                        border.color: "red"
//                        border.width: 1
//                    }
//                }
            }
        }

        ListView {
            id: argsView
            width: parent.width
            height: 1.5 * dpi
            property variant params : []

            delegate: Row {
                Label {
                    width: 2.5 * dpi
                    text: modelData.name + "\t" + modelData.type
                }

                ComboBox {
                    id: boolField
                    visible: modelData.type === "bool"
                    width: mainColumn.width - 2.5 * dpi
                    editable: false
                    model: ListModel {
                        ListElement { text: "" }
                        ListElement { text: "true" }
                        ListElement { text: "false" }
                    }

                    Connections {
                        target: contentOwner
                        function onRefresh() {
                            boolField.currentIndex = 0
                        }
                    }

                    onCurrentIndexChanged: {
                        if ( !visible || currentIndex < 0 || contractIndex < 0 ) return;
                        argsView.params[index] = currentText
                        encodeCall(contractIndex, functionField.currentText, argsView.params);
                    }
                }

                TextField {
                    id: valField
                    visible: modelData.type !== "bool"
                    width: mainColumn.width - 2.5 * dpi
                    placeholderText: modelData.placeholder

                    Connections {
                        target: contentOwner
                        function onRefresh() {
                            valField.text = "" // ensure we wipe old values on window re-open and func reselect
                        }
                    }

                    onTextChanged: {
                        if ( !visible || contractIndex < 0 ) return;
                        argsView.params[index] = text
                        encodeCall(contractIndex, functionField.currentText, argsView.params);
                    }

                    validator: RegExpValidator {
                        regExp: modelData.valrex
                    }
                }
            }
        }

        Connections {
            target: contractModel
            function onCallError(err) {
                errorText.text = err
                errorText.visible = true
                encodedText.visible = false
                encodedText.text = ''
                functionIsConstant = false
                functionCallIndex = -1
                functionUserData = null
                contractError()
            }
        }

        Button {
            id: callButton
            width: parent.width
            height: 0.6 * dpi
            z: 10
            text: errorText.text.length ? qsTr("Invalid Input") : qsTr("Setup Transaction")

            Image {
                id: callIcon
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: parent.height * 0.15
                width: height
                source: errorText.text.length ? "/images/warning" : "/images/ok"
            }

//            style: ButtonStyle {
//              label: Text {
//                renderType: Text.NativeRendering
//                verticalAlignment: Text.AlignVCenter
//                horizontalAlignment: Text.AlignHCenter
//                font.pixelSize: callButton.height / 2.0
//                text: control.text
//              }
//            }

            function check() {
                var result = {
                    error: errorText.text.length ? errorText.text : null
                }

                if ( functionField.currentIndex < 0 ) {
                    result.error = qsTr("No function to call")
                }

                return result;
            }

            function tryCall() {
                var result = check()
                if ( result.error !== null ) {
                    errorDialog.text = result.error
                    errorDialog.open()
                    return
                }

                contractReady(encodedText.text, functionIsConstant, functionCallIndex, functionUserData, true)
            }

            onClicked: tryCall()
        }
    }
}
