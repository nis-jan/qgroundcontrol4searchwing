/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Controls 1.2
import QtLocation       5.3
import QtPositioning    5.3
import QtQuick.Dialogs  1.2

import QGroundControl                       1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.Controls              1.0
import QGroundControl.FlightMap             1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.Vehicle               1.0
import QGroundControl.QGCPositionManager    1.0

import REST 1.0




Map {
    id: _map

    //-- Qt 5.9 has rotation gesture enabled by default. Here we limit the possible gestures.
    gesture.acceptedGestures:   MapGestureArea.PinchGesture | MapGestureArea.PanGesture | MapGestureArea.FlickGesture
    gesture.flickDeceleration:  3000
    plugin:                     Plugin { name: "QGroundControl" }

    // https://bugreports.qt.io/browse/QTBUG-82185
    opacity:                    0.99

    property string mapName:                        'defaultMap'
    property bool   isSatelliteMap:                 activeMapType.name.indexOf("Satellite") > -1 || activeMapType.name.indexOf("Hybrid") > -1
    property var    gcsPosition:                    QGroundControl.qgcPositionManger.gcsPosition
    property real   gcsHeading:                     QGroundControl.qgcPositionManger.gcsHeading
    property bool   allowGCSLocationCenter:         false   ///< true: map will center/zoom to gcs location one time
    property bool   allowVehicleLocationCenter:     false   ///< true: map will center/zoom to vehicle location one time
    property bool   firstGCSPositionReceived:       false   ///< true: first gcs position update was responded to
    property bool   firstVehiclePositionReceived:   false   ///< true: first vehicle position update was responded to
    property bool   planView:                       false   ///< true: map being using for Plan view, items should be draggable

    readonly property real  maxZoomLevel: 20

    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property var    _activeVehicleCoordinate:   _activeVehicle ? _activeVehicle.coordinate : QtPositioning.coordinate()

    function setVisibleRegion(region) {
        // TODO: Is this still necessary with Qt 5.11?
        // This works around a bug on Qt where if you set a visibleRegion and then the user moves or zooms the map
        // and then you set the same visibleRegion the map will not move/scale appropriately since it thinks there
        // is nothing to do.
        _map.visibleRegion = QtPositioning.rectangle(QtPositioning.coordinate(0, 0), QtPositioning.coordinate(0, 0))
        _map.visibleRegion = region
    }

    function _possiblyCenterToVehiclePosition() {
        if (!firstVehiclePositionReceived && allowVehicleLocationCenter && _activeVehicleCoordinate.isValid) {
            firstVehiclePositionReceived = true
            center = _activeVehicleCoordinate
            zoomLevel = QGroundControl.flightMapInitialZoom
        }
    }

    function centerToSpecifiedLocation() {
        specifyMapPositionDialog.createObject(mainWindow).open()
    }

    Component {
        id: specifyMapPositionDialog
        EditPositionDialog {
            title:                  qsTr("Specify Position")
            coordinate:             center
            onCoordinateChanged:    center = coordinate
        }
    }


    // Center map to gcs location
    onGcsPositionChanged: {
        if (gcsPosition.isValid && allowGCSLocationCenter && !firstGCSPositionReceived && !firstVehiclePositionReceived) {
            firstGCSPositionReceived = true
            //-- Only center on gsc if we have no vehicle (and we are supposed to do so)
            var _activeVehicleCoordinate = _activeVehicle ? _activeVehicle.coordinate : QtPositioning.coordinate()
            if(QGroundControl.settingsManager.flyViewSettings.keepMapCenteredOnVehicle.rawValue || !_activeVehicleCoordinate.isValid)
                center = gcsPosition
        }
    }

    function updateActiveMapType() {
        var settings =  QGroundControl.settingsManager.flightMapSettings
        var fullMapName = settings.mapProvider.value + " " + settings.mapType.value

        for (var i = 0; i < _map.supportedMapTypes.length; i++) {
            if (fullMapName === _map.supportedMapTypes[i].name) {
                _map.activeMapType = _map.supportedMapTypes[i]
                return
            }
        }
    }

    on_ActiveVehicleCoordinateChanged: _possiblyCenterToVehiclePosition()

    onMapReadyChanged: {
        if (_map.mapReady) {
            updateActiveMapType()
            _possiblyCenterToVehiclePosition()
        }
    }

    Connections {
        target:             QGroundControl.settingsManager.flightMapSettings.mapType
        function onRawValueChanged() { updateActiveMapType() }
    }

    Connections {
        target:             QGroundControl.settingsManager.flightMapSettings.mapProvider
        function onRawValueChanged() { updateActiveMapType() }
    }

    /// Ground Station location
    MapQuickItem {
        anchorPoint.x:  sourceItem.width / 2
        anchorPoint.y:  sourceItem.height / 2
        visible:        gcsPosition.isValid
        coordinate:     gcsPosition

        sourceItem: Image {
            id:             mapItemImage
            source:         isNaN(gcsHeading) ? "/res/QGCLogoFull" : "/res/QGCLogoArrow"
            mipmap:         true
            antialiasing:   true
            fillMode:       Image.PreserveAspectFit
            height:         ScreenTools.defaultFontPixelHeight * (isNaN(gcsHeading) ? 1.75 : 2.5 )
            sourceSize.height: height
            transform: Rotation {
                origin.x:       mapItemImage.width  / 2
                origin.y:       mapItemImage.height / 2
                angle:          isNaN(gcsHeading) ? 0 : gcsHeading
            }
        }
    }

    //Code from here is searchwing specific
    //unfortunately I couldn't make it work to dynamically add Markers to the model, they always wouldnt be displayed if not added at compiletime to the model.
    ListModel {
        id: markerModel
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
        ListElement {lat: -35.3618271; lon:149.1675706; visible: false}
    }

    Repeater {
        model: markerModel

        delegate: MapQuickItem {
            property bool hovered: false
            coordinate: QtPositioning.coordinate(model.lat, model.lon)
            anchorPoint.x: 10
            anchorPoint.y: 10
            visible: model.visible
            z: 1000
            sourceItem: Image {
                height: 30
                width: 30
                visible: true
                Dialog {
                    id: infoDialog
                    title: "Boot"
                    visible: false
                    standardButtons: StandardButton.Ok

                    onAccepted: {
                        infoDialog.visible = false
                        console.log("Dialog wurde akzeptiert");
                    }

                    contentItem: Column {
                        spacing: 10
                        Text { text: "Boot bei lat=" + model.lat + " lon=" + model.lon}
                    }
                }
                // Tooltip-Text
                Rectangle {
                    visible: hovered
                    color: "#333333"        // Hintergrundfarbe
                    anchors.top: parent.top
                    radius: 4
                    anchors.left: parent.right
                    anchors.margins: 4
                    Text {
                        id: text
                        text: "Boot bei:\nlat: " + model.lat + "\nlon: " + model.lon
                        color: "white"
                        anchors.margins: 6
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    width: text.implicitWidth+24
                    height: text.implicitHeight+24
                    z: 100
                }

                Image {
                    id: icon
                    source: "/res/firmware/distress_boat.svg"
                    anchors.fill: parent
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    // for the tooltip text (on hover):
                    onEntered: hovered = true
                    onExited: hovered = false

                    onClicked: {
                        infoDialog.visible = true;
                    }
                }
            }
        }
    }

    //TODO: newMarkers signal machen, wo eine Liste übergeben wird und jedes mal alle Marker neu gesetzt werden.
    Connections {
        target: API_bridge
        onNewMarkers: (coordList) => {
                         console.log("new Markers:");
                         // alle Marker erstmal deaktivieren, die vorher gezeigt wurden:
                         for (var i = 0; i < 100; i++){
                             if (markerModel.get(i).visible == true){
                                 markerModel.setProperty(i, "visible", false);
                             }
                             else break;
                         }
                        // jetzt entsprechend die Marker setzen:
                         for (var i = 0; i < coordList.length && i < 100; i++){
                             markerModel.setProperty(Math.floor(i/2.0), i%2 == 0?"lat":"lon", coordList[i]);
                             markerModel.setProperty(Math.floor(i/2.0), "visible", true);

                         }
        }
    }

} // Map
