import io
import unittest
import zipfile
from tools.audit_publish import scan, scan_archive, forbidden

class PublishAuditTests(unittest.TestCase):
    def test_token_redacted(self):
        hits=[]
        secret=b"sk-" + b"a"*32
        scan(secret,"fixture",hits)
        self.assertEqual(hits,[{"kind":"token","location":"fixture"}])
        self.assertNotIn(secret.decode(),str(hits))
    def test_runtime_allowlist_is_narrow(self):
        self.assertFalse(forbidden(".godot/imported/music.ogg-a.oggvorbisstr",True))
        self.assertTrue(forbidden(".godot/editor/state.cfg",True))
        self.assertTrue(forbidden(".godot/imported/ai-key.enc",True))
        self.assertTrue(forbidden("ai-settings.cfg",True))
    def test_nested_archive(self):
        inner=io.BytesIO()
        with zipfile.ZipFile(inner,"w") as z: z.writestr("ai-settings.cfg",b"sk-"+b"b"*32)
        outer=io.BytesIO()
        with zipfile.ZipFile(outer,"w") as z: z.writestr("game.zip",inner.getvalue())
        hits=[]
        self.assertEqual(scan_archive(outer.getvalue(),"fixture.zip",hits),2)
        self.assertEqual({h["kind"] for h in hits},{"private-file","token"})
    def test_pem_parser_delimiter_is_not_a_key(self):
        hits=[]
        scan(b"-----BEGIN PRIVATE KEY-----", "engine-parser",hits)
        self.assertEqual(hits,[])
        scan(b"-----BEGIN PRIVATE KEY-----\n"+b"A"*80+b"\n-----END PRIVATE KEY-----", "fixture",hits)
        self.assertEqual(hits,[{"kind":"private-key","location":"fixture"}])
if __name__=="__main__": unittest.main()
