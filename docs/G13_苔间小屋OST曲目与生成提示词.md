# 苔间小屋 OST：把远方寄回家

英文副标题：**Moss & Moments — Letters to a Little Home**

本文件是一套可直接用于音乐生成的创作方案：24首正曲＋3段短音乐。尚未生成音频，未接入Godot。宣传片配乐及合成已由用户自行完成，与本套游戏OST分开。

## 专辑的声音

像木桌上摊开的一本旅行手账：温暖、轻巧，有一点想念，也有一点对明天的好奇。

统一骨架是毛毡钢琴、指弹木吉他、低音单簧管或柔和单簧管、极少量钟琴。保留琴键、拨弦的自然质感，避免过强机械噪声。日常曲旋律稀疏，旅行曲更有记忆点；地域乐器只点一两笔，不把每座城市写成夸张的旅游广告。

全专辑纯器乐，无歌词、念白、合唱、突发强音或大段高潮。雨声、鸟叫、脚步、风铃等环境音留给游戏独立控制，尽量不要烘焙进音乐，以免晴天播雨声、循环时重复同一只鸟叫。

**共同动机的创作提案：**五个音，级数`1–2–3–5–3`，节奏“短、短、长、短、长”，像小蛙走两步又停下来看看。主旋律留出回应的空白。先生成01并选定满意旋律，再把实际旋律当作专辑主题；文字中的级数只是方向，不能保证生成器准确执行或跨曲复现。若所用工具支持参考音频，可使用自己选定的01片段制作变奏；若不支持，用共同音色、节奏与和声气质维持统一。

## 生成方法与参数

- 每首下方英文框是一条**完整Music Caption**，可单独复制；无需再拼接统一前缀。
- Instrumental：开；Lyrics：留空；Batch Size：1；Think：开（页面提供时）。一次先做一条，听过再决定是否重抽。
- 表内时长、BPM、拍号是创作建议。建议时长填Duration；BPM及拍号有对应控件时按表填写，无控件时保留提示词中的描述。调性默认自动，避免强求所有曲目同调。
- 先做01、02、05、15、18五首建立声音标准，其余再分批制作。最长曲若超过工具限制，先生成90–120秒候选，再使用可用的延展功能，或制作较短专辑版本。
- 以下主要按专辑试听版本设计，有自然的开头和收尾。用于游戏时另制作Loop版，去掉长引子与片尾，按乐句边界剪辑并检查接缝；“seamless loop”提示词不能替代实际剪辑验收。
- 建议保留原始最高质量文件及生成提示词、实际Seed和参数。专辑版导出WAV或FLAC留档；游戏版另导出OGG。只拿到MP3时保留原件，转WAV不会恢复已损失的信息。

## 曲目单

以下顺序是专辑听赏顺序，不是游戏必须按序播放的规则。正曲约59分钟。

