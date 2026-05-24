class SkillLink < Formula
  desc "Manage Claude Code skill symlinks across multiple source directories"
  homepage "https://github.com/Mizumaki/homebrew-skill-link"
  url "https://github.com/Mizumaki/homebrew-skill-link/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "a1475b4cc64ed12ec94043744c962bd8330ba47967c93666f1e5fe0e6c278164"
  license "MIT"

  def install
    bin.install "bin/skill-link"
  end

  test do
    assert_match "skill-link 0.1.0", shell_output("#{bin}/skill-link --version")
    assert_match "Usage", shell_output("#{bin}/skill-link 2>&1", 1)
  end
end
