let canvas = document.createElement('canvas'),
    gl = canvas.getContext('webgl2', {antialias: false, depth: false, stencil: false});

document.body.appendChild(canvas);

let quad_vshader = `
attribute vec2 vpos;

void main() {
    gl_Position = vec4(vpos, 0.0, 1.0);
}
`;

let quad = new Float32Array([
    -1.0, 1.0,
    1.0, 1.0,
    1.0, -1.0,
    -1.0, -1.0
]);

function simpleShader (vs, fs) {
    let program = gl.createProgram(),
        vshader = gl.createShader(gl.VERTEX_SHADER),
        fshader = gl.createShader(gl.FRAGMENT_SHADER);

    gl.shaderSource(vshader, vs);
    gl.shaderSource(fshader, fs);

    gl.compileShader(vshader);
    gl.compileShader(fshader);

    gl.attachShader(program, vshader);
    gl.attachShader(program, fshader);

    gl.linkProgram(program);

    return program;
}