| # | 中文曲名 / English title | 场景 | 时长 | BPM / 拍号 |
|---|---|---|---|---|
| 01 | 把远方寄回家 / Letters to a Little Home | 标题、主题曲 | 180秒 | 76 / 4/4 |
| 02 | 窗边有一块阳光 / A Patch of Sunlight | 白天小屋、常驻 | 180秒 | 68 / 4/4 |
| 03 | 香草慢慢长 / While the Herbs Grow | 田园 | 150秒 | 82 / 4/4 |
| 04 | 便当里装着晴天 / Sunshine in a Lunchbox | 厨房 | 120秒 | 92 / 4/4 |
| 05 | 今天适合听雨 / A Good Day for Rain | 雨天小屋 | 180秒 | 62 / 4/4 |
| 06 | 灯还为你留着 / A Light Left On | 夜晚、长时间挂机 | 180秒 | 56 / 4/4 |
| 07 | 翻到有风的那一页 / The Page Where the Wind Lives | 每日小书 | 120秒 | 66 / 3/4 |
| 08 | 你说过你喜欢 / The Things You Told Me | 陪伴、记忆本 | 150秒 | 64 / 4/4 |
| 09 | 围巾系好，出发 / Scarf Tied, Off We Go | 行囊、出发主题 | 120秒 | 88 / 6/8 |
| 10 | 溪水把青石磨圆 / Pebbles in the Stream | 溪谷 | 120秒 | 72 / 4/4 |
| 11 | 集市有一杯热茶 / Tea at the Woodland Market | 林间集市、小店备选 | 120秒 | 94 / 4/4 |
| 12 | 山坡借我一点风 / Borrowing a Little Wind | 山坡 | 120秒 | 78 / 6/8 |
| 13 | 西湖把云留住 / Clouds Rest on West Lake | 杭州 | 150秒 | 66 / 4/4 |
| 14 | 洱海边，慢一点 / Take Your Time by Erhai | 大理 | 150秒 | 72 / 6/8 |
| 15 | 东京的最后一班小雨 / The Last Little Rain in Tokyo | 东京 | 150秒 | 80 / 4/4 |
| 16 | 海峡那边也是黄昏 / Dusk Across the Bosphorus | 伊斯坦布尔 | 150秒 | 74 / 6/8 |
| 17 | 巴黎街角，留一张空椅 / An Empty Chair in Paris | 巴黎 | 150秒 | 84 / 3/4 |
| 18 | 极光落进毛线帽 / Aurora in a Woollen Hat | 冰岛 | 180秒 | 58 / 4/4 |
| 19 | 从上海寄出的第一封信 / The First Letter from Shanghai | 上海途中明信片 | 120秒 | 78 / 4/4 |
| 20 | 迪拜河上的金色折痕 / Golden Folds on Dubai Creek | 迪拜途中明信片 | 120秒 | 76 / 4/4 |
| 21 | 伦敦的伞，借你一半 / Half an Umbrella in London | 伦敦途中明信片 | 120秒 | 70 / 4/4 |
| 22 | 北方的房子像盒彩笔 / A Paintbox of Northern Houses | 斯德哥尔摩／哥本哈根 | 150秒 | 74 / 6/8 |
| 23 | 邮戳上的一点想念 / A Little Longing in the Postmark | 通用信件、收藏回顾 | 150秒 | 68 / 4/4 |
| 24 | 门开了，是你回来了 / The Door Opens, You Are Home | 归家、专辑尾曲 | 180秒 | 72 / 4/4 |

## 第一章：小屋里的日子

### 01｜把远方寄回家

主旋律最完整的一首。开头像推开小屋的门，中段有出门的期待，尾声回到熟悉的灯光。这里建立专辑的声音标准。

```text
An original instrumental main theme for Moss & Moments, a cozy watercolor frog life-sim. Warm felt piano introduces a simple five-note rising-and-returning motif with generous pauses, answered by fingerpicked acoustic guitar and soft clarinet. A few glockenspiel notes feel like sunlight on a wooden desk. Gentle 76 BPM, 4/4. Begin intimately, open into a small chamber ensemble in the middle, then return to solo piano and a warm resolved ending. Tender, curious, quietly hopeful. Natural spacious sound, soft dynamics. No vocals, choir, field recordings, heavy drums, or cinematic climax.
```

### 02｜窗边有一块阳光

主界面最常听的底色。比主题曲更少音符，容许玩家不注意音乐，也不会觉得房间空着。

```text
Understated instrumental cottage ambience for a cozy watercolor game. Sparse felt piano fragments, soft fingerpicked nylon-string guitar, occasional low clarinet replies, and a very quiet warm sustained background. 68 BPM in 4/4, relaxed and unhurried. Let short melodic phrases breathe across long spaces; use gentle harmonic changes and subtle variation rather than a prominent repeating hook. Sunlight resting on a wooden floor, safe and lived-in. Even soft dynamics, intimate natural acoustics, a short gentle opening and restrained ending. No vocals, drums, environmental sounds, dramatic builds, or bright piercing notes.
```

### 03｜香草慢慢长

有种下种子的小满足，不做农场竞速感。木质拨弦为主，律动像慢慢浇水。

