#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D texture; // Frame texture supplied by Processing's filter pipeline.
uniform vec2 resolution; // Width and height used for scanline and vignette coordinates.

varying vec4 vertColor;
varying vec4 vertTexCoord; // Processing's built-in filter vertex shader outputs vec4, not vec2

void main() {
  vec2 uv = vertTexCoord.st;
  vec2 centered = uv * 2.0 - 1.0;

  // No geometric warp here on purpose: distorting pixel positions would desync
  // button hitboxes (mouseX/mouseY) from where they visually appear on screen.
  vec4 col = texture2D(texture, uv);

  // Horizontal scanlines that look cool
  float scanline = 0.92 + 0.08 * cos(uv.y * resolution.y * 3.14159 * 1.0);
  col.rgb *= scanline;

  // Faint RGB mask stripes.
  float stripe = mod(gl_FragCoord.x, 3.0);
  vec3 mask = vec3(1.0);
  if (stripe < 1.0) mask = vec3(1.05, 0.95, 0.95);
  else if (stripe < 2.0) mask = vec3(0.95, 1.05, 0.95);
  else mask = vec3(0.95, 0.95, 1.05);
  col.rgb *= mask;

  // Vignette that darkens toward the corners of the screen (looks nice once again).
  float vignette = 1.0 - dot(centered, centered) * 0.35;
  col.rgb *= vignette;

  gl_FragColor = col;
}
