import Toybox.Activity;
import Toybox.WatchUi;

class SimpleDataFieldView extends WatchUi.SimpleDataField {

    function initialize() {
        SimpleDataField.initialize();
        label = "SOG";   // appears above the big number
    }

    // Called ~1 Hz with live activity data
    function compute(info as Activity.Info) {
        var ms = (info != null && info.currentSpeed != null) ? info.currentSpeed : 0.0;
        var kts = ms * 1.943844;      // convert m/s → knots
        return kts;                   // Garmin draws this number automatically
    }

}