```text
A gentle instrumental gardening piece for a cozy frog game. Fingerpicked acoustic guitar, soft pizzicato strings, rounded wooden marimba, and small felt-piano answers. 82 BPM, 4/4, lightly bouncing but never hurried. A tiny seed seems to grow through repeating phrases with changing voicings, a quieter middle passage, and a modest warm ending. Keep the melody simple and the texture airy, with restrained low percussion and a natural wooden tone. Friendly, patient, quietly satisfying. No vocals, birdsong, water recordings, sharp bells, busy solos, or energetic pop drums.
```

### 04｜便当里装着晴天

全专辑较活泼的一首，但不闹腾。用短句之间的应答表现摆食材、包饭团的动作感。

```text
A playful but soft instrumental kitchen miniature for a watercolor life-sim. Rounded marimba and pizzicato strings trade short phrases with muted acoustic guitar and warm piano; a tiny brushed rhythm suggests preparing a lunchbox by hand. 92 BPM in 4/4, light and tidy. Introduce a friendly motif, give it two small variations, then settle with a neat gentle cadence. Sunny domestic warmth, modest energy, clear space between instruments. No vocals, cooking sound effects, novelty cartoon whistles, slapstick accents, heavy bass, or loud percussion.
```

### 05｜今天适合听雨

下雨也可以安心待在家。音乐里不放真实雨声，方便游戏天气音独立叠加、停止。

```text
A comforting instrumental for a rainy afternoon inside a tiny cottage. Soft felt piano with widely spaced notes, warm low clarinet, delicate muted guitar, and a faint airy harmonic bed. 62 BPM, 4/4. Gentle suspended chords resolve slowly; a small reassuring melody appears occasionally and leaves room for silence. Reflective but never sorrowful, sheltered and warm. Maintain an even low intensity with a quiet opening and natural soft ending. Clean spacious mix. No actual rain recordings, thunder, vocals, choir, strong percussion, dark drones, or dramatic swells.
```

### 06｜灯还为你留着

夜间和长途等待的常驻音乐。音符少、亮度低，表达“它不在家，但家还在等它”。

```text
A very quiet instrumental nighttime cottage piece. Low-register felt piano, soft nylon-string guitar harmonics, and a restrained warm cello sustain. 56 BPM in 4/4 with a barely felt pulse. Short tender phrases drift through ample silence, with slow warm harmony and occasional familiar rising-and-returning melodic shapes. A lamp is left on for a travelling friend. Peaceful, patient, gently reassuring rather than lonely. Consistently soft dynamics and a long natural final resonance. No vocals, choir, ticking clocks, field recordings, percussion, ominous bass, or sudden high notes.
```

### 07｜翻到有风的那一页

像一本有插图的小书。三拍子很轻，只让人感觉书页在缓缓翻动。

```text
A delicate instrumental reading-room waltz for a cozy illustrated game. Felt piano and lightly plucked harp carry a small curious melody, with a soft clarinet answering at the ends of phrases. 66 BPM in 3/4, gently swaying rather than dancing. Use sparse chamber textures, warm harmonies, a brief wandering middle phrase, and a quiet return. The feeling of opening a well-loved picture book by a window. Intimate and low in intensity. No vocals, page-turning recordings, ticking, music-box harshness, grand orchestral gestures, or busy accompaniment.
```

### 08｜你说过你喜欢

AI陪伴和偏好记忆的情感主题。重点是有人认真听你说话，不用科技感音色强调“大模型”。

```text
A tender instrumental conversation theme for a cozy companion game. Two short felt-piano phrases gently answer each other, joined by soft acoustic guitar and low clarinet. 64 BPM in 4/4. Leave long pauses as if listening carefully before replying; develop the melody through small changes instead of a large emotional climax. Warm, attentive, a little shy, and quietly affectionate. Natural acoustic instruments, balanced soft dynamics, a close and reassuring ending. No vocals, spoken dialogue, digital notification sounds, synthetic robot effects, heavy percussion, or sentimental orchestral swells.
```

## 第二章：背上行囊，慢慢走

### 09｜围巾系好，出发

