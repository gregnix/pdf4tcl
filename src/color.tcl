###############################################################################
# pdf4tcl - color handling
#
# Every user supplied color goes through GetColor, which accepts four forms
# and always returns what the document's color space needs: three components
# for DeviceRGB, four for DeviceCMYK (option -cmyk).
#
#     {r g b}        three values 0.0 to 1.0
#     {c m y k}      four values 0.0 to 1.0
#     #rrggbb        hexadecimal
#     red, navy, ... one of the 147 standard color names, or any name Tk
#                    knows when Tk is loaded and a display is available
#
# This file also holds the RGB/CMYK conversions, which used to live in
# src/helpers.tcl. They keep their namespace, so ::pdf4tcl::rgb2Cmyk and
# ::pdf4tcl::cmyk2Rgb are unchanged for callers and remain overridable.
#
# NOTE ON CLASS VARIABLES
# This file reopens ::pdf4tcl::pdf4tcl with a second oo::define, like
# src/encrypt.tcl and src/tagged.tcl. It must NOT contain a "variable"
# declaration: oo::define variable REPLACES the class variable list rather
# than extending it, so declaring only "pdf" here would hide options, fonts,
# images and the rest from every method of the class.
###############################################################################

namespace eval pdf4tcl {

    # The incoming RGB must contain three values in the range 0.0 to 1.0
    # The return value is CMYK as a list of values in the range 0.0 to 1.0
    proc rgb2Cmyk {RGB} {
        foreach {r g b} $RGB break

        # Black, including some margin for float roundings
        if {$r <= 0.00001 && $g <= 0.00001 && $b <= 0.00001} {
            return [list 0.0 0.0 0.0 1.0]
        }
        set c [expr {1.0 - $r}]
        set m [expr {1.0 - $g}]
        set y [expr {1.0 - $b}]

        # k is min of c/m/y
        set k [expr {min($c, $m, $y)}]
        # k is less than 1 since only black would give exactly 1
        # so all divisions are safe.
        # Since k is min, all numerators are >= 0
        # All numerators are <= denominators, leaving all results <= 1.0
        set c [expr {($c - $k) / (1.0 - $k)}]
        set m [expr {($m - $k) / (1.0 - $k)}]
        set y [expr {($y - $k) / (1.0 - $k)}]

        return [list $c $m $y $k]
    }

    # The incoming CMYK must contain four values in the range 0.0 to 1.0
    # The return value is RGB as a list of values in the range 0.0 to 1.0
    proc cmyk2Rgb {CMYK} {
        foreach {c m y k} $CMYK break

        # Black, including some margin for float roundings
        if {$k >= 0.99999} {
            return [list 0.0 0.0 0.0]
        }

        set c [expr {$c * (1.0 - $k) + $k}]
        set m [expr {$m * (1.0 - $k) + $k}]
        set y [expr {$y * (1.0 - $k) + $k}]

        set r [expr {1.0 - $c}]
        set g [expr {1.0 - $m}]
        set b [expr {1.0 - $y}]

        return [list $r $g $b]
    }

