# G8 换装素材

2026-09-12，使用内置 ImageGen 编辑工具（imagegen 技能），未使用 CLI。编辑参考为 `assets/frog.png`，输出复制进项目，原图不覆盖。

| 路径 | 装扮 |
| --- | --- |
| `assets/outfits/scarf.png` | 湖色丝围巾 |
| `assets/outfits/hat.png` | 山风探险帽 |
| `assets/outfits/gloves.png` | 星夜针织手套 |
| `assets/outfits/pack.png` | 蜗牛探险背包 |

四图均为1230×1278 RGBA，角点alpha=0，保留真实透明通道；未做白底shader或程序抠图。分别打开检查角色身份、完整身体、装扮与边缘，并在原生小屋截图检查显示。整体替换角色sprite，每次一套；没有分部件混搭或动态穿衣动画。明信片继续使用已有 `assets/postcards.png`，本轮无需新生成风景。

## 实际提示词

### scarf

Use case: identity-preserve. Edit target is this exact watercolor frog sprite. Replace the yellow scarf with a flowing muted turquoise silk scarf with subtle lotus embroidery. Keep leaf bag. Preserve this exact character, eyes, face, body, smile, full-body standing pose, feet placement and watercolor paper texture. One character only, full body centered with generous transparent margin, same relative size. TRUE transparent PNG alpha background, no checkerboard, no solid backdrop, no text, no white halo, no ground shadow. Game costume sprite.

### hat

Use case: identity-preserve. Edit target is this exact watercolor frog sprite. Add a small soft russet explorer hat with a tiny feather, fitting between and behind the eyes, never covering eyes. Keep original scarf and leaf bag. Preserve this exact character, eyes, face, body, smile, full-body standing pose, feet placement and watercolor paper texture. One character only, full body centered with generous transparent margin, same relative size. TRUE transparent PNG alpha background, no checkerboard, no solid backdrop, no text, no white halo, no ground shadow. Game costume sprite.

### gloves

Use case: identity-preserve. Edit target is this exact watercolor frog sprite. Put knitted plum mittens with a tiny cream star on BOTH hands, visibly covering the hands. Keep original yellow scarf and leaf bag. Preserve this exact character, eyes, face, body, smile, full-body standing pose, feet placement and watercolor paper texture. One character only, full body centered with generous transparent margin, same relative size. TRUE transparent PNG alpha background, no checkerboard, no solid backdrop, no text, no white halo, no ground shadow. Game costume sprite.

### pack

Use case: identity-preserve. Edit target is this exact watercolor frog sprite. Replace the small leaf shoulder bag with a clearly visible ochre canvas explorer backpack on the frog's left silhouette, rolled blue blanket and map peeking out, brown straps. Keep original yellow scarf. Preserve this exact character, eyes, face, body, smile, full-body standing pose, feet placement and watercolor paper texture. One character only, full body centered with generous transparent margin, same relative size. TRUE transparent PNG alpha background, no checkerboard, no solid backdrop, no text, no white halo, no ground shadow. Game costume sprite.