把小屋旋律稍稍提速。不是英雄踏上征途，而是小蛙检查完便当，认真地迈出门。

```text
A small optimistic instrumental departure theme for a travelling frog. Fingerpicked acoustic guitar leads a buoyant melody, answered by warm clarinet, soft pizzicato strings, and very light brushed percussion. 88 BPM in 6/8, a comfortable walking sway. Suggest a familiar home melody opening into a curious new phrase. Begin simply, add a little forward motion, then finish lightly with room for the journey to continue. Cozy chamber-folk sound, friendly and modest. No vocals, marching drums, triumphant brass, field recordings, or epic adventure climax.
```

### 10｜溪水把青石磨圆

第一次小旅行的小确幸。用琴音表现水面的反光，不直接生成流水音。

```text
A gentle instrumental streamside miniature for a watercolor travel game. Soft acoustic guitar arpeggios, rounded piano droplets, mellow wooden flute, and very sparse low sustained strings. 72 BPM in 4/4. A simple melody wanders slowly and returns, with small rippling variations and plenty of breathing room. Smooth pebbles, clear light, a short peaceful outing close to home. Intimate acoustic production and softly rounded attacks. End with a calm little resolution. No vocals, recorded water, birds, sharp chimes, strong drums, or dramatic development.
```

### 11｜集市有一杯热茶

一点热闹、一点人情味。也可作为叶子小店的备选，避免使用刺激消费的紧张或庆祝感。

```text
A friendly instrumental woodland market tune in a cozy chamber-folk style. Warm clarinet, lightly strummed acoustic guitar, soft pizzicato bass, and a few wooden percussion taps. 94 BPM, 4/4, relaxed with a tiny lilt. Short conversational melodies pass between instruments like neighbours chatting over tea. Include a quieter middle section and a warm understated return. Cheerful but never frantic, small-scale and welcoming. No vocals, crowd recordings, cash-register sounds, circus instruments, brassy fanfares, exaggerated swing, or loud rhythmic accents.
```

### 12｜山坡借我一点风

比溪谷更开阔一些，但保留脚步很小的感觉。旋律上扬后缓缓落下。

```text
An airy instrumental hilltop walk for a cozy frog adventure. Nylon-string guitar, mellow flute, soft felt piano, and thin warm string harmonics. 78 BPM in 6/8 with a relaxed swaying pulse. Let the melody rise gently across a long phrase and settle down again, leaving open space between replies. Fresh, light, quietly curious, never grand. A modest opening grows only slightly before returning to a calm ending. Natural chamber acoustics and soft dynamics. No vocals, wind recordings, forceful percussion, soaring cinematic strings, or heroic fanfares.
```

### 13｜西湖把云留住

在统一的钢琴和吉他骨架上，加少量古筝与柔和笛声。偏当代室内乐，不做宏大古风。

```text
A serene instrumental postcard from West Lake, within a warm acoustic game soundtrack. Felt piano and nylon-string guitar form the foundation; a few delicate guzheng plucks and soft bamboo-flute phrases add restrained local colour. 66 BPM in 4/4. Floating pentatonic touches, unhurried melodic lines, spacious harmonies, and a gentle reflective return. Imagine clouds resting on still water during a quiet personal walk. Small chamber scale, soft natural sound. No vocals, gongs, recorded water, theatrical flourishes, grand historical-drama orchestration, or heavy drums.
```

### 14｜洱海边，慢一点

阳光、湖边、慢行，音乐比西湖更明亮轻松。不声称模拟某个民族的传统乐种。

```text
A sunlit instrumental lakeside travel piece inspired by a slow afternoon at Erhai. Warm fingerpicked acoustic guitar, mellow flute, soft piano, and sparse hand-percussion brushes. 72 BPM in 6/8, easy and gently lilting. Use open melodic intervals and spacious acoustic harmony, with a breezy middle passage and a relaxed homeward return. The feeling of sitting by a lake with nowhere urgent to go. Contemporary intimate chamber-folk, soft and clear. No vocals, field recordings, ceremonial imitation, piercing flute, strong bass, or festival-style percussion.
```

