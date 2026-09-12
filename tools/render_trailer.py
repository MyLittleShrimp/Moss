"""Compose authentic Godot movie capture into a 16:9 social trailer.
Requires Pillow and imageio-ffmpeg in .tools/video (no online services).
"""
from pathlib import Path
import json
import argparse
import subprocess
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'artifacts/promo'
sys.path.insert(0, str(ROOT / '.tools/video'))
import imageio_ffmpeg
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
SCENES = [
    (0, 4, '一只小蛙，\n把日子过成诗。', '苔间小屋', 'AI 陪伴 · 治愈养成', 'WELCOME HOME'),
    (4, 9, '种下今天，\n等一份小收成。', '八种作物，慢慢长大。', '种植 / 收获', '01  GROW'),
    (9, 14, '把田园的香气，\n装进便当。', '不同食材，做不同旅行餐。', '烹饪 / 准备行囊', '02  COOK'),
    (14, 19, '备好行囊，\n让它去看世界。', '九处目的地，各有惊喜。', '随机旅程 / 未知归期', '03  EXPLORE'),
    (19, 25, '它还没到远方，\n思念先到了。', '沿途城市，随机寄来信。', '途中明信片 / 旅行寄语', '04  LETTERS'),
    (25, 31, '这次的包裹，\n藏着什么？', '拆开之前，留一点悬念。', '神秘收藏 / 稀有发现', '05  DISCOVER'),
    (31, 35, '把旅行的收获，\n穿在身上。', '发现宝物，解锁新装扮。', '收藏奖励 / 小屋装饰', '06  MAKE IT YOURS'),
    (35, 39, '回到小屋，\n翻开今日小书。', '读书、布置，也陪它发会儿呆。', '每日小书 / 温柔日常', '07  SLOW LIVING'),
    (39, 43, '接入你的 AI，\n慢慢熟悉彼此。', '云端 API 或本机 Ollama。', '自备模型 / 偏好记忆', '08  YOUR COMPANION'),
    (43, 47, '苔间小屋', 'MOSS & MOMENTS', '种一点生活，等一封远方。', 'FOLLOW THE JOURNEY'),
]

def font(size, bold=False):
    return ImageFont.truetype('C:/Windows/Fonts/msyhbd.ttc' if bold else 'C:/Windows/Fonts/msyh.ttc', size)

def cards():
    OUT.mkdir(parents=True, exist_ok=True)
    ink, muted = '#334d3e', '#758570'
    for i, (start, end, title, detail, tags, kicker) in enumerate(SCENES):
        im = Image.new('RGB', (1920, 1080), '#f5f2e7')
        d = ImageDraw.Draw(im)
        d.ellipse((-260, 690, 560, 1510), fill='#e3e8d6')
        d.ellipse((1440, -460, 2350, 380), fill='#e9e5d4')
        d.rounded_rectangle((64, 59, 116, 111), radius=20, fill=ink)
        d.text((77, 65), '苔', font=font(28, True), fill='#f5f2e7')
        d.text((132, 63), '苔间小屋', font=font(29, True), fill=ink)
        d.text((554, 72), 'MOSS & MOMENTS  /  GAMEPLAY PREVIEW', font=font(20), fill=muted)
        d.rounded_rectangle((542, 116, 1882, 961), radius=15, fill='#d6dccd')
        d.rectangle((550, 124, 1874, 954), fill='#ffffff')
        d.text((65, 246), kicker, font=font(21, True), fill=muted)
        d.line((65, 296, 142, 296), fill='#b39560', width=4)
        d.multiline_text((61, 345), title, font=font(49, True), fill=ink, spacing=23)
        d.text((65, 534), detail, font=font(24), fill=ink)
        d.text((65, 608), tags, font=font(22), fill=muted)
        if i == 9:
            d.rounded_rectangle((65, 700, 383, 766), radius=32, fill=ink)
            d.text((99, 715), '关注开发进展', font=font(30, True), fill='#ffffff')
        else:
            d.text((65, 851), '%02d' % (i + 1), font=font(67), fill='#a6b19b')
            d.text((169, 899), '/  一段有来信的慢生活', font=font(20), fill=muted)
        d.text((554, 994), '开发中实机画面 · 演示存档 · 部分流程加速', font=font(22), fill=muted)
        d.text((66, 1000), 'AI 陪伴  ×  旅行养成', font=font(21), fill=ink)
        for j in range(10):
            x = 1520 + j * 34
            d.rounded_rectangle((x, 1005, x + 22, 1011), radius=3, fill=ink if j == i else '#cdd4c4')
        im.save(OUT / f'card-{i:02d}.png')
    lines = []
    for i, (start, end, *_) in enumerate(SCENES):
        lines += [f"file 'card-{i:02d}.png'", f'duration {end-start}']
    lines += ["file 'card-09.png'"]
    (OUT / 'cards.txt').write_text('\n'.join(lines), encoding='utf-8')
    srt = []
    def ts(t): return f'00:00:{t:02d},000'
    for i, (start, end, title, detail, tags, kicker) in enumerate(SCENES):
        srt.append(f'{i+1}\n{ts(start)} --> {ts(end)}\n{title.replace(chr(10), "")}\n{detail}\n')
    (OUT / 'Moss-and-Moments-zh.srt').write_text('\n'.join(srt), encoding='utf-8-sig')
    (OUT / 'storyboard.json').write_text(json.dumps(SCENES, ensure_ascii=False, indent=2), encoding='utf-8')

def render():
    cards()
    command = [FFMPEG, '-y', '-hide_banner', '-i', str(OUT/'gameplay.avi'),
        '-f', 'concat', '-safe', '0', '-i', str(OUT/'cards.txt'),
        '-filter_complex', '[0:v]scale=1320:826:flags=lanczos,setsar=1[game];[1:v]fps=30[base];[base][game]overlay=552:126,fade=t=in:st=0:d=0.5,fade=t=out:st=46:d=1,scale=out_range=tv:out_color_matrix=bt709,setparams=range=limited:color_primaries=bt709:color_trc=bt709:colorspace=bt709[v]',
        '-map', '[v]', '-an', '-t', '47', '-c:v', 'libx264', '-preset', 'medium', '-crf', '18',
        '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(OUT/'Moss-and-Moments-16x9-silent.mp4')]
    subprocess.run(command, check=True)

def add_music(path):
    """Use only the separately approved and exported soundtrack."""
    subprocess.run([FFMPEG, '-y', '-hide_banner', '-i', str(OUT/'Moss-and-Moments-16x9-silent.mp4'),
        '-i', str(Path(path).resolve()), '-map', '0:v', '-map', '1:a', '-c:v', 'copy',
        '-af', 'loudnorm=I=-19:TP=-1.5:LRA=9,afade=t=in:d=0.6,afade=t=out:st=43:d=2,apad,atrim=duration=47',
        '-c:a', 'aac', '-b:a', '192k', '-ar', '48000', '-ac', '2', '-t', '47', '-movflags', '+faststart',
        str(OUT/'Moss-and-Moments-16x9.mp4')], check=True)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--music', help='Approved local soundtrack; mux into the existing silent master')
    args = parser.parse_args()
    if args.music: add_music(args.music)
    else: render()
