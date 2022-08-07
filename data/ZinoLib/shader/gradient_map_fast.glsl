varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

uniform sampler2D u_texture;
uniform vec4 colorB;
uniform vec4 colorW;

void main()
{
    vec4 texcol = v_fragmentColor * texture2D(u_texture, v_texCoord);
    gl_FragColor = mix(colorB,colorW,texcol.r);
    gl_FragColor.a *= texcol.a;
}
