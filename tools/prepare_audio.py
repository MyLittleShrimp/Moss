"""Build game-ready audio copies; never modify the user's OST/SoundFX masters."""
from pathlib import Path
import json, re, subprocess, sys
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools/video'))
import imageio_ffmpeg
ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
out = ROOT / 'assets/audio'
out.mkdir(parents=True, exist_ok=True)
manifest = {}
sources = []
for source in sorted((ROOT/'OST').rglob('*.mp3')):
    match = re.match(r'(\d{2})', source.name)
    ident = 'music_' + match[1] if match else 'main_theme'
    sources.append((ident, source, 'music', None))
effects = {'风声':('wind','ambient',None), '森林环境':('forest','ambient',None),
    '森林田野鸟鸣':('birds','ambient',None), '溪流':('stream','ambient',None),
    '雨声 小雨淅淅沥沥':('rain','ambient',None), '收到信':('mail','effect',4),
    '揭晓收藏':('discover','effect',8), '欢迎回家':('welcome','effect',10)}
for stem, (ident, kind, length) in effects.items():
    sources.append((ident, ROOT/'SoundFX'/(stem+'.mp3'), kind, length))
for ident, source, kind, length in sources:
    assert source.is_file(), source
    target = out/(ident+'.ogg')
    filters = []
    if length:
        filters += ['silenceremove=start_periods=1:start_duration=0.05:start_threshold=-45dB', f'atrim=duration={length}', 'asetpts=PTS-STARTPTS']
    filters += [f'loudnorm=I={-27 if kind == "ambient" else -21}:TP=-2:LRA=9']
    if length: filters += ['afade=t=in:d=0.04', f'afade=t=out:st={length-0.7}:d=0.7']
    command = [ffmpeg,'-y','-hide_banner','-i',str(source),'-vn','-af',','.join(filters),
        '-ar','48000','-ac','2','-c:a','libvorbis','-q:a','4',str(target)]
    result = subprocess.run(command, capture_output=True, text=True, encoding='utf-8', errors='replace')
    if result.returncode: raise RuntimeError(result.stderr)
    manifest[ident] = {'path':'res://assets/audio/'+target.name,'title':source.stem,
        'source':str(source.relative_to(ROOT)), 'kind':kind, 'cue_seconds':length}
    print('AUDIO_READY',ident,target.stat().st_size,flush=True)
(out/'catalog.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print('AUDIO_PREPARE_PASS',len(manifest))
