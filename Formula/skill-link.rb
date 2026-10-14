class SkillLink < Formula
  desc "Manage agent skill symlinks (Claude Code, Codex) across source directories"
  homepage "https://github.com/Mizumaki/homebrew-skill-link"
  url "https://github.com/Mizumaki/homebrew-skill-link/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "1489b8c060e406b9de33d745a2aabedc03d6802fd83251284e28c8cf8493b9ed"
  license "MIT"

  def install
    bin.install "bin/skill-link"
  end

  test do
    assert_match "skill-link #{version}", shell_output("#{bin}/skill-link --version")
    assert_match "Usage", shell_output("#{bin}/skill-link 2>&1", 1)
  end
end
