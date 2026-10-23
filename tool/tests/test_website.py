from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
WEBSITE = ROOT / "website"


class WebsiteTest(unittest.TestCase):
    def test_netlify_publishes_static_website_directory(self):
        config = (ROOT / "netlify.toml").read_text(encoding="utf-8")
        self.assertIn('publish = "website"', config)

    def test_home_links_to_privacy_and_has_no_tracking_scripts(self):
        html = (WEBSITE / "index.html").read_text(encoding="utf-8")
        self.assertIn("Print photos at the exact size", html)
        self.assertIn('href="/privacy/"', html)
        self.assertNotRegex(html.lower(), r"google-analytics|googletagmanager|facebook\.net|segment\.com")
        self.assertNotIn("<script", html.lower())

    def test_privacy_policy_covers_required_photo_cut_data_flows(self):
        html = (WEBSITE / "privacy" / "index.html").read_text(encoding="utf-8")
        required = [
            "Privacy Policy",
            "Photo Cut",
            "com.frainzzel.photocut",
            "processed locally",
            "Google Play",
            "Sharing and printing",
            "Android backup",
            "Data retention and deletion",
            "Security",
            "privacy contact",
            "github.com/FranPerezSevilla/photo-cut/issues",
        ]
        for text in required:
            self.assertIn(text, html)

    def test_site_uses_only_local_assets(self):
        html_files = list(WEBSITE.rglob("*.html"))
        external_asset = re.compile(
            r'''(?:src|href)=["']https?://''',
            re.IGNORECASE,
        )
        for path in html_files:
            html = path.read_text(encoding="utf-8")
            for match in external_asset.finditer(html):
                fragment = html[match.start(): match.start() + 160]
                self.assertIn(
                    "github.com/FranPerezSevilla/photo-cut/issues",
                    fragment,
                    msg=f"Unexpected external asset or link in {path}: {fragment}",
                )


if __name__ == "__main__":
    unittest.main()