    # The 147 standard color names of X11 and CSS, as RGB in 0.0 to 1.0.
    #
    # Generated with [winfo rgb] against Tk 8.6.14, so the values are exactly
    # the ones Tk would have produced. Having them here means a color name
    # works in a headless script: winfo rgb needs Tk *and* a display, which a
    # PDF generator on a server does not have. Tk is still consulted for names
    # outside this list, so nothing that worked before stops working.
    variable colorNames {
        aliceblue             {0.941176 0.972549 1}
        antiquewhite          {0.980392 0.921569 0.843137}
        aqua                  {0 1 1}
        aquamarine            {0.498039 1 0.831373}
        azure                 {0.941176 1 1}
        beige                 {0.960784 0.960784 0.862745}
        bisque                {1 0.894118 0.768627}
        black                 {0 0 0}
        blanchedalmond        {1 0.921569 0.803922}
        blue                  {0 0 1}
        blueviolet            {0.541176 0.168627 0.886275}
        brown                 {0.647059 0.164706 0.164706}
        burlywood             {0.870588 0.721569 0.529412}
        cadetblue             {0.372549 0.619608 0.627451}
        chartreuse            {0.498039 1 0}
        chocolate             {0.823529 0.411765 0.117647}
        coral                 {1 0.498039 0.313725}
        cornflowerblue        {0.392157 0.584314 0.929412}
        cornsilk              {1 0.972549 0.862745}
        crimson               {0.862745 0.078431 0.235294}
        cyan                  {0 1 1}
        darkblue              {0 0 0.545098}
        darkcyan              {0 0.545098 0.545098}
        darkgoldenrod         {0.721569 0.52549 0.043137}
        darkgray              {0.662745 0.662745 0.662745}
        darkgreen             {0 0.392157 0}
        darkgrey              {0.662745 0.662745 0.662745}
        darkkhaki             {0.741176 0.717647 0.419608}
        darkmagenta           {0.545098 0 0.545098}
        darkolivegreen        {0.333333 0.419608 0.184314}
        darkorange            {1 0.54902 0}
        darkorchid            {0.6 0.196078 0.8}
        darkred               {0.545098 0 0}
        darksalmon            {0.913725 0.588235 0.478431}
        darkseagreen          {0.560784 0.737255 0.560784}
        darkslateblue         {0.282353 0.239216 0.545098}
        darkslategray         {0.184314 0.309804 0.309804}
        darkslategrey         {0.184314 0.309804 0.309804}
        darkturquoise         {0 0.807843 0.819608}
        darkviolet            {0.580392 0 0.827451}
        deeppink              {1 0.078431 0.576471}
        deepskyblue           {0 0.74902 1}
        dimgray               {0.411765 0.411765 0.411765}
        dimgrey               {0.411765 0.411765 0.411765}
        dodgerblue            {0.117647 0.564706 1}
        firebrick             {0.698039 0.133333 0.133333}
        floralwhite           {1 0.980392 0.941176}
        forestgreen           {0.133333 0.545098 0.133333}
        fuchsia               {1 0 1}
        gainsboro             {0.862745 0.862745 0.862745}
        ghostwhite            {0.972549 0.972549 1}
        gold                  {1 0.843137 0}
        goldenrod             {0.854902 0.647059 0.12549}
        gray                  {0.501961 0.501961 0.501961}
        green                 {0 0.501961 0}
        greenyellow           {0.678431 1 0.184314}
        grey                  {0.501961 0.501961 0.501961}
        honeydew              {0.941176 1 0.941176}
        hotpink               {1 0.411765 0.705882}
        indianred             {0.803922 0.360784 0.360784}
        indigo                {0.294118 0 0.509804}
        ivory                 {1 1 0.941176}
        khaki                 {0.941176 0.901961 0.54902}
        lavender              {0.901961 0.901961 0.980392}
        lavenderblush         {1 0.941176 0.960784}
        lawngreen             {0.486275 0.988235 0}
        lemonchiffon          {1 0.980392 0.803922}
        lightblue             {0.678431 0.847059 0.901961}
        lightcoral            {0.941176 0.501961 0.501961}
        lightcyan             {0.878431 1 1}
        lightgoldenrodyellow  {0.980392 0.980392 0.823529}
        lightgray             {0.827451 0.827451 0.827451}
        lightgreen            {0.564706 0.933333 0.564706}
        lightgrey             {0.827451 0.827451 0.827451}
        lightpink             {1 0.713725 0.756863}
        lightsalmon           {1 0.627451 0.478431}
        lightseagreen         {0.12549 0.698039 0.666667}
        lightskyblue          {0.529412 0.807843 0.980392}
        lightslategray        {0.466667 0.533333 0.6}
        lightslategrey        {0.466667 0.533333 0.6}
        lightsteelblue        {0.690196 0.768627 0.870588}
        lightyellow           {1 1 0.878431}
        lime                  {0 1 0}
        limegreen             {0.196078 0.803922 0.196078}
        linen                 {0.980392 0.941176 0.901961}
        magenta               {1 0 1}
        maroon                {0.501961 0 0}
        mediumaquamarine      {0.4 0.803922 0.666667}
        mediumblue            {0 0 0.803922}
        mediumorchid          {0.729412 0.333333 0.827451}
        mediumpurple          {0.576471 0.439216 0.858824}
        mediumseagreen        {0.235294 0.701961 0.443137}
        mediumslateblue       {0.482353 0.407843 0.933333}
        mediumspringgreen     {0 0.980392 0.603922}
        mediumturquoise       {0.282353 0.819608 0.8}
        mediumvioletred       {0.780392 0.082353 0.521569}
        midnightblue          {0.098039 0.098039 0.439216}
        mintcream             {0.960784 1 0.980392}
        mistyrose             {1 0.894118 0.882353}
        moccasin              {1 0.894118 0.709804}
        navajowhite           {1 0.870588 0.678431}
        navy                  {0 0 0.501961}
        oldlace               {0.992157 0.960784 0.901961}
        olive                 {0.501961 0.501961 0}
        olivedrab             {0.419608 0.556863 0.137255}
        orange                {1 0.647059 0}
        orangered             {1 0.270588 0}
        orchid                {0.854902 0.439216 0.839216}
        palegoldenrod         {0.933333 0.909804 0.666667}
        palegreen             {0.596078 0.984314 0.596078}
        paleturquoise         {0.686275 0.933333 0.933333}
        palevioletred         {0.858824 0.439216 0.576471}
        papayawhip            {1 0.937255 0.835294}
        peachpuff             {1 0.854902 0.72549}
        peru                  {0.803922 0.521569 0.247059}
        pink                  {1 0.752941 0.796078}
        plum                  {0.866667 0.627451 0.866667}
        powderblue            {0.690196 0.878431 0.901961}
        purple                {0.501961 0 0.501961}
        red                   {1 0 0}
        rosybrown             {0.737255 0.560784 0.560784}
        royalblue             {0.254902 0.411765 0.882353}
        saddlebrown           {0.545098 0.270588 0.07451}
        salmon                {0.980392 0.501961 0.447059}
        sandybrown            {0.956863 0.643137 0.376471}
        seagreen              {0.180392 0.545098 0.341176}
        seashell              {1 0.960784 0.933333}
        sienna                {0.627451 0.321569 0.176471}
        silver                {0.752941 0.752941 0.752941}
        skyblue               {0.529412 0.807843 0.921569}
        slateblue             {0.415686 0.352941 0.803922}
        slategray             {0.439216 0.501961 0.564706}
        slategrey             {0.439216 0.501961 0.564706}
        snow                  {1 0.980392 0.980392}
        springgreen           {0 1 0.498039}
        steelblue             {0.27451 0.509804 0.705882}
        tan                   {0.823529 0.705882 0.54902}
        teal                  {0 0.501961 0.501961}
        thistle               {0.847059 0.74902 0.847059}
        tomato                {1 0.388235 0.278431}
        turquoise             {0.25098 0.878431 0.815686}
        violet                {0.933333 0.509804 0.933333}
        wheat                 {0.960784 0.870588 0.701961}
        white                 {1 1 1}
        whitesmoke            {0.960784 0.960784 0.960784}
        yellow                {1 1 0}
        yellowgreen           {0.603922 0.803922 0.196078}
    }
}

