#define MAX_STEPS 200
#define MAX_DISTANCE 100.0
#define EPSILON 0.001
#define USE_HALF_LAMBERT 1
#define MAX_BOUNCE 6

const vec3 ambient = vec3(0., 0., 0.);
const vec3 lightColor = vec3(1., 185./255., 77./255.);
const vec3 lightDir = normalize(vec3(-1, 1, -1));
const vec3 diffColor = vec3(1., 1., 1.);
const vec3 specularColor = vec3(1., 1., 1.);
const float gloss = 100.;
const float fieldOfView = 45.;
const float near = 1.;
const vec3 sphereCenter = vec3(0, 0, 0);
const float fresnelScale = .0;

float sphere1(vec3 sp) {
    return length(sp - sphereCenter) - 1.0;
}

float cube1(vec3 sp) {
    vec3 cubeCenter = vec3(0., 0., 2.);
    vec3 cubeScale = vec3(2., 2., .1);
    return length(max(abs(sp-cubeCenter) - cubeScale, 0.));
}

float cube2(vec3 sp) {
    vec3 cubeCenter = vec3(2., 0., 0.);
    vec3 cubeScale = vec3(.1, 2., 2.);
    return length(max(abs(sp-cubeCenter) - cubeScale, 0.));   
}

float cube3(vec3 sp) {
    vec3 cubeCenter = vec3(0., -2., 0.);
    vec3 cubeScale = vec3(2., .1, 2.);
    return length(max(abs(sp-cubeCenter) - cubeScale, 0.));   
}

float SDF(vec3 sp) {
    //return min(sphere1(sp), cube1(sp));
    return min(min(min(cube1(sp), cube2(sp)), cube3(sp)), sphere1(sp));
}

vec3 getNorm(vec3 sp) {
    vec3 spPlus = sp + EPSILON;
    vec3 spMinus = sp - EPSILON;
    float x1 = SDF(vec3(spPlus.x, sp.y, sp.z));
    float x0 = SDF(vec3(spMinus.x, sp.y, sp.z));
    float y1 = SDF(vec3(sp.x, spPlus.y, sp.z));
    float y0 = SDF(vec3(sp.x, spMinus.y, sp.z));
    float z1 = SDF(vec3(sp.x, sp.y, spPlus.z));
    float z0 = SDF(vec3(sp.x, sp.y, spMinus.z));
    
    return normalize(vec3(x1-x0, y1-y0, z1-z0));
}

vec4 backgroundSampler(vec3 rd) {
    return texture(iChannel0, rd);
}


vec3 rayMarching(vec3 ro, vec3 rd) {
    vec3 returnColor = vec3(0, 0, 0);
    float weight = 1.0;
    float whiteColorWeight = 1.;
    
    int bounce;
    for(bounce = 0; bounce < MAX_BOUNCE; ++bounce) {
        weight *= 0.8;
        float dist = 0.01;
        bool reachMaxFlag = true;
        for(int i = 0; i < MAX_STEPS; ++i) {
            vec3 sp = ro + rd * dist;
            float deltaDist = SDF(sp);
            dist += deltaDist;
            if(deltaDist < EPSILON) {
                //calcLight
                vec3 normDir = getNorm(sp);
                vec3 viewDir = -rd;
                vec3 halfDir = normalize(viewDir + lightDir);


                vec3 reflDir = reflect(rd, normDir);
                
                float diff;
                #if USE_HALF_LAMBERT
                    diff = max(0., 0.5+0.5*dot(normDir, lightDir));
                #else
                    diff = max(0., dot(normDir, lightDir));
                #endif

                vec3 diffuse = 1. * diffColor * diff;
                vec3 specular = lightColor * pow(max(0., dot(halfDir, normDir)), gloss);
                
                vec3 reflColor = diffuse;

                float fresnel = fresnelScale + (1. - fresnelScale) * pow((1. - dot(viewDir, normDir)), 5.);
                
                if(sphere1(sp) < EPSILON) {
                    return mix(diffuse + specular, backgroundSampler(reflDir).xyz * lightColor, fresnel);
                }

                returnColor = reflColor;
                ro = sp;
                rd = reflDir;
                
                reachMaxFlag = false;
                break;

            }
            else if(dist >= MAX_DISTANCE) {
                break;
            }
        }
        if(reachMaxFlag) {
            return backgroundSampler(rd).xyz;
        }
    }
    return backgroundSampler(rd).xyz;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float angle = iTime;
    vec3 ro = vec3(6.*sin(angle), 1., 6.*cos(angle));
    vec3 camDirection = normalize(sphereCenter - ro);
    vec3 camXAxis = normalize(vec3(cos(angle), 0, -sin(angle)));
    vec3 camYAxis = cross(camXAxis, camDirection);
    
    float nearPlaneHeight = near * tan(radians(fieldOfView / 2.)) * 2.;
    vec2 uv = (fragCoord.xy - iResolution.xy * 0.5) * nearPlaneHeight / iResolution.y; 
    vec3 rd = normalize(camXAxis*uv.x + camYAxis*uv.y + camDirection*near);
    
    fragColor = vec4(rayMarching(ro, rd), 1.);
}