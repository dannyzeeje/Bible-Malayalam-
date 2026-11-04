#include <flutter/runtime_effect.glsl>
uniform vec2 uSize;
uniform float uRadius;
uniform float uLens;
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
void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 halfSize = uSize * 0.5;
  float radius = min(uRadius, min(halfSize.x, halfSize.y));
  vec2 q = abs(p - halfSize) - halfSize + radius;
  float sdf = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
  float rim = 1.0 - smoothstep(0.0, max(radius * 0.7, 1.0), -sdf);
  vec2 normal = (p - halfSize) / max(length(p - halfSize), 1.0);
  vec2 lens = p - normal * rim * uLens * min(uSize.x, uSize.y);
  vec4 c = sampleAt(lens) * 0.25;
  c += (sampleAt(lens + vec2(uStep,0)) + sampleAt(lens - vec2(uStep,0))
      + sampleAt(lens + vec2(0,uStep)) + sampleAt(lens - vec2(0,uStep))) * 0.125;
  c += (sampleAt(lens + vec2(uStep,uStep)) + sampleAt(lens - vec2(uStep,uStep))
      + sampleAt(lens + vec2(uStep,-uStep)) + sampleAt(lens - vec2(uStep,-uStep))) * 0.0625;
  fragColor = c;
}
