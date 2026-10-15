class SkillLink < Formula
  desc "Manage agent skill symlinks (Claude Code, Codex) across source directories"
  homepage "https://github.com/Mizumaki/homebrew-skill-link"
  url "https://github.com/Mizumaki/homebrew-skill-link/archive/refs/tags/v1.3.1.tar.gz"
  sha256 "324000461fb7786ab4bac775cdb55aa929d236e90871f7899a1180a0b82efc4f"
  license "MIT"

  def install
    bin.install "bin/skill-link"
  end

  test do
    assert_match "skill-link #{version}", shell_output("#{bin}/skill-link --version")
    assert_match "Usage", shell_output("#{bin}/skill-link 2>&1", 1)
  end
end
