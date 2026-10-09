#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D texture; // Frame texture supplied by Processing's filter pipeline.
uniform vec2 resolution; // Width and height of the filtered frame.
uniform vec2 lightCenter; // Player center in screen coordinates.
uniform float lightRadius; // Full-bright radius around the player.
uniform float lightSoftness; // Width of the fade outside the full-bright radius.
uniform float dangerAmount; // Enemy proximity amount used for the edge warning.
uniform float nightmareMode; // Selects total darkness outside the light when set to one.

varying vec4 vertColor;
varying vec4 vertTexCoord;

void main() {
  vec2 uv = vertTexCoord.st;
  vec2 playerPosition = vec2(lightCenter.x, resolution.y - lightCenter.y);
  float distanceFromPlayer = distance(gl_FragCoord.xy, playerPosition);
  float lightStart = max(0.0, lightRadius - lightSoftness);
  float light = 1.0 - smoothstep(lightStart, lightRadius + lightSoftness, distanceFromPlayer);

  vec4 col = texture2D(texture, uv);

  // Nightmare mode removes all visibility outside the player's light.
  float brightness = mix(0.42, 1.0, light);
  brightness = mix(brightness, light, nightmareMode);
  col.rgb *= brightness;

  // Push the warning toward the screen edges instead of tinting the whole frame.
  vec2 edgeDistance = min(uv, 1.0 - uv);
  float edgePosition = min(edgeDistance.x, edgeDistance.y);
  float edgeFade = clamp((edgePosition - 0.04) / (0.22 - 0.04), 0.0, 1.0);
  float edgeMask = mix(1.0, 0.0, edgeFade);
  float redGlow = dangerAmount * edgeMask * 0.24;
  col.rgb += vec3(redGlow, redGlow * 0.08, redGlow * 0.03);

  gl_FragColor = col;
}