oo::define ::pdf4tcl::pdf4tcl {

    # Check that all components of a color are within 0.0 and 1.0.
    #
    # The values end up verbatim as operands of rg, RG, k or K, where
    # ISO 32000-1 clause 8.6.4 requires the range 0 to 1. Out of range
    # operands are not a syntax error: readers clamp them silently, qpdf
    # reports nothing, and the document simply has the wrong color. So this
    # raises an error instead -- the same reasoning as for the random source
    # in 0.9.4.35, where a document that cannot be written beats one that
    # only looks right.
    method CheckColorRange {components what} {
        foreach c $components {
            if {![string is double -strict $c]} {
                throw {PDF4TCL} "invalid $what component \"$c\":\
                        not a number"
            }
            if {$c < 0.0 || $c > 1.0} {
                throw {PDF4TCL} "invalid $what component \"$c\":\
                        must be between 0.0 and 1.0"
            }
        }
        return $components
    }

    method GetColor {color} {
        variable ::pdf4tcl::colorNames
        # Remove list layers, to accept things that have been
        # multiply listified
        if {[llength $color] == 1} {
            set color [lindex $color 0]
        }
        if {[llength $color] == 4} {
            my CheckColorRange $color CMYK
            if {$pdf(cmyk)} {
                return $color
            }
            # Convert CMYK to RGB
            set color [pdf4tcl::cmyk2Rgb $color]
        }
        if {[llength $color] == 3} {
            set RGB [my CheckColorRange $color RGB]
        } elseif {[regexp {^\#([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})$} \
                $color -> rHex gHex bHex]} {
            set red   [expr {[scan $rHex %x] / 255.0}]
            set green [expr {[scan $gHex %x] / 255.0}]
            set blue  [expr {[scan $bHex %x] / 255.0}]
            set RGB [list $red $green $blue]
        } elseif {[dict exists $colorNames [string tolower $color]]} {
            # Standard name, resolved without Tk
            set RGB [dict get $colorNames [string tolower $color]]
        } else {
            # Anything else: ask Tk. Catch both a bad color and Tk not
            # being present or having no display.
            if {[catch {winfo rgb . $color} tkcolor]} {
                throw {PDF4TCL} "unknown color: $color"
            }
            foreach {red green blue} $tkcolor break
            set red   [expr {($red   & 0xFF00) / 65280.0}]
            set green [expr {($green & 0xFF00) / 65280.0}]
            set blue  [expr {($blue  & 0xFF00) / 65280.0}]
            set RGB [list $red $green $blue]
        }
        if {!$pdf(cmyk)} {
            return $RGB
        }
        # Convert RGB to CMYK
        return [pdf4tcl::rgb2Cmyk $RGB]
    }

    # Number of components the document's color space uses, and its name.
    # Gradients need both to declare /ColorSpace correctly.
    method ColorSpaceName {} {
        return [expr {$pdf(cmyk) ? "/DeviceCMYK" : "/DeviceRGB"}]
    }

    # Format the components the way every other number in the file is
    # formatted. Used by the gradients, which write their colors into a
    # function object rather than through Pdfoutcmd.
    method FormatColor {color} {
        set out {}
        foreach v $color {
            lappend out [::pdf4tcl::Nf $v]
        }
        return $out
    }

    method setBgColor {args} {
        set pdf(bgColor) [my GetColor $args]
    }

    method SetFillColor {color} {
        if {$pdf(cmyk)} {
            foreach {red green blue k} $color break
            my Pdfoutcmd $red $green $blue $k "k"
        } else {
            foreach {red green blue} $color break
            my Pdfoutcmd $red $green $blue "rg"
        }
    }

    method setFillColor {args} {
        my EndTextObj
        set pdf(fillColor) [my GetColor $args]
        my SetFillColor $pdf(fillColor)
    }

    method SetStrokeColor {color} {
        if {$pdf(cmyk)} {
            foreach {red green blue k} $color break
            my Pdfoutcmd $red $green $blue $k "K"
        } else {
            foreach {red green blue} $color break
            my Pdfoutcmd $red $green $blue "RG"
        }
    }

    method setStrokeColor {args} {
        my EndTextObj
        set pdf(strokeColor) [my GetColor $args]
        my SetStrokeColor $pdf(strokeColor)
    }
}
