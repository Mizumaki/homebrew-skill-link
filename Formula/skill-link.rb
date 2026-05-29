class SkillLink < Formula
  desc "Manage Claude Code skill symlinks across multiple source directories"
  homepage "https://github.com/Mizumaki/homebrew-skill-link"
  url "https://github.com/Mizumaki/homebrew-skill-link/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "bf16fb066a713e7921ea43cef3e49aaf626dc0a5e1e942e396fcafee25e6afd1"
  license "MIT"

  def install
    bin.install "bin/skill-link"
  end

  test do
    assert_match "skill-link 1.0.0", shell_output("#{bin}/skill-link --version")
    assert_match "Usage", shell_output("#{bin}/skill-link 2>&1", 1)
  end
end
