using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Activity as Act;
using Toybox.System   as Sys;
// (Rez.* is auto-generated from resources; no import needed)

class MyField extends Ui.DataField {
    var _layout as Ui.View;
    var _big    as Ui.Label;
    var _small  as Ui.Label;
    var _last   as String = "";   // <-- plain ASCII string

    function initialize() { DataField.initialize(); }

    function onLayout(dc as Gfx.Dc) as Void {
        _layout = Rez.Layouts.MainLayout(dc);           // factory function
        _big    = _layout.findById("big")   as Ui.Label;
        _small  = _layout.findById("small") as Ui.Label;
        setLayout(_layout);
    }

    function compute(info as Act.Info) as Void {
        var spd = (info.currentSpeed == null) ? 0.0 : info.currentSpeed; // m/s
        _last = "SOG " + spd.format("%.1f") + " m/s";
    }

    function onUpdate(dc as Gfx.Dc) as Void {
        _big.setText("Tactical HUD");
        _small.setText(_last);
        Ui.requestUpdate();
    }
}