### 15｜东京的最后一班小雨

安静街角的城市夜色。电钢琴稍微加入都市感，避免做成鼓点鲜明的Lo-fi歌单。

```text
A gentle instrumental evening postcard from Tokyo for a cozy travel game. Soft felt piano blends with mellow electric piano, lightly plucked nylon guitar, and occasional restrained vibraphone notes. 80 BPM in 4/4 with very light brushed percussion and warm extended chords. A small wistful melody suggests quiet side streets after a shower, curious and comforting rather than melancholy. Intimate contemporary acoustic texture, clear space, a tender resolved ending. No vocals, train announcements, rain recordings, vinyl crackle, bright city-pop drums, aggressive bass, or anime-style climax.
```

### 16｜海峡那边也是黄昏

用乌德琴与柔和单簧管带出海峡黄昏。仍然像小蛙的私人旅行，不做异域冒险大片。

```text
A warm instrumental dusk postcard from Istanbul. Gentle oud plucking and mellow clarinet sit inside the soundtrack's familiar felt-piano and acoustic-guitar palette, with only a few soft frame-drum touches. 74 BPM in 6/8, a calm swaying motion. Subtle modal colour and conversational melodic replies suggest sitting beside the Bosphorus at sunset. Intimate, curious, peaceful, with a brief reflective middle and a warm quiet ending. No vocals, chants, calls to prayer, crowd recordings, dramatic exotic flourishes, pounding percussion, or cinematic spectacle.
```

### 17｜巴黎街角，留一张空椅

手风琴轻轻出现，像街角有人在远处练习。旋律带一点俏皮，但不是夸张的“法式广告歌”。

```text
A small instrumental Paris cafe waltz for a cozy illustrated travel game. Soft accordion shares a modest melody with felt piano and fingerpicked acoustic guitar; restrained pizzicato bass supports the sway. 84 BPM in 3/4. Warm, gently playful, slightly wistful, like leaving a chair for a friend at a quiet street corner. Use a simple theme, a delicate contrasting phrase, and a relaxed return. Intimate acoustic mix and even soft dynamics. No vocals, cafe recordings, theatrical accordion runs, cabaret brass, fast musette virtuosity, or grand romantic climax.
```

### 18｜极光落进毛线帽

整张专辑最空旷的一首。冷色背景里保留一颗暖色钢琴，远方再冷也不失去家的温度。

```text
A spacious instrumental Iceland night piece for a gentle watercolor travel game. Sparse felt piano remains warm at the centre, surrounded by quiet bowed string harmonics, a faint airy pad, and rare soft bell overtones. 58 BPM in 4/4 with almost no audible beat. Long patient phrases and slowly shifting harmonies suggest aurora above a tiny traveller in a woollen hat. Wonder rather than grandeur, solitude without dread. Gradually reveal a tender melody and let it settle naturally. No vocals, choir, wind recordings, booming sub-bass, dramatic risers, or post-rock climax.
```

## 第三章：途中的邮戳

### 19｜从上海寄出的第一封信

熟悉的远行起点，城市感略带摇摆，音量和演奏规模仍然克制。

```text
A warm instrumental first-letter theme from Shanghai. Gentle piano, mellow clarinet, fingerpicked guitar, and soft upright-bass touches create a small contemporary chamber-jazz palette. 78 BPM in 4/4 with a subtle relaxed swing, never a nightclub groove. A curious melody opens into a warm answer, suggesting golden riverfront light before the next leg of a journey. Keep the texture light, personal, and quietly optimistic, with a soft resolved ending. No vocals, traffic or ferry recordings, vintage noise, big-band brass, busy solos, or loud drums.
```

### 20｜迪拜河上的金色折痕

把注意力放在木船、河湾与傍晚。与伊斯坦布尔相比更少旋律装饰、更轻的拨弦。

