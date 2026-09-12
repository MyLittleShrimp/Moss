# 美术来源与实际提示词

## G6 图文与可交互小屋 · 2026-09-10

新增 `assets/items-g6.png`、`assets/cottage-g6.png`、`assets/rugs-g6.png`。均使用内置 ImageGen，最终项目资产为 RGB；物品 / 地毯白底由 Godot 共享 shader 在显示时处理。实际五次生成 / 编辑提示、尺寸、通道与未采用结果说明见 [G6_ASSETS.md](G6_ASSETS.md)。未把棋盘格 RGB 冒充透明素材。

## G5 明信片图集 · 2026-09-10

使用内置 ImageGen，生成原创 `assets/postcards.png`（1536×1024），3 列 × 2 行，每格 512×512。顺序为溪谷、林间集市、山坡、杭州西湖、东京、伊斯坦布尔。运行时使用 AtlasTexture 区域显示，未用 Python 改图。图集预先生成，玩家到访解锁；不表示每趟实时调用图片模型。

生成返回文件：`exec-42447977-9adf-4681-8f9d-331ff465240f.png`。没有输入原版游戏截图或借用其角色。

实际提示词：

Use case: illustration-story. Asset: a precisely aligned 3-column by 2-row atlas of SIX original collectible travel postcard illustrations for a cozy hand-painted frog travel game. Full 1536x1024 landscape canvas divided into six equal rectangular panels of 512x512, no gutters, no borders, no text or lettering. Each panel must be self-contained and not cross its boundary. Warm watercolor, colored pencil, subtle paper grain, sage green and apricot accents, playful miniature details, gentle healing mood, no humans, no copyrighted game designs. Top left: peaceful forest creek, rounded blue green stones, tiny wooden bridge, raindrops on large leaves. Top middle: woodland market tea stall with little cups and hanging bunting. Top right: golden grassy hill with dandelion seeds and a delicate wind chime on a branch. Bottom left: Hangzhou-inspired West Lake scene, willow branches, arched stone bridge and distant pavilion. Bottom middle: Tokyo-inspired red lattice tower amongst cherry blossoms and quiet narrow street with lanterns. Bottom right: Istanbul-inspired Bosphorus waterfront, domed skyline, blue-and-white ceramics and a ferry under a warm sunset. Each illustration has one tiny ORIGINAL sage-green frog traveler wearing an apricot scarf and a leaf-shaped satchel, looking toward the scene, small in the composition. Attractive collectible storybook pictures, not a UI mockup. Exact regular 3 by 2 grid.

G5 新增绿植、小灯、彩旗、季节枝叶目前由 `house_decor.gd` 程序绘制，属于功能占位，未宣称是 ImageGen 水彩家具或成套角色皮肤。

## 首版背景与角色

日期：2026-09-09。使用内置 ImageGen；未调用外部图片 API。两张图均为本项目原创生成，未输入原作游戏画面。

- `assets/cottage.png`：1536×1024，小屋和三块庭院地的单层背景。独立角色在 Godot 中叠加。暂未拆分前景遮挡层。
- `assets/frog.png`：1230×1278，RGBA，alpha 范围 0–255；围巾与叶形包的苔苔角色。当前只有一个姿势，呼吸、晃动、移动使用程序补间；不宣称完整逐帧动画已完成。

## 实际生成提示词

### Cottage

Use case: illustration-story. Asset type: original 2D Godot cozy pet game background, landscape 1536x1024. Create an exquisitely charming hand painted storybook cutaway of a tiny forest cottage and attached little garden, no characters. Warm cream plaster, sage green trim, honey wooden floor, soft pencil linework and watercolor paper texture, gentle afternoon light. Composition: interior occupies left two thirds; a broad arched blue-green window on back left wall with a clear low windowsill for a small collectible; a tiny bed against far left, low reading table toward the back, curved doorway in rear center-right; open unobstructed warm oval woven rug on floor in lower middle LEFT where a separately animated pet will walk; on right third outside cottage show exactly three small empty garden soil patches and stepping stones, leafy greenery framing edges. Fixed slightly elevated three-quarter game view, clear floor plane, coherent perspective. Foreground low plants only at corners. Empty floor must remain spacious for interactive pet. Beautiful detailed environment with restrained clutter, soft warm highlights, no UI, no lettering, no logos, no watermarks, no animals, no frogs. Entire image finished game art not a mockup, no external frame.

### Frog

Use case: illustration-story. Asset type: single original 2D game character sprite with REAL TRANSPARENT alpha background. A tiny very cute round sage-green frog companion standing upright, full body, front three-quarter view facing slightly right, two large raised eyes with warm black pupils, cream oval belly, small gentle smile, tiny rounded feet and hands. Wears a short muted apricot yellow scarf and a little leaf-shaped green crossbody satchel with a brown strap. Original storybook design, hand-painted watercolor and colored-pencil outlines, soft subtle paper-textured body, matching warm cozy cottage game illustration, soft top-left daylight. Entire frog including feet and scarf visible, centered, generous empty transparent margin, no ground scenery, no props outside body, no letters, no watermark, no frame, no grid, one character only, no shadow extending outside sprite. Clear silhouette suitable for game animation with programmatic bob and tilt. Transparent background mandatory.
