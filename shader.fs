<script id='compshader'>
precision mediump float;

uniform vec2 ires;
uniform float time;

uniform sampler2D data;

bool equal(float a, float b) {
    return abs(a - b) < 0.1;
}

bool v2equal(vec2 a, vec2 b) {
    return equal(a[0], b[0]) && equal(a[1], b[1]);
}

void main () {
    vec4 col;
    col = vec4(gl_FragCoord.xy/ires*(sin(time/1000.)+1.), 0.0, 1.0);
    if (gl_FragCoord.x > ires.x/2.)
        col = vec4(0.0);
    if(time > 1000.) {
        col = texture2D(data, gl_FragCoord.xy);
    }

    float f = texture2D(data, vec2(0., 0.)).r;
    //if(f < 1.)
        //col = vec4(gl_FragCoord.xy/ires*(sin(time/1000.)+1.), 0.0, 1.0);

    if (v2equal(gl_FragCoord.xy, vec2(2.5, 2.5))) {
        col = vec4(0.0, 0.0, 1.0, 1.0);
    }
    if (equal(mod(gl_FragCoord.x, 2.), 0.5)) {
        col = vec4(gl_FragCoord.x/ires.x, 0., 0., 1.);
    }
    col = texture2D(data, gl_FragCoord.xy/ires);

    gl_FragColor = col;
}
</script>
