// 引擎设置的参数，不可修改

SamplerState screen_texture_sampler : register(s4); // RenderTarget 纹理的采样器
Texture2D screen_texture            : register(t4); // RenderTarget 纹理
cbuffer engine_data : register(b1)
{
    float4 screen_texture_size; // 纹理大小
    float4 viewport;            // 视口
};

// 用户传递的浮点参数
// 由多个 float4 组成，且 float4 是最小单元，最多可传递 8 个 float4

cbuffer user_data : register(b0)
{
    float4   color;
    float4   userdata;
};
#define radius userdata.x
#define alpha userdata.y

// 用户传递的纹理和采样器参数，可用槽位 0 到 3

// 为了方便使用，可以定义一些宏


// 不变量

static const float my_PI = 3.14159265f;

// 主函数

struct PS_Input
{
    float4 sxy : SV_Position;
    float2 uv  : TEXCOORD0;
    float4 col : COLOR0;
};
struct PS_Output
{
    float4 col : SV_Target;
};

#define RADCOUNT 16

static const float invradcount = 90.0/RADCOUNT;

PS_Output main(PS_Input input)
{
    float offset = radius/screen_texture_size.x;
    float4 tex_col = screen_texture.Sample(screen_texture_sampler, input.uv);
    float4 orig_col = tex_col;
    for (float i = 0; i < RADCOUNT; i++){
        tex_col.a += screen_texture.Sample(screen_texture_sampler, input.uv + float2(offset * cos(my_PI * i * 2.0 / RADCOUNT), offset * sin(my_PI * i * 2.0 / RADCOUNT))).a * invradcount;
        tex_col.a = min(tex_col.a, color.a);
    }
    tex_col.a = min(tex_col.a + orig_col.a, 1.0f);
    tex_col.rgb = lerp(color.rgb,orig_col.rgb,orig_col.a);
    tex_col.rgb *= tex_col.a;

    PS_Output output;
    output.col = min(tex_col, float4(1.0f,1.0f,1.0f,1.0f));
    output.col *= alpha;
    return output;
}

// lua 侧调用（仅用于说明参数如何传递，并非可正常运行的代码）
/*

lstg.LoadTexture("texture0", "xxx.png")
lstg.LoadTexture("texture1", "yyy.png")
lstg.CreateRenderTarget("rendertarget2")
lstg.CreateRenderTarget("rendertarget3")

lstg.CreateRenderTarget("screen")
lstg.LoadFX("template", "template.hlsl")

lstg.PushRenderTarget("screen")
lstg.RenderClear(lstg.Color(255, 0, 0, 0))
lstg.PopRenderTarget()
lstg.PostEffect("template", "screen", 6, "mul+alpha", -- 着色器名称，屏幕渲染目标，采样器类型，（最终绘制出来的）混合模式
    -- 浮点参数
    {
        { 1.0f, 1.0f, 1.0f, 0.0f },         -- my_color3(r, g, b), timer
        { 0.0f, 0.0f, 0.0f, 1.0f },         -- my_color4(r, g, b, a)
        { 100.0f, 100.0f, -50.0f, -50.0f }, -- my_pos2_1(x, y), my_pos2_2(x, y)
        { 0.0f, 1280.0f, 0.0f, 960.0f },    -- my_rect(l, r, b, t)

        -- my_matrix
        { 1.0f, 0.0f, 0.0f, 0.0f },
        { 0.0f, 1.0f, 0.0f, 0.0f },
        { 0.0f, 0.0f, 1.0f, 0.0f },
        { 0.0f, 0.0f, 0.0f, 1.0f },
    },
    -- 纹理与采样器类型参数
    {
        { "texture0", 6 },
        { "texture1", 6 },
        { "rendertarget2", 6 },
        { "rendertarget3", 6 },
    }
)

*/
