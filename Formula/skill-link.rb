class SkillLink < Formula
  desc "Manage Claude Code skill symlinks across multiple source directories"
  homepage "https://github.com/Mizumaki/homebrew-skill-link"
  url "https://github.com/Mizumaki/homebrew-skill-link/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "dae91d66d50fe1abfb04b434988789ab3e1c03ddc95181e26408423aac7ca2ef"
  license "MIT"

  def install
    bin.install "bin/skill-link"
  end

  test do
    assert_match "skill-link 0.1.0", shell_output("#{bin}/skill-link --version")
    assert_match "Usage", shell_output("#{bin}/skill-link 2>&1", 1)
  end
end
