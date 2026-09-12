"""Verify audio resources in both built packs, then archive portable game folders."""
from pathlib import Path
import json, zipfile
root = Path(__file__).resolve().parents[1]
catalog = json.loads((root/'assets/audio/catalog.json').read_text(encoding='utf-8'))
for channel in ['Release', 'Development']:
    target = root/'dist'/('Moss-'+channel)
    with zipfile.ZipFile(target/'game.zip') as archive:
        names = archive.namelist()
        assert 'assets/audio/catalog.json' in names
        assert not any(n.startswith(('OST/', 'SoundFX/')) for n in names)
        for entry in catalog.values():
            path = entry['path'].removeprefix('res://')
            assert path+'.import' in names or path in names, path
        assert len([n for n in names if n.endswith('.oggvorbisstr')]) == 33
    destination = root/'dist'/f'Moss-{channel}-G14-Audio-Windows.zip'
    with zipfile.ZipFile(destination, 'w', zipfile.ZIP_DEFLATED, compresslevel=3) as archive:
        for name in ['Moss.exe', 'game.zip', 'Start.cmd', '开始游玩.txt', 'GODOT-LICENSE.txt', 'GODOT-COPYRIGHT.txt']:
            archive.write(target/name, arcname=f'Moss-{channel}/{name}')
    print('G14_PACKAGE_AUDIO_PASS', channel, '33 streams; no original masters;',destination.stat().st_size, flush=True)
