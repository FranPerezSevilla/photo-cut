from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
WEBSITE = ROOT / "website"


class WebsiteTest(unittest.TestCase):
    def test_netlify_publishes_static_website_directory(self):
        config = (ROOT / "netlify.toml").read_text(encoding="utf-8")
        self.assertIn('publish = "website"', config)

    def test_netlify_relies_on_pretty_urls_for_privacy_route(self):
        config = (ROOT / "netlify.toml").read_text(encoding="utf-8")
        self.assertIn("pretty_urls = true", config)
        self.assertNotIn('from = "/privacy"', config)
        self.assertNotIn('to = "/privacy/"', config)
        self.assertTrue((WEBSITE / "privacy" / "index.html").exists())

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
            "Netlify",
            "marketing cookies",
            "Security",
            "privacy contact",
            "official app-store listing",
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
            self.assertIsNone(
                external_asset.search(html),
                msg=f"Unexpected external URL in {path}",
            )


if __name__ == "__main__":
    unittest.main()
