#iChannel0 https://66.media.tumblr.com/tumblr_mcmeonhR1e1ridypxo1_500.jpg
#iChannel1 buf://./test.glsl

#define EPSILON 0.01

float ground ( vec3 point ) {
  return point.y;
}

float sphere ( vec3 point, float radius ) {
  return length(point) - radius;
}

float box ( vec3 point, vec3 bounds ) {
  vec3 d = abs(point) - bounds;
  return length (max(d,0.0))
         + min (max (d.x, max(d.y, d.z)), 0.0);
}
float torus ( vec3 point, vec2 t ) {
  vec2 q = vec2(length(point.xz) - t.x, point.y);
  return length(q) - t.y;
}

vec3 sd_repeat (vec3 p, vec3 c) {
  vec3 q = mod(p, c) - 0.5 * c;
  return q;
}
vec3 sd_symX ( vec3 p ) {
  p.x = abs(p.x);
  return p;
}
vec3 sd_symXZ ( vec3 p ) {
  p.xz = abs(p.xz);
  return p;
}
/*
float sd_cheapBend( in sdf3d primitive, in vec3 p ) {
    const float k = 10.0; // or some other amount
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xy,p.z);
    return primitive(q);
}*/

//vec3 sd_tx( vec3 p, mat3x4 t ) {
//    return invert(t) * p;
//}

float sd_displace( float d, vec3 p, float k ) {
  float d2 = -abs(sin(k * p.x) * sin(k * p.y) * sin(k * p.z));
  return d+d2;
}
vec3 sd_twist ( vec3 p, float k ) {
  float c = cos(k*p.y);
  float s = sin(k*p.y);
  mat2  m = mat2(c,-s,s,c);
  vec3  q = vec3(m*p.xz,p.y);
  return q;
}

float sd_union ( float a, float b ) {
  return min(a, b);
}
float sd_diff ( float a, float b ) {
  return max(-a, b); // max(a, -b)?
}
float sd_intersect ( float a, float b ) {
  return max(a, b);
}
float sd_smooth_union ( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5 * (d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}
float sd_smooth_diff ( float d1, float d2, float k ) {
  float h = clamp( 0.5 - 0.5 * (d2+d1)/k, 0.0, 1.0 );
  return mix( d2, -d1, h ) + k*h*(1.0-h);
}
float sd_smooth_intersect ( float d1, float d2, float k ) {
  float h = clamp( 0.5 - 0.5 * (d2-d1)/k, 0.0, 1.0 );
  return mix( d2, d1, h ) + k*h*(1.0-h);
}

float world ( vec3 position ) {
  vec3 tp = position - vec3 (0.0, 0.0, 0.0);
  tp.x = abs(tp.x);

  return sd_displace (sphere ( sd_repeat (tp, vec3(4.0, 4.0, 4.0)), 0.3), vec3(5.0,3.0,7.0), sin(iGlobalTime*0.5));
  float d = 100.0;
  for (int i = 0; i < 8; i++) {
    d = sd_smooth_union (
          d,
          torus(
            sd_repeat (
              vec3(tp.x + sin(iTime) * float(i&1),
                   tp.y + sin(iTime) * float(i&2),
                   tp.z + sin(iTime) * float(i&4) ),
              vec3(-3.0, 3.0, 0.0) ), 
            vec2(0.9, 0.2)), 0.5);
  }
  return d;
  //return d;
  return sd_union (
          d,//ground(position - vec3 (0.0, -1.5, 0.0)),
          sd_smooth_union (
            sphere(tp, 1.0),
            torus(tp, vec2(1.0,0.1+abs(sin(iGlobalTime)))),
            //box(tp, vec3(0.5, 1.0, 0.5)),
            0.3
          )
         );
}

float raymarch ( vec3 origin, vec3 direction ) {
  const float minDistance = 1.0, maxDistance = 100.0;
  float totalDistance = minDistance;
  const int maxSteps = 64;
  for (int steps = 0; steps < maxSteps; steps++) {
    float p = 0.0005 * totalDistance;
    float distance = world(origin + direction * totalDistance);
    if (distance < EPSILON || totalDistance >= maxDistance) break;
    totalDistance += distance;
  }
  if (totalDistance >= maxDistance) totalDistance = -1.0;
  return totalDistance;
}

vec3 normal ( vec3 p ) {
  float dx = world(vec3(p.x+EPSILON, p.yz)) - world(vec3(p.x-EPSILON, p.yz)),
       dy = world(vec3(p.x, p.y+EPSILON, p.z)) - world(vec3(p.x, p.y-EPSILON, p.z)),
       dz = world(vec3(p.xy, p.z+EPSILON)) - world(vec3(p.xy, p.z-EPSILON));
  return normalize(vec3(dx, dy, dz));
}

vec3 render ( vec3 eye, vec3 direction ) {
  vec3 color = vec3(0.0);
  float t = raymarch(eye, direction);
  if (t > -0.5) {
    vec3 N = normal(eye + direction * t);
    vec3 material = vec3(0.9);
    //vec3 material = texture2D(iChannel1, vec2(iGlobalTime*0.0001)).rgb;
    color = material * dot(N, normalize(eye));
    color *= exp( -0.00001 * t*t*t );
    vec2 tuv = gl_FragCoord.xy / iResolution.xy;
    color *= texture2D(iChannel1,tuv).rgb;// * 0.2;// * dot(N, eye);
  }
  return color;
}

mat3 setCamera ( vec3 ro, vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main() {

  float time = iGlobalTime * 1.0;

  vec2 uv = (gl_FragCoord.xy / iResolution.xx - 0.5) * 8.0;

  vec3 light = vec3(2.0, 2.0, 2.0);

        vec2 p = (-iResolution.xy + 2.0*gl_FragCoord.xy)/iResolution.y;

        float an = 12.0 - sin(0.1*iTime);
        vec3 ray_origin = vec3(0.0,8.0,18.0+6.0*sin(time));//vec3( 3.0*cos(0.1*an), 1.0, -3.0*sin(0.1*an) );
        vec3 ta = vec3(cos(time)*3.0, sin(time) , cos(time)*2.0 );
        // camera-to-world transformation
        mat3 camera = setCamera( ray_origin, ta, 0.0 );

        // ray direction
        vec3 ray_direction = camera * normalize( vec3(p.xy, 0.5+sin(iGlobalTime*0.1)*1.0) );

        // render
        vec3 col = render( ray_origin, ray_direction );

		    // gamma
        //col = pow( col, vec3(0.4545) );

    gl_FragColor = vec4( col, 1.0 );

}
