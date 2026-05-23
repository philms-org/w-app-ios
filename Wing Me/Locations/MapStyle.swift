
import UIKit

class MapStyle {
    static let key = "AIzaSyDUTdULOtu0SPHoi171cG8vN9bpSLotLFU"
    
    static let kMapStyle = """
        [{
            "featureType": "landscape",
            "elementType": "labels",
            "stylers": [{
                "visibility": "off"
            }]
        },
        {
            "featureType": "poi",
            "elementType": "labels",
            "stylers": [{
                "visibility": "off"
            }]
        },
        {
            "featureType": "transit",
            "elementType": "labels",
            "stylers": [{
                "visibility": "off"
            }]
        }]
        """
}
