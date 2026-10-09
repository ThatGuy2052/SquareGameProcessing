#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D texture; // Frame texture supplied by Processing's filter pipeline.
uniform vec2 resolution; // Width and height used to convert blur offsets to pixels.
uniform float bloomStrength; // Amount of blurred brightness added back to the frame.

varying vec4 vertColor;
varying vec4 vertTexCoord; // Processing's built-in filter vertex shader outputs vec4, not vec2

void main() {
  vec2 uv = vertTexCoord.st;
  vec2 texel = 1.0 / resolution;

  vec4 original = texture2D(texture, uv);//grabs the color of the current selected pixel (uv is like xy)

  // Cheap bloom that since the background is always black it blurs the whole frame and adds it back only lights up areas near bright shapes. very cool thing I once saw done and wanted to try. 
  vec4 blurred = vec4(0.0);
  float total = 0.0;
  for (int x = -2; x <= 2; x++) {
    for (int y = -2; y <= 2; y++) {
      float weight = 1.0 / (1.0 + float(x * x + y * y));
      blurred += texture2D(texture, uv + texel * vec2(float(x), float(y)) * 3.0) * weight;
      total += weight;
    }
  }
  blurred /= total;

  gl_FragColor = original + blurred * bloomStrength;//adds the actually blurred frame onto the original.
}
