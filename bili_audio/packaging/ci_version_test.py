import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ci_version


PUBSPEC = "name: bili_audio\n\nversion: 0.1.0+1\n"


class DecideTest(unittest.TestCase):
    def test_first_build_is_one_past_pubspec(self):
        result = ci_version.decide(PUBSPEC, [], "branch", "main")
        self.assertEqual(result["version"], "0.1.0+2")
        self.assertEqual(result["release_tag"], "v0.1.0+2")
        self.assertEqual(result["release_name"], "v0.1.0+2")

    def test_build_passes_published_releases(self):
        lines = ["v0.1.0+4", "Continuous", "v0.2.0", "v0.2.0+9"]
        result = ci_version.decide(PUBSPEC, lines, "branch", "main")
        self.assertEqual(result["version"], "0.1.0+10")
        self.assertEqual(result["release_tag"], "v0.1.0+10")

    def test_version_tag_keeps_its_name_and_raises_the_build(self):
        result = ci_version.decide(PUBSPEC, ["v0.1.0+4"], "tag", "v0.2.0")
        self.assertEqual(result["build_name"], "0.2.0")
        self.assertEqual(result["version"], "0.2.0+5")
        self.assertEqual(result["release_tag"], "v0.2.0")
        self.assertEqual(result["release_name"], "v0.2.0+5")

    def test_auto_tag_is_not_rebuilt(self):
        with self.assertRaises(SystemExit):
            ci_version.decide(PUBSPEC, [], "tag", "v0.1.0+2")

    def test_previous_tag_is_the_highest_older_release(self):
        found = ci_version.previous_tag(
            ["v0.1.0+2", "continuous", "v0.1.0+4", "v0.2.0+1"],
            "v0.1.0+4",
        )
        self.assertEqual(found, "v0.1.0+2")

    def test_changelog_lists_subjects_once(self):
        notes = ci_version.release_notes(
            ["支持队列中搜索", "支持队列中搜索", "  ", "优化歌词匹配"],
            "abc",
            "v0.1.0+3",
            "https://example.test/run/1",
        )
        self.assertTrue(notes.startswith("## 更新日志\n"))
        self.assertIn("- 支持队列中搜索\n- 优化歌词匹配\n", notes)
        self.assertEqual(notes.count("- 支持队列中搜索"), 1)
        self.assertIn("## 安装包\n", notes)
        self.assertLess(
            notes.index("## 更新日志"),
            notes.index("## 安装包"),
        )

    def test_stamp_replaces_only_the_version_line(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "pubspec.yaml"
            path.write_text(PUBSPEC + "description: version: keep\n", encoding="utf-8")
            ci_version.stamp(path, "0.1.0+6")
            text = path.read_text(encoding="utf-8")
        self.assertIn("version: 0.1.0+6\n", text)
        self.assertIn("description: version: keep\n", text)


if __name__ == "__main__":
    unittest.main()
