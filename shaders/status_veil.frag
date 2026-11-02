#include <flutter/runtime_effect.glsl>
uniform vec2 uSize;
uniform float uExtent;
uniform float uStep;
uniform sampler2D uInput;
out vec4 fragColor;
vec4 sampleAt(vec2 p) {
  vec2 uv = clamp(p, vec2(0.5), uSize - vec2(0.5)) / uSize;
  #ifdef IMPELLER_TARGET_OPENGLES
    uv.y = 1.0 - uv.y;
  #endif
  return texture(uInput, uv);
}
float weight(int i) {
  if (i == 0) return 6.0;
  if (i == 1 || i == -1) return 4.0;
  return 1.0;
}
void main() {
  vec2 p = FlutterFragCoord().xy;
  vec4 original = sampleAt(p);
  // Compact binomial Gaussian: adjacent samples, no sparse wide offsets.
  vec4 softened = vec4(0.0);
  for (int y = -2; y <= 2; y++) {
    for (int x = -2; x <= 2; x++) {
      softened += sampleAt(p + vec2(float(x), float(y)) * uStep)
        * weight(x) * weight(y) / 256.0;
    }
  }
  float fade = 0.55 * (1.0 - smoothstep(0.0, max(uExtent, 1.0), p.y));
  fragColor = mix(original, softened, fade);
}
