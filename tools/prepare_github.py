"""Prepare audited source snapshot and Windows release attachments; never pushes."""
from pathlib import Path
import hashlib, re, shutil, subprocess, sys, zipfile
ROOT=Path(__file__).resolve().parents[1]
subprocess.run([sys.executable,str(ROOT/"tools/audit_publish.py")],cwd=ROOT,check=True)
OUT=ROOT/"dist/GitHub-Upload"
OUT.mkdir(parents=True,exist_ok=True)
for link in re.findall(r"!\[[^]]*\]\(([^)]+)\)",(ROOT/"README.md").read_text(encoding="utf-8")):
    assert (ROOT/link).is_file(),link
files=subprocess.check_output(["git","ls-files","-z"],cwd=ROOT).decode().split("\0")
source=OUT/"Moss-and-Moments-Source-G18.zip"
with zipfile.ZipFile(source,"w",zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for name in filter(None,files):
        if (ROOT/name).is_file(): z.write(ROOT/name,"Moss-and-Moments/"+name)
artifacts=[source]
for ch in ["Release","Development"]:
    path=ROOT/"dist"/f"Moss-{ch}-G18-Audio-Windows.zip"
    target=OUT/path.name
    shutil.copy2(path,target)
    artifacts.append(target)
shutil.copy2(ROOT/"docs/GITHUB_RELEASE_NOTES.md",OUT/"RELEASE_NOTES.md")
shutil.copy2(ROOT/"docs/GITHUB_UPLOAD.md",OUT/"UPLOAD_GUIDE.md")
shutil.copy2(ROOT/"artifacts/publish-audit.json",OUT/"AUDIT.json")
(OUT/"SHA256SUMS.txt").write_text("\n".join(hashlib.file_digest(p.open("rb"),"sha256").hexdigest()+"  "+p.name for p in artifacts)+"\n",encoding="utf-8")
with zipfile.ZipFile(source) as z:
    assert "Moss-and-Moments/README.md" in z.namelist()
    assert sum(n.startswith("Moss-and-Moments/docs/images/") for n in z.namelist())==6
print("GITHUB_READY",OUT,"source files",len([f for f in files if f]))
