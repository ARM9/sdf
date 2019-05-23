'use strict';
let pr = s => console.log(s);

function setupCanvas(canvas, shader, cols, rows) {
    let ires_loc = gl.getUniformLocation(shader, 'ires');
    gl.uniform2fv(ires_loc, [cols, rows]);

    gl.viewport(0,0, cols,rows);
    canvas.style = `width:${cols*16}px;height:${rows*16}px;image-rendering:pixelated;`;
    canvas.width = cols;
    canvas.height = rows;
}

function main() {
    let rows = 16, cols = 16;

    let shader = simpleShader(quad_vshader, document.getElementById('compshader').textContent);
    gl.useProgram(shader);

    let quad_buffer = gl.createBuffer(),
        vpos_loc = gl.getAttribLocation(shader, 'vpos');

    gl.bindBuffer(gl.ARRAY_BUFFER, quad_buffer);
    gl.bufferData(gl.ARRAY_BUFFER, quad, gl.STATIC_DRAW);

    gl.vertexAttribPointer(vpos_loc, 2, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(vpos_loc);

    let tex0_loc = gl.getUniformLocation(shader, 'data');
    gl.uniform1i(tex0_loc, 0);

    let data = new Uint8Array(cols*rows*4);
    for(let i = 0; i < cols*rows*4; i+=4) {
        data[i+0] = i;
        data[i+1] = i;
        data[i+2] = (i^255);
        data[i+3] = 255;
    }
    pr(data);

    let fb = gl.createFramebuffer(),
        output_texture = gl.createTexture();
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, output_texture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, cols, rows, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);

    //gl.texStorage2D(gl.TEXTURE_2D, 1, gl.RGBA8, cols, rows);
    //gl.clearColor(0.,0.,1.,1.);
    //gl.clear(gl.COLOR_BUFFER_BIT);
    //gl.copyTexSubImage2D(gl.TEXTURE_2D, 0, 0, 0, 0, 0, cols, rows, 0);

    //gl.texSubImage2D(gl.TEXTURE_2D, 0, 0, 0, cols, rows, gl.RGBA, gl.UNSIGNED_BYTE, data);

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    //gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

    //gl.bindFramebuffer(gl.FRAMEBUFFER, fb);
    //gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, output_texture, 0);

    setupCanvas(canvas, shader, cols, rows);

    let output = new Uint8Array(cols*rows*4);

    function render(time) {
        window.requestAnimationFrame(render);

        //gl.bindFramebuffer(gl.FRAMEBUFFER, fb);

        gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.uniform1f(gl.getUniformLocation(shader, 'time'), time);

        gl.drawArrays(gl.TRIANGLE_FAN, 0, quad.length/2);

        //gl.readPixels(0, 0, cols, rows, gl.RGBA8, gl.UNSIGNED_BYTE, output);
        //gl.copyTexSubImage2D(gl.TEXTURE_2D, 0, 0, 0, 0, 0, cols, rows, 0);

        //gl.bindFramebuffer(gl.FRAMEBUFFER, null);
        //gl.clear(gl.COLOR_BUFFER_BIT);
        //gl.drawArrays(gl.TRIANGLE_FAN, 0, quad.length/2);
    }
    render();
}

main();

