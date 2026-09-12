# G7 整景素材

2026-09-11。使用 imagegen 技能及 ImageGen 编辑工具，以 `assets/cottage-g6.png` 为唯一参考，分别生成六张完整小屋。原始生成文件保留，项目复制为 `assets/rooms/{leaf|flower}-{window|desk|door}.png`；1536×1024 PNG，不依赖透明背景，不做程序抠图。

运行时按已购植物与位置整幅替换；`empty` 使用原 `cottage-g6.png`。相机、家具与光照要求一致，仍可能有生成式局部差异。扫帚改为 Godot 原生线条，不是新的 ImageGen 素材。

## 实际提示词

### leaf-window

Precise object edit. Use this exact original cottage scene as the edit target. Add ONE modest leafy green houseplant in an earthy terracotta pot on the empty LEFT portion of the large windowsill, at original image pixel approximately (282,270), fully resting on the sill, tiny size matching the stack of books at the right. Render it as part of the SAME watercolor painting: muted natural sage leaves, warm ambient afternoon light, correct perspective and contact shadows, same detail and paper grain, no sticker outline or white halo, not oversized or bright. Preserve ALL other furniture, floorboards, exterior garden, lighting, camera and 1536x1024 composition exactly. Floor remains empty with NO rug, no frog or UI. Do not rearrange the room. Output a complete scene background, not an isolated asset.

### flower-window

Precise object edit of this exact cottage background. Add ONE small pot of muted pink wildflowers with sage leaves in an earthy ceramic pot on the empty LEFT portion of the large windowsill, at original image pixel approximately (282,270), fully resting on the sill, tiny size matching the stack of books at the right. Paint this as part of the SAME watercolor scene, correct warm afternoon light, perspective, contact shadows and muted palette, no white halo or sticker outline. Preserve ALL other furniture, floorboards, exterior garden, camera and 1536x1024 composition. No rug, no frog, no UI. Output full room.

### leaf-desk

Precise object edit. Use this exact original cottage scene as the edit target. Add ONE modest leafy green houseplant in an earthy terracotta pot on the RIGHT edge of the wooden writing desk, approximately (651,270), keeping the open book accessible, small enough not to crowd the desktop. Render it as part of the SAME watercolor painting: muted natural sage leaves, warm ambient afternoon light, correct perspective and contact shadows, same detail and paper grain, no sticker outline or white halo, not oversized or bright. Preserve ALL other furniture, floorboards, exterior garden, lighting, camera and 1536x1024 composition exactly. Floor remains empty with NO rug, no frog or UI. Do not rearrange the room. Output a complete scene background, not an isolated asset.

### flower-desk

Precise object edit of this exact cottage background. Add ONE small pot of muted pink wildflowers with sage leaves in an earthy ceramic pot on the RIGHT edge of the wooden writing desk, approximately (651,270), keeping the open book accessible, small enough not to crowd the desktop. Paint this as part of the SAME watercolor scene, correct warm afternoon light, perspective, contact shadows and muted palette, no white halo or sticker outline. Preserve ALL other furniture, floorboards, exterior garden, camera and 1536x1024 composition. No rug, no frog, no UI. Output full room.

### leaf-door

Precise object edit. Use this exact original cottage scene as the edit target. Add ONE modest leafy green houseplant in an earthy terracotta pot on top of the green cabinet next to the doorway, approximately (954,347), replacing the small existing flowers there, fully resting on the cabinet surface. Render it as part of the SAME watercolor painting: muted natural sage leaves, warm ambient afternoon light, correct perspective and contact shadows, same detail and paper grain, no sticker outline or white halo, not oversized or bright. Preserve ALL other furniture, floorboards, exterior garden, lighting, camera and 1536x1024 composition exactly. Floor remains empty with NO rug, no frog or UI. Do not rearrange the room. Output a complete scene background, not an isolated asset.

### flower-door

Precise object edit of this exact cottage background. Add ONE small pot of muted pink wildflowers with sage leaves in an earthy ceramic pot on top of the green cabinet next to the doorway, approximately (954,347), replacing the small existing flowers there, fully resting on the cabinet surface. Paint this as part of the SAME watercolor scene, correct warm afternoon light, perspective, contact shadows and muted palette, no white halo or sticker outline. Preserve ALL other furniture, floorboards, exterior garden, camera and 1536x1024 composition. No rug, no frog, no UI. Output full room.

