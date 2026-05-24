class SkillLink < Formula
  desc "Manage Claude Code skill symlinks across multiple source directories"
  homepage "https://github.com/Mizumaki/skill-link"
  url "https://github.com/Mizumaki/skill-link/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "4c6adf37c166aac40d0d6c7394af050881d4b06e6e681d463684dc6b69bdab73"
  license "MIT"

  def install
    bin.install "bin/skill-link"
  end

  test do
    assert_match "skill-link 0.1.0", shell_output("#{bin}/skill-link --version")
    assert_match "Usage", shell_output("#{bin}/skill-link 2>&1", 1)
  end
end