```text
A quiet instrumental postcard from Dubai Creek at golden hour. Sparse oud notes, warm acoustic guitar, soft felt piano, and restrained wooden percussion create a gently flowing texture. 76 BPM in 4/4. Use a simple reflective melody with subtle modal turns and generous pauses, as if watching small boats from the riverbank. Sandy warmth and patient curiosity, intimate rather than luxurious. A short understated opening, a lightly varied middle, and a calm ending. No vocals, chants, field recordings, resort dance beats, dramatic desert imagery, heavy bass, or showy percussion.
```

### 21｜伦敦的伞，借你一半

与雨天小屋呼应，带一点不经意的幽默和相伴的暖意。

```text
A gently affectionate instrumental London postcard. Soft felt piano, warm clarinet, fingerpicked guitar, and a restrained cello line share a modest conversational melody. 70 BPM in 4/4 with an easy walking pulse and lightly playful pauses. The feeling of sharing an umbrella during an unhurried riverside stroll, cosy despite the grey sky. Keep the acoustic texture intimate, with mild harmonic surprises, a quiet middle, and a comforting ending. No vocals, rain recordings, clock chimes, traffic, brass marches, grand orchestration, or dramatic melancholy.
```

### 22｜北方的房子像盒彩笔

供斯德哥尔摩与哥本哈根共用的北欧途中主题，以旧城、运河和温暖房子为共同意象；不把两座城市描述成同一个地方。

```text
A light instrumental northern harbour postcard for a cozy travel soundtrack. Warm acoustic guitar and felt piano meet a softly played fiddle, a few delicate glockenspiel notes, and gentle pizzicato bass. 74 BPM in 6/8, relaxed and quietly buoyant. A simple folk-tinged melody suggests colourful houses reflected in calm water and a traveller taking a small break. Airy yet warm, with restrained variations and a soft natural finish. Intimate chamber scale. No vocals, seagull or harbour recordings, fast folk-dance energy, sharp bells, stomping drums, or sweeping cinematic strings.
```

### 23｜邮戳上的一点想念

作为通用读信曲，能承接任何城市。重点是“这张风景是寄给你的”，而不是目的地的宏伟。

```text
A tender instrumental letter-reading theme for Moss & Moments. Felt piano carries a small rising-and-returning melody, softly answered by nylon guitar, clarinet, and occasional harp harmonics. 68 BPM in 4/4. Leave long quiet spaces as if reading a handwritten message slowly; introduce a slightly warmer second statement before a gentle resolved ending. Affectionate, patient, a little homesick but reassuring. Natural close acoustic sound, low intensity throughout. No vocals, paper sound effects, typewriter noises, ticking, strong percussion, or sentimental cinematic swells.
```

### 24｜门开了，是你回来了

主题曲的归家变奏。比01更安定，结尾不用盛大庆祝，只留下“终于又坐在一起了”。

```text
A warm instrumental homecoming finale for a cozy frog life-sim album. Begin with intimate felt piano and fingerpicked guitar, then welcome soft clarinet, restrained cello, and a few glockenspiel touches. 72 BPM in 4/4. A simple rising-and-returning home motif feels familiar, now slower in spirit and more settled; build only to a small affectionate ensemble, then return to piano and let the final warm chord ring naturally. Relief, belonging, quiet joy. No vocals, choir, door sound effects, triumphant drums, grand finale gestures, or abrupt ending.
```

## 附录曲：三次小小的心动

这三段是游戏事件短音乐，不参与常驻随机播放。先生成15–30秒候选（以工具支持为准），再剪出目标长度。不要为了8秒提示音强行要求生成器输出它不支持的时长。

### B01｜叮，一封远方｜A Letter Has Arrived

用途：收到新信，目标3–4秒。响一次即可，读信后不重复。

```text
A very short original instrumental notification cue for a cozy watercolor game. Three softly rounded glockenspiel notes receive a warm felt-piano answer, like a tiny friendly greeting from far away. Place the concise musical gesture near the beginning and leave a clean gentle decay with quiet space afterwards. Tender, light, low in volume, no rhythmic backing. No vocals, actual notification beeps, sharp high frequencies, mail sound effects, dramatic rise, or loud final accent.
```

### B02｜包裹里有一点星光｜A Little Starlight in the Parcel

