using Toybox.Math as M;

class CircularAvg {
    var s = 0.0;
    var c = 0.0;
    var n = 0;

    function add(rad as Float) as Void {
        s += M.sin(rad);
        c += M.cos(rad);
        n += 1;
    }

    function mean() as Float {
        return (n == 0) ? 0.0 : M.atan2(s / n, c / n);
    }
}

class TacticalEngine {
    // Tunables
    const VMIN = 0.5;            // m/s ignore noise below this
    const TURN_RATE_MIN = 0.15;  // rad/s ~8.6°/s for maneuvers
    const LIFT_DEG = 4.0;

    // State
    var twd = null;          // radians
    var lastCog = null;
    var lastTs  = null;
    var rollPort = new CircularAvg();
    var rollStar = new CircularAvg();
    var tackSign = 0;        // -1 port, +1 star

    function step(ts as Number, sog as Float, cog as Float) as Dictionary {
        if (lastTs == null) {
            lastTs = ts;
            lastCog = cog;
            return { :state => "idle" };
        }

        var dt = (ts - lastTs) / 1000.0;
        if (dt <= 0) { dt = 1.0; }

        // turn rate
        var d = wrap(cog - lastCog);
        var turn = d / dt;

        // bootstrap TWD from close-hauled bisector once moving
        if (sog >= VMIN) {
            var thetaGuess = cog; // first few seconds
            var side = sideOf(thetaGuess, twd);

            if (side < 0) {
                rollPort.add(cog);
            } else {
                rollStar.add(cog);
            }

            var mp = rollPort.mean();
            var ms = rollStar.mean();
            if (rollPort.n > 10 && rollStar.n > 10) {
                // bisector pointing to wind
                var bis = wrap((mp + ms) * 0.5);
                twd = bis;
            }
        }

        // classify leg and maneuvers
        var state = "unknown";
        if (twd != null) {
            var awa = absDeg(radToDeg(angdiff(cog, twd)));     // angle to wind
            var up   = (awa >= 25) && (awa <= 55);
            var down = absDeg(radToDeg(angdiff(cog, twd + M.PI))) <= 45;

            var newsign = sideOf(cog, twd);
            if (M.abs(turn) > TURN_RATE_MIN && newsign != tackSign && tackSign != 0) {
                state = up ? "tack" : "gybe";
            } else if (up) {
                state = "upwind";
            } else if (down) {
                state = "downwind";
            } else {
                state = "reach";
            }

            tackSign = (newsign == 0) ? tackSign : newsign;
        }

        lastTs = ts;
        lastCog = cog;

        var lift = 0.0;
        if (twd != null) {
            var awaNow = radToDeg(angdiff(cog, twd));
            // crude lift/header sign by “toward/away” from wind on this tack
            lift = (tackSign < 0) ? (-awaNow) : (-1 * awaNow);
        }

        return {
            :state    => state,
            :twd      => twd,
            :cog      => cog,
            :lift_deg => lift
        };
    }
}

// ------- helpers (file scope) -------
function angdiff(a as Float, b as Float) as Float {
    return wrap(a - b);
}

function wrap(x as Float) as Float {
    while (x <= -M.PI) { x += 2 * M.PI; }
    while (x >   M.PI) { x -= 2 * M.PI; }
    return x;
}

function radToDeg(r as Float) as Float {
    return r * 180.0 / M.PI;
}

// left/right of current TWD: negative = port, positive = starboard
function sideOf(cog as Float, twd as Float) as Number {
    if (twd == null) { return 0; }
    return (angdiff(cog, twd) < 0) ? -1 : 1;
}

function absDeg(d as Float) as Float {
    return (d < 0) ? -d : d;
}
