"""Read-only credential pattern audit. Reports locations, never matched values."""
from pathlib import Path
import io, json, re, subprocess, zipfile
ROOT = Path(__file__).resolve().parents[1]
PATTERNS = {
    "token": re.compile(rb"(?:sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})"),
    "private-key": re.compile(rb"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----[\r\n]+[A-Za-z0-9+/=\r\n]{64,}-----END (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    "literal-key": re.compile(rb"(?:api_key|DEEPSEEK_API_KEY|OPENAI_API_KEY)[\"']?\s*[:=]\s*[\"'][A-Za-z0-9_./+:-]{20,}[\"']", re.I),
}
DENIED = re.compile(r"(?:^|/)(?:\.local|\.godot|saves|slots)(?:/|$)|(?:^|/)(?:\.env(?:\..*)?|ai-(?:image-)?settings\.cfg|ai-key[^/]*|proxy-token|moss_save[^/]*\.json)$|\.(?:enc|dpapi|pem|key)$", re.I)
def forbidden(name, exported=False):
    # These are required Godot runtime assets, not editor/user configuration.
    if exported and (re.fullmatch(r"\.godot/imported/[^/]+\.(?:ctex|oggvorbisstr)", name) or re.fullmatch(r"\.godot/exported/[^/]+/[^/]+\.scn", name) or name in [".godot/global_script_class_cache.cfg", ".godot/uid_cache.bin"]):
        return False
    return bool(DENIED.search(name.replace("\\", "/"))) and not name.endswith(".env.example")
def scan(data, location, hits):
    for kind, pattern in PATTERNS.items():
        if pattern.search(data): hits.append({"kind":kind,"location":location})
def scan_archive(data, location, hits):
    count=0
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        for info in archive.infolist():
            if info.is_dir(): continue
            name=location+"!"+info.filename
            if forbidden(info.filename, exported=True): hits.append({"kind":"private-file","location":name})
            content=archive.read(info)
            if info.filename.endswith(".zip"):
                count += scan_archive(content,name,hits)
            else: scan(content,name,hits)
            count += 1
    return count
def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--label', default='G18')
    label = parser.parse_args().label
    assert label.isalnum()
    hits=[]
    paths=subprocess.check_output(["git","ls-files","--cached","--others","--exclude-standard","-z"],cwd=ROOT).decode().split("\0")
    for path in filter(None,paths):
        if forbidden(path): hits.append({"kind":"private-file","location":path})
        if (ROOT/path).is_file(): scan((ROOT/path).read_bytes(),path,hits)
    rows=subprocess.check_output(["git","rev-list","--objects","--all"],cwd=ROOT).splitlines()
    proc=subprocess.Popen(["git","cat-file","--batch"],cwd=ROOT,stdin=subprocess.PIPE,stdout=subprocess.PIPE)
    blobs=0
    for row in rows:
        oid,_,name=row.partition(b" ")
        proc.stdin.write(oid+b"\n");proc.stdin.flush()
        header=proc.stdout.readline().split();data=proc.stdout.read(int(header[2]));proc.stdout.read(1)
        if header[1]!=b"blob": continue
        blobs+=1
        location="history:"+oid.decode()+":"+name.decode("utf-8","replace")
        if forbidden(name.decode("utf-8","replace")): hits.append({"kind":"private-history-file","location":location})
        scan(data,location,hits)
    proc.stdin.close();proc.wait()
    packages={}
    for channel in ["Release","Development"]:
        path=ROOT/"dist"/f"Moss-{channel}-{label}-Audio-Windows.zip"
        packages[path.name]=scan_archive(path.read_bytes(),path.name,hits)
    report={"result":"PASS" if not hits else "REVIEW_REQUIRED","working_files":len([p for p in paths if p]),"history_blobs":blobs,"package_members_including_nested":packages,"matches":hits,"scope":"Known token/private-key/literal-key patterns and private filenames; no secret values printed. Screenshots reviewed separately."}
    (ROOT/"artifacts").mkdir(exist_ok=True)
    (ROOT/"artifacts/publish-audit.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
    print(json.dumps(report,ensure_ascii=False))
    return 1 if hits else 0
if __name__=="__main__": raise SystemExit(main())