用途：首次揭晓稀有收藏，目标6–8秒。先好奇、后微笑，避免刺激性的抽卡爆金音效。

```text
A short original instrumental discovery cue for a gentle treasure-collecting game. A curious soft pizzicato phrase pauses, then a small harp arpeggio and warm felt-piano chord reveal a few delicate bell notes. One compact gesture near the beginning, followed by a natural lingering decay. A private little surprise, affectionate and restrained rather than triumphant. No vocals, coin noises, casino effects, explosive impact, risers, booming bass, fanfare, or loud orchestral hit.
```

### B03｜欢迎回家，小旅人｜Welcome Home, Little Traveller

用途：旅行结算、归家提示，目标8–10秒。短曲播完再恢复常驻曲，不与其叠出两个旋律。

```text
A short original instrumental welcome-home cue for a cozy frog companion game. Warm felt piano plays a simple rising-and-returning phrase, answered by soft clarinet and one gentle acoustic-guitar chord. Shape a single compact affectionate greeting near the start, resolve quietly, and allow a clean natural tail. Relief, familiarity, and small everyday happiness. No vocals, door or footstep recordings, victory fanfare, heavy drums, cinematic swell, loud accents, or abrupt cutoff.
```

## 怎么让它成为耐听的游戏配乐

以下为后续接入建议，尚未修改当前游戏：

1. **少切歌。**小屋白天以02为常驻，夜晚06、下雨05；打开厨房、田园、设置等短操作时，优先继续当前曲。03、04可作为长时间停留时的备选或专辑曲，不要求每个菜单必换。
2. **青蛙出门，玩家仍在小屋。**09用于准备远行或短暂出发段；远行中的小屋继续家居氛围。10–22主要在主动打开目的地明信片、旅行回忆时播放，不根据后台途经点强制替换玩家正在听的音乐。
3. **不同明信片有不同声音，但不抢操作。**同一张明信片反复开关不从头重播；快速浏览时保留当前曲，或等待停留5–8秒再切换。上海等途经点曲目对应当前已打开的卡片，而非最终旅行目的地。
4. **让安静也成为内容。**每播完一两首常驻曲，可以留20–40秒环境声；若玩家开启连续播放，则取消这段留白。同曲避免连续重抽。
5. **稀有发现轻轻庆祝。**B02仅在首次揭晓时触发；B01多个邮件同时补投时合并一次。可将BGM临时压低约3–6dB，让短音乐清楚，再平滑恢复。
6. **跨曲不要硬切。**建议3–5秒音量交叉淡化；拍号、调性差异明显时，在稀疏尾声切换。没有对齐和声时不要把两首主旋律长时间叠加。
7. **声音有独立开关。**保留总音量、音乐、环境音、交互音效四项；默认音乐偏轻。与实际点击声、天气声一起试听后确定平衡，而不是只看波形大小。

## 生成与验收顺序

**第一批：**01、02、05、15、18，分别验证主题、耐听常驻、天气、城市与远方。听起来像同一个游戏之后，再生成余下19首和短曲。

**第二批：**03、04、06、07、08、09、23、24，补齐日常与情感叙事。

**第三批：**10–14、16–17、19–22及B01–B03，完成旅行地图与事件音乐。

每条试听检查：有没有混入人声或环境音；高音是否刺耳；中段是否突然变成大编制；连续听10分钟是否疲劳；首尾有没有硬切或噪声。Loop版至少连续播放三遍检查节拍、混响尾巴和音量跳变。检查是在实际音频生成后进行，本方案不代表已经通过听感验收。

建议命名：`MM_01_Letters_to_a_Little_Home_album.wav`、`MM_02_A_Patch_of_Sunlight_loop.ogg`。保留一张记录表：曲号、实际参数、Seed、生成工具/版本、选中版本、时长、原文件路径、循环起止点、备注。不要仅凭Seed认定其他曲目会延续相同旋律。

专辑封面文字建议：**苔间小屋 / 把远方寄回家 / Original Soundtrack**。一句专辑介绍：**“那些没说出口的想念，都被它夹进了寄回家的明信片。”**
