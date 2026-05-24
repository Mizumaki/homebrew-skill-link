class SkillLink < Formula
  desc "Manage Claude Code skill symlinks across multiple source directories"
  homepage "https://github.com/Mizumaki/homebrew-skill-link"
  url "https://github.com/Mizumaki/homebrew-skill-link/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "e3b4e57a65402fc8c65250a58255f2e363883cd2c9329713db3b2d93e0dac554"
  license "MIT"

  def install
    bin.install "bin/skill-link"
  end

  test do
    assert_match "skill-link 1.0.0", shell_output("#{bin}/skill-link --version")
    assert_match "Usage", shell_output("#{bin}/skill-link 2>&1", 1)
  end
end
