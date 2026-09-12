# G6 美术素材与实际提示词

2026-09-10，使用内置 ImageGen。项目最终资产：

- `assets/items-g6.png`：1536×1024 RGB，6×4 物品图集，24 个插画对象；Godot AtlasTexture 选区并以共享 shader 处理白底。
- `assets/cottage-g6.png`：1536×1024 RGB，从原背景移除固定地毯和左窗台盆栽，方便独立摆放。原 cottage.png 保留。
- `assets/rugs-g6.png`：实际 1254×1254 RGB，2×2 地毯图集；使用前三款，第四款为未上架备用，不宣称已解锁。

未用 Python 编辑图片，Python 仅读取尺寸与模式。图集当前是白底 RGB，不冒称原生透明 PNG。白底在 Godot 显示时淡出，极亮高光也可能受到轻微影响；后续可换成逐件干净 alpha 素材。原 G5 小灯和彩旗延续程序绘制，其小图标与场景形状一致。

## 物品初稿（背景未满足要求，未接入）

Use case: illustration-story. Asset type: production sprite atlas for an original cozy watercolor frog cottage game. Make ONE precisely aligned 6-column by 4-row atlas, exactly 1536x1024 canvas, 24 equal 256x256 cells with NO grid lines and a REAL TRANSPARENT alpha background. Each cell has ONE centered isolated object with generous 35 pixel clear margins, never crossing boundaries, no text or numerals. Consistent charming hand-painted watercolor and pencil, warm cream, sage, honey, apricot palette, soft dark sage contours, readable at small UI sizes. Exact left-to-right row-major order: Row1: sprig of fresh herbs; tied golden rice stalks; two cute brown mushrooms; round orange pumpkin; round wooden herb bento with green vegetables and rice; triangular rice balls wrapped in leaves. Row2: two-tier wooden mushroom bento opened showing rice and mushrooms; rich pumpkin travel meal in a square wood box with pumpkin wedges and rice; smooth blue-green river stone; softly glowing blue crystal stone; small wood-grain teacup; curled old woodland map. Row3: delicate bronze wind chime; golden dandelion seed head; folded lake-blue silk ribbon; small carved lotus-shaped button; pink cherry blossom charm pouch; dark blue star-shaped little bell. Row4: blue-white patterned ceramic shard; turquoise blue eye glass keepsake; green leafy houseplant in terracotta pot; pink flowering houseplant in cream ceramic pot; open illustrated storybook with NO readable text; small straw broom with wooden handle. All 24 objects have matching view and polished storybook item art. No characters, no checkerboard drawn into the image, no backdrop, no lettering, no UI frame. Every object fully contained in its exact cell. These are original assets, not copies of any existing game.

## 透明背景尝试（实际为棋盘格 RGB，未接入）

Edit target: the attached 6x4 sprite atlas. Precise background-extraction edit. Remove ALL colored brown/green/blue background and backdrop glow between objects and replace it with REAL alpha transparency, not white, not black and not a checkerboard illustration. Keep all 24 objects in exactly the same positions, exact 1536x1024 image dimensions, exact 6 columns and 4 rows of 256x256 cells. Preserve watercolor detail, object identities and colors. Ensure each object is fully within its own cell with at least 14 pixels transparent margin, shrinking individual objects slightly within their existing cell if needed. No text. The output is a transparent PNG sprite atlas to overlay onto cream UI cards and a cottage room.

## 最终白底物品图集

Precise edit of supplied sprite atlas. Replace ONLY the gray checkerboard backdrop with perfectly UNIFORM SOLID WHITE #FFFFFF across the entire canvas between all objects. No checkerboard anywhere. No gradients, no colored shadows on the background. Keep all 24 watercolor objects, their exact order, positions and 6 by 4 grid. Keep size 1536x1024. Shrink all objects slightly around the center of their existing 256x256 cell so nothing touches another cell. Every object fully contained. This white-matted atlas will be displayed in white inventory cards in a game. Keep dark outlines and detailed shading inside objects, do not redesign them.

## 可交互小屋底图

Use case: precise-object-edit. Edit target is this exact original cozy cottage game background. Remove ONLY two objects: (1) the large oval woven rug in the center foreground floor, replace it with continuous matching warm wooden floorboards; (2) the single small white-flowering terracotta plant sitting on the LEFT end of the large windowsill, replace it with the matching empty windowsill. Keep the window, books stacked at the RIGHT end of windowsill, desk and open book, bed, door, all other plants, broom, exterior garden and composition exactly the same. Preserve exact 1536x1024 canvas and original watercolor pencil style. Do not add new objects, do not shift camera or recolor scene. This is a clean background layer for separately interactive rug and potted plant.

## 地毯图集

Use case: illustration-story. Asset type: one 2 by 2 atlas of four original cozy game rugs, exactly 1024x1024, four equal 512x512 cells. Each object is a fully visible horizontal oval rug viewed from a slightly elevated three-quarter angle for a cottage wooden floor, elliptical silhouette approximately 430 wide and 270 high, centered in its own cell with ample margins. Pure uniform solid white #FFFFFF backdrop, no grid, no text, no shadows outside the rug, no overlapping cells. Hand-painted watercolor, colored pencil, woven fibers, delicate stitched edge, gentle cozy style. Top left: natural honey straw woven braided rug. Top right: sage green wool rug with a cream botanical leaf border and tiny light flowers. Bottom left: warm apricot terracotta rug with a soft golden sun motif and cream concentric border. Bottom right: muted blue rug with small cream stars and snowflake-like stitches. Match thickness, perspective and size across all four. These are isolated inventory and scene sprites, no room, no humans, no animals.
