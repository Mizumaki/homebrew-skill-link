class SkillLink < Formula
  desc "Manage Claude Code skill symlinks across multiple source directories"
  homepage "https://github.com/Mizumaki/homebrew-skill-link"
  url "https://github.com/Mizumaki/homebrew-skill-link/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "8ccd3319abc073cd8ad5b637d2a9b3809ce322ba8c28298de33b5861e9171fc1"
  license "MIT"

  def install
    bin.install "bin/skill-link"
  end

  test do
    assert_match "skill-link 1.0.0", shell_output("#{bin}/skill-link --version")
    assert_match "Usage", shell_output("#{bin}/skill-link 2>&1", 1)
  end
end
